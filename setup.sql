-- Lumen backend: run this once in Supabase > SQL Editor > New query > Run

create table if not exists public.docs (
  col text not null,
  id text not null,
  data jsonb not null default '{}'::jsonb,
  owner uuid not null default auth.uid(),
  updated_at timestamptz not null default now(),
  primary key (col, id)
);
alter table public.docs enable row level security;

-- usernames owned by the signed-in user
create or replace function public.lumen_names() returns text[]
language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(id), '{}') from docs where col = 'accounts' and owner = auth.uid()
$$;

-- a user may only write rows that name one of their own usernames
create or replace function public.lumen_ok(c text, d jsonb) returns boolean
language sql stable security definer set search_path = public as $$
  select (case c
    when 'posts' then d->>'user'
    when 'likes' then d->>'user'
    when 'comments' then d->>'user'
    when 'follows' then d->>'a'
    when 'outbox' then d->>'from'
    when 'reads' then d->>'me'
    else null end) = any(public.lumen_names())
$$;

drop policy if exists docs_read on public.docs;
drop policy if exists docs_insert on public.docs;
drop policy if exists docs_update on public.docs;
drop policy if exists docs_delete on public.docs;

-- everyone can read profiles, posts, likes, comments, follows.
-- messages: only the sender and the recipient. read receipts: only the owner.
create policy docs_read on public.docs for select to anon, authenticated using (
  col in ('accounts','posts','likes','comments','follows')
  or (col = 'outbox' and (owner = auth.uid() or data->>'to' = any(public.lumen_names())))
  or (col = 'reads' and owner = auth.uid())
);

create policy docs_insert on public.docs for insert to authenticated with check (
  owner = auth.uid() and (
    (col = 'accounts' and id = data->>'user' and id = split_part(auth.jwt()->>'email', '@', 1))
    or public.lumen_ok(col, data)
  )
);

create policy docs_update on public.docs for update to authenticated using (owner = auth.uid()) with check (
  owner = auth.uid() and (
    (col = 'accounts' and id = data->>'user' and id = split_part(auth.jwt()->>'email', '@', 1))
    or public.lumen_ok(col, data)
  )
);

create policy docs_delete on public.docs for delete to authenticated using (owner = auth.uid());

-- live updates
alter publication supabase_realtime add table public.docs;

-- photo and video storage (public bucket, 40 MB limit per file)
insert into storage.buckets (id, name, public, file_size_limit)
values ('media', 'media', true, 41943040)
on conflict (id) do nothing;

drop policy if exists media_read on storage.objects;
drop policy if exists media_write on storage.objects;
create policy media_read on storage.objects for select using (bucket_id = 'media');
create policy media_write on storage.objects for insert to authenticated
  with check (bucket_id = 'media' and (storage.foldername(name))[1] = auth.uid()::text);
