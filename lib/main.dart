import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:provider/provider.dart';

import 'theme/pollit_theme.dart';
import 'pages/onboarding/onboarding_screen.dart';
import 'pages/onboarding/profile_setup_screen.dart';
import 'pages/app_shell.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/feed_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Debug: log what Firebase knows right after init
  final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
  debugPrint('=== POLLIT AUTH DEBUG ===');
  debugPrint('currentUser after Firebase.initializeApp: ${currentUser?.uid ?? "NULL"}');
  debugPrint('========================');

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF161616),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  
  runApp(
    MultiProvider(
      providers: [
        // lazy: false forces AuthProvider to be created immediately,
        // so its auth stream listener is active before any widget reads it.
        ChangeNotifierProvider(create: (_) => AuthProvider(), lazy: false),
        ChangeNotifierProxyProvider<AuthProvider, FeedProvider>(
          create: (_) => FeedProvider(),
          update: (_, auth, feed) => feed!..updateAuth(auth),
        ),
      ],
      child: const PollitApp(),
    ),
  );
}

class _PollitScrollBehavior extends ScrollBehavior {
  const _PollitScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      decelerationRate: ScrollDecelerationRate.fast,
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class PollitApp extends StatelessWidget {
  const PollitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pollit',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _PollitScrollBehavior(),
      theme: PollitTheme.dark,
      darkTheme: PollitTheme.dark,
      themeMode: ThemeMode.dark,
      home: const AuthWrapper(),
    );
  }
}

/// AuthWrapper decides what screen to show based purely on AuthProvider state.
/// No StreamBuilder, no second subscription. Just Consumer<AuthProvider>.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        debugPrint('AuthWrapper rebuild → isLoading=${auth.isLoading}, '
            'user=${auth.user?.uid ?? "null"}, '
            'isProfileLoading=${auth.isProfileLoading}, '
            'profile=${auth.userProfile != null}');

        // 1. Still waiting for Firebase to emit the first auth event
        if (auth.isLoading) {
          return const Scaffold(
            backgroundColor: PollitColors.background,
            body: Center(
              child: CircularProgressIndicator(color: PollitColors.accent),
            ),
          );
        }

        // 2. No user → show onboarding / login
        if (auth.user == null) {
          return const OnboardingScreen();
        }

        // 3. User exists but Firestore profile is still loading
        if (auth.isProfileLoading) {
          return const Scaffold(
            backgroundColor: PollitColors.background,
            body: Center(
              child: CircularProgressIndicator(color: PollitColors.accent),
            ),
          );
        }

        // 4. Profile not yet set up
        if (auth.userProfile == null ||
            auth.userProfile!['profileSetupCompleted'] != true) {
          return const ProfileSetupScreen();
        }

        // 5. Fully authenticated + profile complete → go to app
        return const AppShell();
      },
    );
  }
}
