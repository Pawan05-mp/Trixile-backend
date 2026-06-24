# Google & Facebook Sign-In — Setup Guide

Social login is fully wired in the code now (both Sign In and Create
Account screens, both providers). What's left is **external setup**:
creating developer apps with Google and Facebook, and plugging their
credentials into Supabase. None of this requires Firebase.

## How it works (so the steps below make sense)

1. User taps "Connect with Google/Facebook" in the app.
2. `supabase_flutter` opens a browser tab and walks them through Google's
   or Facebook's actual OAuth consent screen.
3. The provider redirects back to **Supabase's** callback URL
   (`https://<project-ref>.supabase.co/auth/v1/callback`), which is fixed
   and the same for every provider — Supabase handles the OAuth handshake
   for you, you never see provider tokens in the app.
4. Supabase then redirects into the app itself via the custom URL scheme
   `io.trixile.app://login-callback` (already configured in
   `AndroidManifest.xml` and `Info.plist`).
5. The app catches that redirect, grabs the Supabase session, and sends
   it to your own backend's new `POST /auth/social` endpoint, which
   verifies it against Supabase and mints your normal backend JWT. From
   here on it behaves exactly like email/password login.

So you need three things configured: **Google Cloud**, **Facebook
Developers**, and **Supabase** (to glue them together), plus the
backend's two new env vars.

---

## 1. Supabase Dashboard

Go to your project at `https://supabase.com/dashboard/project/<project-ref>`
(the project already in use is `ypicbilajipxjgkqxuht` — see
`mobile/lib/main.dart`).

1. **Authentication → URL Configuration → Redirect URLs** — add:
   ```
   io.trixile.app://login-callback
   ```
   This must match `AppConstants.supabaseRedirectUrl` in
   `mobile/lib/app/constants/app_constants.dart` exactly, or Supabase will
   refuse to redirect back into the app.

2. **Authentication → Providers → Google** — toggle it on. You'll paste in
   the Client ID and Client Secret from step 2 below. Note the **Callback
   URL (for OAuth)** shown on this page — you'll need it for step 2.

3. **Authentication → Providers → Facebook** — same idea, toggle on,
   you'll paste in App ID and App Secret from step 3 below.

4. **Project Settings → API** — copy the **Project URL** and the
   **anon / public key**. These go into the backend's `.env` (step 4).

---

## 2. Google Cloud Console (for Google Sign-In)

1. Go to https://console.cloud.google.com/ and create a project (or pick
   an existing one).
2. **APIs & Services → OAuth consent screen** — configure it (External
   user type is fine for testing), add your app name, support email, and
   the scopes `email` and `profile`.
3. **APIs & Services → Credentials → Create Credentials → OAuth client ID**
   - Application type: **Web application** (yes, even though this is a
     mobile app — the redirect target is Supabase's web callback URL).
   - Authorized redirect URI: paste the Supabase callback URL from step
     1.2 above (looks like
     `https://ypicbilajipxjgkqxuht.supabase.co/auth/v1/callback`).
4. Copy the generated **Client ID** and **Client Secret** into Supabase's
   Google provider settings (step 1.2) and save.

---

## 3. Facebook Developers (for Facebook Login)

1. Go to https://developers.facebook.com/apps and create a new app
   (type: **Consumer**, or **Business** if you have a company).
2. Add the **Facebook Login** product to the app.
3. **Facebook Login → Settings → Valid OAuth Redirect URIs** — paste the
   same Supabase callback URL from step 1.2.
4. **App Settings → Basic** — copy the **App ID** and **App Secret** into
   Supabase's Facebook provider settings (step 1.3) and save.
5. While testing, add yourself as a **Test User** or **Developer** under
   **Roles**, or switch the app to Live mode — Facebook blocks login for
   everyone else while the app is in development mode.

---

## 4. Backend `.env`

Add these two values (from Supabase step 1.4) to your backend
environment — either `backend/.env` for local runs, or wherever you set
env vars for your Cloud Run / Docker deployment:

```
SUPABASE_URL="https://ypicbilajipxjgkqxuht.supabase.co"
SUPABASE_ANON_KEY="<the anon/public key from Supabase Project Settings -> API>"
```

`infra/docker/docker-compose.yml` already passes these through to the
`api` container if they're set in your shell/`.env` when you run
`docker compose up`.

Without these two values, `/auth/social` will return a 401 for every
request (`AuthService.authenticate_social` short-circuits if either is
empty) — so this step is required, not optional.

---

## 5. Rebuild and test

```
cd mobile
flutter pub get
flutter run
```

Tap "Connect with Google" or "Connect with Facebook" on either the Sign
In or Create Account screen. A browser tab should open, walk you through
the provider's login, then bounce you straight back into the app at the
home screen (new accounts land on the "get started" onboarding instead).

### If the redirect doesn't come back to the app
- Double check the redirect URL matches **exactly** (scheme + host) in
  all three places: `AppConstants.supabaseRedirectUrl`, the Android
  intent-filter, the iOS `CFBundleURLSchemes` entry, and Supabase's
  Redirect URLs allow-list.
- On Android, custom URL scheme handling requires a real device/emulator
  with a browser installed — it won't trigger from `flutter run -d chrome`.
- `io.trixile.app` is a placeholder scheme — if you rename the Android
  `applicationId` / iOS bundle identifier before shipping (both are still
  `com.example.place_discovery_mobile` / `com.example.placeDiscoveryMobile`
  defaults), you don't have to change the URL scheme to match, but it's
  good practice to pick something unique to your app to avoid clashing
  with another app on the user's device that registered the same scheme.

### If you get "Could not verify social login session" in the app
That's the backend's 401 from `/auth/social` — almost always means
`SUPABASE_URL` / `SUPABASE_ANON_KEY` aren't set on the backend, or don't
match the project the mobile app initializes in `main.dart`.
