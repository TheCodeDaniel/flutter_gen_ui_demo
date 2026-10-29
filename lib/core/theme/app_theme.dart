import 'package:flutter/material.dart';

/// The app's colours, inspired by a pot of jollof rice.
abstract final class AppColors {
  static const jollof = Color(0xFFE4572E); // primary: tomato-pepper red
  static const leaf = Color(0xFF2E7D4F); // secondary: ugwu leaf green
  static const pepper = Color(0xFFF4B942); // accent: yellow pepper
  static const cream = Color(0xFFFFF8F0); // page background
  static const card = Colors.white;
  static const ink = Color(0xFF2B1D14); // main text
  static const muted = Color(0xFF8A7A6D); // secondary text
  static const outline = Color(0xFFF0E4D7);
}

/// One theme for the whole app.
///
/// GenUI's basic widgets (buttons, chips, text fields...) are normal Material
/// widgets, so the UI the AI builds picks up this theme automatically.
abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.jollof,
      primary: AppColors.jollof,
      secondary: AppColors.leaf,
      tertiary: AppColors.pepper,
      surface: AppColors.card,
      onSurface: AppColors.ink,
    );

    final roundedShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(26));

    return ThemeData(
      useMaterial3: true,
      fontFamily: "Poppins",
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.jollof,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: roundedShape,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontFamily: "Poppins", fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: roundedShape)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: roundedShape)),

      // Chips (used by GenUI's ChoicePicker)
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.jollof.withValues(alpha: 0.15),
        side: const BorderSide(color: AppColors.outline),
        shape: roundedShape,
        labelStyle: const TextStyle(fontFamily: "Poppins", color: AppColors.ink),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),

      // Text fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: AppColors.jollof),
        ),
        hintStyle: const TextStyle(color: AppColors.muted),
      ),

      checkboxTheme: CheckboxThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
      dividerTheme: const DividerThemeData(color: AppColors.outline),
    );
  }
}
