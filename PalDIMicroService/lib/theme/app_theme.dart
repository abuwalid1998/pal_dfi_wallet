import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // --- FacePal Sense & iD+ Official Color Palette ---
  static const Color facepalBlue = Color(0xFF00A3FF);      // Electric Sky Blue (FacePal Sense)
  static const Color facepalBlueDark = Color(0xFF0077CC);  // Deep Cyan Accent
  static const Color facepalBlueLight = Color(0xFF60C5FF); // Soft Luminous Blue

  static const Color idPlusNavy = Color(0xFF0A3663);       // Signature iD+ Midnight Navy
  static const Color idPlusPurple = Color(0xFF7B287D);     // Signature iD+ Royal Purple Tile
  static const Color idPlusCyan = Color(0xFF70C4E8);       // Signature iD+ Sky Cyan Tile
  static const Color idPlusGold = Color(0xFFC69255);       // Signature iD+ Sahara Sand Tile
  static const Color idPlusNavyDeep = Color(0xFF062344);   // Deepest Sovereign Blue

  // Primary Blue Tones (Institutional, Trust, Academic)
  static const Color navyDark = Color(0xFF05111E);
  static const Color navyPrimary = Color(0xFF0A3663);
  static const Color navyLight = Color(0xFF134A80);
  static const Color blueAccent = Color(0xFF00A3FF);
  static const Color blueSurface = Color(0xFF0E243E);

  // Vibrant Brand & Accent Tones
  static const Color goldPrimary = Color(0xFF00A3FF);      // Vibrant FacePal Blue Accent
  static const Color brandGold = Color(0xFFC69255);        // Warm Sahara Sand (iD+ Tile)
  static const Color goldLight = Color(0xFF70C4E8);        // Soft iD+ Sky Cyan
  static const Color goldDark = Color(0xFF0077CC);         // Deep Accent
  static const Color amberWarning = Color(0xFFF59E0B);

  // Midnight & Slate Touches (Deep Navy-tinted Tech Aesthetics)
  static const Color obsidianBlack = Color(0xFF060F1A);
  static const Color charcoalDark = Color(0xFF0A182A);
  static const Color slateCard = Color(0xFF0F223A);
  static const Color slateCardBorder = Color(0xFF1B3B60);
  static const Color charcoalElevated = Color(0xFF142B48);

  // Convenient Theme Aliases
  static const Color goldAccent = Color(0xFFD4AF37);       // Sovereign Gold Accent
  static const Color electricCyan = Color(0xFF00A3FF);     // FacePal Electric Cyan
  static const Color emeraldGreen = Color(0xFF10B981);     // Active Emerald
  static const Color crimsonRevoked = Color(0xFFEF4444);   // Revoked Crimson
  static const Color midnightCard = Color(0xFF0F223A);     // Slate Midnight Card

  // Functional Status Colors
  static const Color statusActive = Color(0xFF10B981);     // Emerald Green
  static const Color statusRevoked = Color(0xFFEF4444);    // Crimson
  static const Color statusExpired = Color(0xFFF59E0B);    // Amber
  static const Color statusPending = Color(0xFF64748B);    // Gray

  // Typography & Dividers
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textSubtle = Color(0xFF64748B);
  static const Color borderLight = Color(0xFF1E3A5F);
}

class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.obsidianBlack,
      primaryColor: AppColors.idPlusNavy,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.facepalBlue,
        onPrimary: AppColors.obsidianBlack,
        primaryContainer: AppColors.idPlusNavy,
        onPrimaryContainer: AppColors.facepalBlueLight,
        secondary: AppColors.idPlusGold,
        onSecondary: AppColors.obsidianBlack,
        tertiary: AppColors.idPlusPurple,
        surface: AppColors.slateCard,
        onSurface: AppColors.textLight,
        error: AppColors.statusRevoked,
      ),
      cardTheme: CardThemeData(
        color: AppColors.slateCard,
        elevation: 4,
        shadowColor: Colors.black.withAlpha(140),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.slateCardBorder, width: 1.2),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.obsidianBlack.withAlpha(240),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.facepalBlue),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: AppColors.textLight,
          letterSpacing: 0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.facepalBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.facepalBlue,
          side: const BorderSide(color: AppColors.facepalBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.charcoalDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slateCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slateCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.facepalBlue, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.textSubtle, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.inter(
          color: AppColors.textLight,
          fontWeight: FontWeight.w800,
          fontSize: 28,
        ),
        headlineMedium: GoogleFonts.inter(
          color: AppColors.textLight,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        titleLarge: GoogleFonts.inter(
          color: AppColors.textLight,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        titleMedium: GoogleFonts.inter(
          color: AppColors.facepalBlueLight,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.textLight,
          fontSize: 15,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 13.5,
        ),
      ),
    );
  }
}
