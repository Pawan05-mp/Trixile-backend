import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'app/constants/app_constants.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'app/providers.dart';
import 'core/api/api_client.dart';
import 'core/storage/local_storage.dart';
import 'core/storage/secure_storage.dart';

/// Global key so the app-level Supabase auth listener (which has no
/// BuildContext of its own) can still surface errors via a SnackBar.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ypicbilajipxjgkqxuht.supabase.co',
    anonKey: 'sb_publishable_CUj1PhLXnuGiGg-f_nrpKg_RENDSuRQ',
  );

  final localStorage = LocalStorage();
  await localStorage.init();

  // Restore any existing session before the router/UI is built, so a
  // returning signed-in user skips straight past the sign-in screen.
  final secureStorage = SecureStorage();
  final apiClient = ApiClient();
  final existingToken = await secureStorage.getAuthToken();
  final isAlreadySignedIn = existingToken != null && existingToken.isNotEmpty;
  if (isAlreadySignedIn) {
    apiClient.setAuthToken(existingToken);
  }
  AppRouter.startSignedIn = isAlreadySignedIn;

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
        secureStorageProvider.overrideWithValue(secureStorage),
        apiClientProvider.overrideWithValue(apiClient),
        isAuthenticatedProvider.overrideWith((ref) => isAlreadySignedIn),
      ],
      child: const PlaceDiscoveryApp(),
    ),
  );
}

class PlaceDiscoveryApp extends ConsumerStatefulWidget {
  const PlaceDiscoveryApp({super.key});

  @override
  ConsumerState<PlaceDiscoveryApp> createState() => _PlaceDiscoveryAppState();
}

class _PlaceDiscoveryAppState extends ConsumerState<PlaceDiscoveryApp> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();

    // Fires once Google/Facebook sign-in completes and the OAuth
    // redirect lands back in the app (see AndroidManifest.xml /
    // Info.plist deep-link config + the "CONNECT WITH GOOGLE/FACEBOOK"
    // buttons in sign_in_screen.dart and create_account_screen.dart).
    // From here on, the flow mirrors email/password login: exchange the
    // Supabase session for our own backend JWT, persist it, and route
    // to onboarding (new users) or home (returning users).
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
        if (data.event != AuthChangeEvent.signedIn || data.session == null) {
          return;
        }
        await _exchangeSupabaseSession(data.session!);
      },
    );
  }

  Future<void> _exchangeSupabaseSession(Session session) async {
    String? backendToken;
    bool isNewUser = false;

    try {
      // Try to exchange with our own backend first — this gives the user
      // a backend JWT so all protected API routes (/favorites, etc.) work.
      final result = await ref
          .read(authServiceProvider)
          .loginWithSupabaseToken(session.accessToken);
      backendToken = result.token;
      isNewUser = result.isNewUser;
    } catch (e) {
      // Backend exchange failed (e.g. SUPABASE_URL/ANON_KEY not set yet,
      // or backend is down). Fall back to using the Supabase access token
      // directly so the user isn't stuck on the sign-in screen.
      debugPrint('Backend social exchange failed, using Supabase token: $e');
      backendToken = session.accessToken;
      // Treat as new user so they go through onboarding — safer default.
      isNewUser = true;
    }

    ref.read(apiClientProvider).setAuthToken(backendToken);
    await ref.read(secureStorageProvider).saveAuthToken(backendToken);

    final email = session.user.email;
    if (email != null) {
      await ref.read(localStorageProvider).saveUserEmail(email);
    }
    final name = (session.user.userMetadata?['full_name']
            ?? session.user.userMetadata?['name']) as String?;
    if (name != null) {
      await ref.read(localStorageProvider).saveUserName(name);
    }

    ref.read(isAuthenticatedProvider.notifier).state = true;
    AppRouter.startSignedIn = true;

    if (!mounted) return;
    AppRouter.config.go(isNewUser ? AppRouter.getStarted : AppRouter.home);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: AppRouter.config,
    );
  }
}