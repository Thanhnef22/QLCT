import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF17252A);
  static const mutedInk = Color(0xFF6D7A7F);
  static const canvas = Color(0xFFF7FAF9);
  static const surface = Color(0xFFFFFFFF);
  static const mint = Color(0xFF18B892);
  static const mintDark = Color(0xFF087F66);
  static const mintSoft = Color(0xFFE2F8F1);
  static const coral = Color(0xFFFF796B);
  static const coralSoft = Color(0xFFFFEFED);
  static const amber = Color(0xFFF5B84B);
  static const line = Color(0xFFE6EEEB);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.mint,
      brightness: Brightness.light,
      surface: AppColors.canvas,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: AppColors.mint,
        onPrimary: Colors.white,
        secondary: AppColors.mintDark,
        surface: AppColors.canvas,
      ),
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: 'Inter',
      textTheme: _textTheme(AppColors.ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.mint, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.mutedInk),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.mintSoft,
        labelTextStyle: WidgetStatePropertyAll(
          _textTheme(AppColors.ink)
              .labelSmall!
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.mint,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(primary: const Color(0xFF52D6B0)),
      scaffoldBackgroundColor: const Color(0xFF101A1A),
      fontFamily: 'Inter',
      textTheme: _textTheme(const Color(0xFFF2F7F5)),
      cardTheme: CardThemeData(
        color: const Color(0xFF182625),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF101A1A),
        foregroundColor: Color(0xFFF2F7F5),
        elevation: 0,
      ),
    );
  }

  static TextTheme _textTheme(Color color) {
    return TextTheme(
      headlineLarge: TextStyle(
          color: color, fontSize: 30, fontWeight: FontWeight.w800, height: 1.1),
      headlineMedium: TextStyle(
          color: color,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.15),
      titleLarge:
          TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800),
      titleMedium:
          TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(color: color, fontSize: 16, height: 1.45),
      bodyMedium: TextStyle(color: color, fontSize: 14, height: 1.4),
      bodySmall:
          TextStyle(color: color.withAlpha(170), fontSize: 12, height: 1.35),
      labelLarge:
          TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
      labelMedium:
          TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      labelSmall:
          TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    );
  }
}
