# What's in this zip

This is the full Trixile stack (`backend/`, `dataset/`, `infra/`, `docs/`, etc.
from `place-discovery-fixed`) with the `mobile/` folder replaced by the
**trix-mobile-obsidian-ui** Flutter app — plus two bug fixes so sign-in and
account creation actually work.

## Fixes applied

1. **`mobile/lib/app/constants/app_constants.dart`**
   `baseUrl` had a trailing `/api`, but `backend/app/main.py` mounts every
   router at the root (`/auth`, `/places`, `/favorites` — no `/api` prefix).
   Every login/register request was hitting a path that doesn't exist on the
   server (404). Removed the `/api` suffix so the app calls the real routes.

   > If your deployed Cloud Run service actually sits behind a reverse proxy
   > that adds back an `/api` prefix, you'll want to restore it instead —
   > check `https://<your-service-url>/docs` to see the live route paths.

2. **`mobile/android/app/src/main/AndroidManifest.xml`**
   Added the missing `<uses-permission android:name="android.permission.INTERNET"/>`.
   Flutter's debug/profile manifests include this by default (so `flutter run`
   in debug mode worked fine), but the release manifest didn't have it — that
   would have silently broken all network calls in a release APK.

## Not changed, but worth knowing about

- `mobile/lib/core/api/supabase_image_service.dart` has a placeholder
  `YOUR_PROJECT.supabase.co` URL. It isn't called anywhere in the app right
  now (dead code), so it's harmless as-is, but fill it in (or delete it) if
  you start using it.
- `docs/PROJECT_STRUCTURE.md` describes an older Vite+React mobile front-end;
  it's stale — the actual `mobile/` app is this Flutter project.

## Google & Facebook sign-in (added)

The "Connect with Google/Facebook" buttons on the Sign In and Create
Account screens were UI-only stubs (`onTap: () {}`). They're now wired up
end-to-end using the Supabase project already initialized in the app:

- **`mobile/lib/main.dart`** — app-level listener on
  `Supabase.instance.client.auth.onAuthStateChange` that fires once a
  user finishes a Google/Facebook login and the OAuth redirect lands back
  in the app. It exchanges the Supabase session for a backend JWT and
  routes to onboarding (new users) or home (returning users).
- **`mobile/lib/features/auth/screens/sign_in_screen.dart`** and
  **`create_account_screen.dart`** — buttons now call
  `Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google / .facebook, ...)`.
- **`mobile/lib/core/api/auth_service.dart`** — new
  `loginWithSupabaseToken()` method calling a new backend endpoint.
- **`backend/app/api/routes/auth.py`** — new `POST /auth/social` route.
- **`backend/app/services/auth_service.py`** — new
  `authenticate_social()`: verifies the Supabase token against Supabase's
  `/auth/v1/user` endpoint, finds-or-creates the matching local `User` row
  by email, and issues the same kind of backend JWT password login does
  — so every existing protected route (`/favorites`, etc.) keeps working
  unchanged regardless of how the user signed in.
- **`backend/app/core/config.py`** — new `SUPABASE_URL` /
  `SUPABASE_ANON_KEY` settings, required for the above verification call.
- **Android/iOS deep link config** — `AndroidManifest.xml` intent-filter
  and `Info.plist` `CFBundleURLTypes` entry for the
  `io.trixile.app://login-callback` redirect scheme.

**You still need to do the external setup** (Google Cloud OAuth client,
Facebook Developer app, enabling both providers in Supabase, and setting
the backend's two new env vars) — see **`SOCIAL_LOGIN_SETUP.md`** for the
full step-by-step walkthrough. Until that's done, tapping the buttons will
open a browser but the provider/Supabase will reject the login.
