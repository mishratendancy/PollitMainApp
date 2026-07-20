import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PollitColors {
  PollitColors._();

  static const Color background = Color(0xFF09090B); // Web background
  static const Color surface = Color(0xFF18181B); // Web card
  static const Color surfaceLight = Color(0xFF27272A); // Muted
  static const Color accent = Color(0xFF2DD4BF); // Web primary
  static const Color accentLight = Color(0xFF5EEAD4);
  static const Color accentDark = Color(0xFF14B8A6);
  static const Color textPrimary = Color(0xFFFAFAFA); // Web foreground
  static const Color textSecondary = Color(0xFFA1A1AA); // Muted foreground
  static const Color textMuted = Color(0xFF71717A);
  static const Color divider = Color(0xFF27272A); // Border
  static const Color error = Color(0xFFF87171); // Destructive
  static const Color cardBorder = Color(0xFF27272A); // Border
}

class PollitTheme {
  PollitTheme._();

  static TextTheme get _textTheme {
    return GoogleFonts.interTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          color: PollitColors.textPrimary,
          height: 1.1,
        ),
        displayMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
          color: PollitColors.textPrimary,
          height: 1.15,
        ),
        displaySmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: PollitColors.textPrimary,
          height: 1.2,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: PollitColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: PollitColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: PollitColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: PollitColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: PollitColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: PollitColors.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: PollitColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: PollitColors.textSecondary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: PollitColors.textMuted,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: PollitColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: PollitColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: PollitColors.textMuted,
        ),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      platform: TargetPlatform.iOS,
      scaffoldBackgroundColor: PollitColors.background,
      textTheme: _textTheme,
      colorScheme: const ColorScheme.dark(
        primary: PollitColors.accent,
        onPrimary: Colors.white,
        secondary: PollitColors.accentLight,
        onSecondary: Colors.white,
        surface: PollitColors.surface,
        onSurface: PollitColors.textPrimary,
        onSurfaceVariant: PollitColors.textSecondary,
        outline: PollitColors.cardBorder,
        outlineVariant: PollitColors.divider,
        error: PollitColors.error,
        primaryContainer: PollitColors.accentDark,
        secondaryContainer: PollitColors.surfaceLight,
        surfaceContainerHighest: PollitColors.surfaceLight,
      ),
      cardTheme: CardThemeData(
        color: PollitColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PollitColors.cardBorder, width: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: PollitColors.background,
        foregroundColor: PollitColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: _textTheme.headlineSmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PollitColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PollitColors.textPrimary,
          side: const BorderSide(color: PollitColors.cardBorder),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PollitColors.accent,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: PollitColors.surfaceLight,
        selectedColor: PollitColors.accent.withValues(alpha: 0.2),
        side: const BorderSide(color: PollitColors.cardBorder, width: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle: const TextStyle(
          color: PollitColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PollitColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: PollitColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: PollitColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: PollitColors.accent, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: PollitColors.textMuted,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: PollitColors.divider,
        thickness: 0.5,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: PollitColors.accent,
        linearTrackColor: PollitColors.surfaceLight,
      ),
    );
  }
}
