import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brand colours taken from the Wantok Radio Light logo:
/// emerald green, sunshine yellow, cross red and white.
///
/// The app ALWAYS uses this one theme. It never follows the phone's
/// light / dark setting (see app.dart and the Android / iOS settings).
class AppColors {
  AppColors._();

  // Greens (logo background, deepened for an elegant, premium look)
  static const Color night = Color(0xFF021C13); // deepest background
  static const Color primary = Color(0xFF064A31); // deep emerald
  static const Color primaryLight = Color(0xFF0E8A4F); // logo green
  static const Color primaryContainer = Color(0xFFD9F3E4);
  static const Color onPrimaryContainer = Color(0xFF00210F);

  // Gold (logo yellow)
  static const Color gold = Color(0xFFFFD60A);
  static const Color goldDeep = Color(0xFFE9A800);
  static const Color secondary = Color(0xFF8A6500); // gold text on light backgrounds
  static const Color secondaryContainer = Color(0xFFFFF4C7);
  static const Color onSecondaryContainer = Color(0xFF2B2000);

  // Red (logo cross)
  static const Color red = Color(0xFFE3262B);

  static const Color tertiary = Color(0xFF2F6A63);
  static const Color background = Color(0xFFF6F5EE); // warm ivory
  static const Color onBackground = Color(0xFF14201B);
  static const Color surfaceVariant = Color(0xFFE5EEE8);
  static const Color onSurfaceVariant = Color(0xFF46544D);
  static const Color outline = Color(0xFF85928B);
  static const Color error = Color(0xFFBA1A1A);

  static const Color facebook = Color(0xFF1877F2);
  static const Color whatsApp = Color(0xFF25D366);
  static const Color email = Color(0xFFEA4335);
  static const Color sms = Color(0xFFFF9800);
  static const Color website = Color(0xFF0E8A4F);

  /// App bar, drawer header and banners.
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF0B6B43), primary, night],
    stops: <double>[0, 0.55, 1],
  );

  /// Full-screen "on air" background behind the live player.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFF07513A), Color(0xFF043524), night],
    stops: <double>[0, 0.5, 1],
  );

  /// Gold buttons and accents.
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFFE45C), gold, goldDeep],
  );

  /// Thin gold line under the app bar.
  static const LinearGradient goldLine = LinearGradient(
    colors: <Color>[Color(0x00FFD60A), gold, Color(0x00FFD60A)],
  );
}

class AppTheme {
  AppTheme._();

  static const String bodyFont = 'Montserrat';
  static const String displayFont = 'PlayfairDisplay';

  /// Status-bar / navigation-bar icons: always light icons on our dark green
  /// bars, whatever the phone's theme is.
  static const SystemUiOverlayStyle overlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // Android
    statusBarBrightness: Brightness.dark, // iOS
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

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
      outlineVariant: Color(0xFFD5DED8),
      inversePrimary: Color(0xFF7FE0AE),
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
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
            fontSize: 26,
            height: 34 / 26,
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
            letterSpacing: 0.3,
          ),
          bodyMedium: const TextStyle(
            fontFamily: bodyFont,
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: 0.2,
          ),
          labelLarge: const TextStyle(
            fontFamily: bodyFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          labelSmall: const TextStyle(
            fontFamily: bodyFont,
            fontSize: 11,
            height: 16 / 11,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
          ),
        )
        .apply(bodyColor: AppColors.onBackground, displayColor: AppColors.onBackground);

    final RoundedRectangleBorder rounded22 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.07)),
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: overlay,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: AppColors.primary.withValues(alpha: 0.18),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: rounded22,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 54),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: bodyFont,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, 50),
          side: const BorderSide(color: AppColors.primary, width: 1.4),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontFamily: bodyFont, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontFamily: bodyFont, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.gold,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(
          fontFamily: bodyFont,
          fontWeight: FontWeight.w600,
          color: AppColors.onBackground,
        ),
        checkmarkColor: AppColors.night,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.night,
        actionTextColor: AppColors.gold,
        contentTextStyle: const TextStyle(fontFamily: bodyFont, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primaryLight),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => s.contains(WidgetState.selected) ? AppColors.night : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => s.contains(WidgetState.selected) ? AppColors.gold : null,
        ),
      ),
      dividerTheme: DividerThemeData(color: AppColors.primary.withValues(alpha: 0.1)),
      drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.gold.withValues(alpha: 0.35),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => TextStyle(
            fontFamily: bodyFont,
            fontSize: 14.5,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.gold.withValues(alpha: 0.35),
        selectedIconTheme: const IconThemeData(color: AppColors.primary),
        selectedLabelTextStyle: const TextStyle(
          fontFamily: bodyFont,
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: const TextStyle(
          fontFamily: bodyFont,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
