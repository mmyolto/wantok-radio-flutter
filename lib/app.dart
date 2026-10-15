import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/app_config.dart';
import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

final GlobalKey<ScaffoldMessengerState> rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

class WantokRadioApp extends StatelessWidget {
  const WantokRadioApp({super.key});

  static final ThemeData _theme = AppTheme.light();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      // ONE fixed brand theme: the phone's light / dark mode never changes it.
      theme: _theme,
      darkTheme: _theme,
      highContrastTheme: _theme,
      highContrastDarkTheme: _theme,
      themeMode: ThemeMode.light,
      scaffoldMessengerKey: rootMessengerKey,
      // Respect the user's font size, but keep layouts readable at extremes.
      builder: (BuildContext context, Widget? child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.overlay,
        child: MediaQuery(
          // Always render as "light" so no widget reacts to the phone's dark mode.
          data: MediaQuery.of(context).copyWith(platformBrightness: Brightness.light),
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: 0.85,
            maxScaleFactor: 1.6,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      home: const _Root(),
    );
  }
}

/// Shows the animated splash once, then the main app.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _splashDone
          ? const HomeShell(key: ValueKey<String>('home'))
          : SplashScreen(
              key: const ValueKey<String>('splash'),
              onFinished: () => setState(() => _splashDone = true),
            ),
    );
  }
}
