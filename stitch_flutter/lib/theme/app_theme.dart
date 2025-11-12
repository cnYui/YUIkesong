import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StitchColors {
  StitchColors._();

  static const Color primary = Color(0xFF13C8EC);
  static const Color background = Color(0xFFF6F8F8);
  static const Color backgroundDark = Color(0xFF101F22);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color wardrobeBeige = Color(0xFFF5F5DC);
  static const Color wardrobeGreen = Color(0xFFD7E5D8);
  static const Color surfaceLight = Colors.white;
  static const Color shadow = Color(0x14000000);
}

class StitchTheme {
  StitchTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
    return base.copyWith(
      primaryColor: StitchColors.primary,
      scaffoldBackgroundColor: StitchColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: StitchColors.primary,
        surface: StitchColors.background,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: StitchColors.textPrimary,
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        selectedItemColor: StitchColors.primary,
        unselectedItemColor: StitchColors.textSecondary,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
