import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'theme/pollit_theme.dart';
import 'pages/onboarding/onboarding_screen.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/feed_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
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
      home: const OnboardingScreen(),
    );
  }
}
