import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/get_started_screen.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/auth/screens/create_account_screen.dart';
import '../../features/auth/screens/occasion_selection_screen.dart';
import '../../features/home/screens/home_dashboard_screen.dart';
import '../../features/explore/screens/explore_discovery_screen.dart';
import '../../features/search/screens/filters_screen.dart';
import '../../features/place_details/screens/place_peek_screen.dart';
import '../../features/favorites/screens/saved_places_map_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_settings_screen.dart';
import '../../features/edit_profile/screens/edit_profile_screen.dart';
import '../../shared/models/place.dart';

class AppRouter {
  AppRouter._();

  /// Set once in main() before the app builds, based on whether a
  /// session token was found in secure storage. When true, hitting the
  /// sign-in route immediately redirects to home instead.
  static bool startSignedIn = false;

  static const String signIn = '/';
  static const String createAccount = '/create-account';
  static const String getStarted = '/get-started';
  static const String occasionSelection = '/onboarding';
  static const String home = '/home';
  static const String explore = '/explore';
  static const String filters = '/filters';
  static const String placePeek = '/place-peek';
  static const String savedPlaces = '/saved-places';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';

  static void goToPlace(BuildContext context, Place place) {
    context.push(placePeek, extra: place);
  }

  /// Bottom nav tab order: Home, Explore, Saved, Profile.
  static void goToTab(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(home);
        break;
      case 1:
        context.go(explore);
        break;
      case 2:
        context.go(savedPlaces);
        break;
      case 3:
        context.go(profile);
        break;
    }
  }

  static final config = GoRouter(
    initialLocation: signIn,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      if (startSignedIn && state.matchedLocation == signIn) {
        return home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: signIn,
        builder: (context, state) => const SignInScreen(),
      ),

      GoRoute(
        path: createAccount,
        builder: (context, state) => const CreateAccountScreen(),
      ),

      GoRoute(
        path: getStarted,
        builder: (context, state) => const GetStartedScreen(),
      ),

      GoRoute(
        path: occasionSelection,
        builder: (context, state) => const OccasionSelectionScreen(),
      ),

      GoRoute(
        path: home,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const HomeDashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      GoRoute(
        path: explore,
        builder: (context, state) => const ExploreDiscoveryScreen(),
      ),

      GoRoute(
        path: filters,
        builder: (context, state) => const FiltersScreen(),
      ),

      GoRoute(
        path: placePeek,
        builder: (context, state) => PlacePeekScreen(
          place: state.extra as Place,
        ),
      ),

      GoRoute(
        path: savedPlaces,
        builder: (context, state) => const SavedPlacesMapScreen(),
      ),

      GoRoute(
        path: notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),

      GoRoute(
        path: profile,
        builder: (context, state) => const ProfileSettingsScreen(),
      ),

      GoRoute(
        path: editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
  );
}
