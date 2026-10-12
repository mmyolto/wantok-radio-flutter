import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brand colours taken from the original Android app.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF003924); // dark green
  static const Color primaryLight = Color(0xFF006C48);
  static const Color primaryContainer = Color(0xFF91F7D0);
  static const Color onPrimaryContainer = Color(0xFF002113);
  static const Color secondary = Color(0xFF926B00); // gold-brown
  static const Color secondaryContainer = Color(0xFFFFDF9E);
  static const Color onSecondaryContainer = Color(0xFF2F1F00);
  static const Color tertiary = Color(0xFF3B6470);
  static const Color background = Color(0xFFFCFCF9);
  static const Color onBackground = Color(0xFF191C1B);
  static const Color surfaceVariant = Color(0xFFDBE5E0);
  static const Color onSurfaceVariant = Color(0xFF3F4945);
  static const Color outline = Color(0xFF6F7975);
  static const Color error = Color(0xFFBA1A1A);

  static const Color red = Color(0xFFBA1A1A);
  static const Color gold = Color(0xFFFFC107);

  static const Color facebook = Color(0xFF1877F2);
  static const Color whatsApp = Color(0xFF25D366);
  static const Color email = Color(0xFFEA4335);
  static const Color sms = Color(0xFFFF9800);
  static const Color website = Color(0xFF2E7D32);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[primaryLight, primary],
  );
}

class AppTheme {
  AppTheme._();

  static const String bodyFont = 'Montserrat';
  static const String displayFont = 'PlayfairDisplay';

  static ThemeData light() {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.background,
      onSurface: AppColors.onBackground,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      inversePrimary: Color(0xFF74DAB5),
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: bodyFont,
      scaffoldBackgroundColor: AppColors.background,
      visualDensity: VisualDensity.standard,
    );

    final TextTheme text = base.textTheme
        .copyWith(
          headlineLarge: const TextStyle(
            fontFamily: displayFont,
            fontSize: 32,
            height: 40 / 32,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: const TextStyle(
            fontFamily: displayFont,
            fontSize: 24,
            height: 32 / 24,
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: const TextStyle(
            fontFamily: displayFont,
            fontSize: 22,
            height: 30 / 22,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: const TextStyle(
            fontFamily: displayFont,
            fontSize: 20,
            height: 28 / 20,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: const TextStyle(
            fontFamily: bodyFont,
            fontSize: 16,
            height: 24 / 16,
            letterSpacing: 0.5,
          ),
          bodyMedium: const TextStyle(
            fontFamily: bodyFont,
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: 0.25,
          ),
          labelSmall: const TextStyle(
            fontFamily: bodyFont,
            fontSize: 11,
            height: 16 / 11,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w500,
          ),
        )
        .apply(bodyColor: AppColors.onBackground, displayColor: AppColors.onBackground);

    return base.copyWith(
      textTheme: text,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontFamily: bodyFont,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontFamily: bodyFont, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primaryContainer,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        selectedLabelTextStyle: TextStyle(
          fontFamily: bodyFont,
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: bodyFont,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
