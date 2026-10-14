# Lumen: setup for GitHub Pages

Lumen needs a small online database so every person on every device sees the same accounts.
This version uses Supabase (free plan). Setup takes about 10 minutes.

1. Create a project at https://supabase.com (free).
2. In **Authentication > Providers > Email**, turn **OFF "Confirm email"**. Lumen signs people in with a username, not a real email.
3. In **SQL Editor**, paste all of `setup.sql` and click **Run**.
4. In **Project Settings > API**, copy the **Project URL** and the **anon public** key.
5. Open `index.html` and paste them at the top, in `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
6. Upload `index.html` to your GitHub repo and turn on GitHub Pages (Settings > Pages).

The anon key is meant to be public. The security rules in `setup.sql` protect the data.

Limits to know about:
- The free plan pauses a project after a week with no activity. Restore it from the Supabase dashboard.
- Lumen loads all accounts and posts on each device, which suits hundreds to a few thousand users.
- Suggestions show the 30 newest accounts. Explore search finds anyone by name.
