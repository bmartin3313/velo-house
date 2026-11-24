# Your copy of Velo House Pitching

This is a full copy of the site's code. It is **not connected to any database yet**. Until you connect one, it runs in demo mode: everything saves only in the browser you're using, and nobody signs in.

## Files
- `index Velo.html`: the whole app. Edit this file to change the site.
- `index.html`: sends visitors to the app page.
- `manifest.webmanifest` and the `.png` icons: the home-screen app name and icons.
- `supabase-setup.sql`: creates your database tables.

## 1. Put the site online (GitHub Pages, free)
1. Make a free GitHub account, then create a new **public** repository (for example `velo-house`).
2. Click **Add file → Upload files** and upload every file in this folder.
3. Go to **Settings → Pages**. Under "Branch", pick `main` and `/ (root)`, then click Save.
4. After a minute your site is live at `https://YOUR-USERNAME.github.io/velo-house/`.

## 2. Create your own database (Supabase, free)
1. Sign up at supabase.com and create a new project.
2. Open **SQL Editor → New query**. Paste all of `supabase-setup.sql` and click **Run**.
3. Open **Authentication → URL Configuration**. Set **Site URL** to your GitHub Pages address from step 1.4, and add the same address under **Redirect URLs**. Sign-up confirmation emails and password-reset links need this.
4. Open **Project Settings → API Keys**. Copy the **Project URL** and the **Publishable key**.

## 3. Connect the two
1. Open `index Velo.html` (on GitHub: click the file, then the pencil icon).
2. Near the top (lines 6 and 7), paste your values between the quotes:
   ```
   window.WLN_SUPABASE_URL = 'https://xxxx.supabase.co';
   window.WLN_SUPABASE_KEY = 'sb_publishable_...';
   ```
3. Save (Commit changes). After a minute, reload the site. It should now show a sign-in screen.

## 4. Make yourself the coach
1. Create your account on your site.
2. In Supabase **SQL Editor**, run this once with your email:
   `update public.profiles set role = 'coach' where email = 'you@example.com';`
3. Reload the site. You'll see the coach view, and your pitchers can sign up from the same link.

Note: the database setup was written to match how the app's code uses its data. If something shows a "check the setup in Supabase" message, send me the message and I'll adjust it.
