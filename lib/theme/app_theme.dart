import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 1. Barevná paleta
  static const Color bgDark = Color(0xFF1A1A1D);       // Temné pozadí dungeonu
  static const Color panelDark = Color(0xFF222225);    // Tmavší panely
  static const Color panelWood = Color(0xFF3E2723);    // Tmavé dřevo / kůže
  static const Color accentGold = Color(0xFFFFB300);   // Zlato, loot, aktivní prvky
  static const Color stepsGreen = Color(0xFF2E7D32);   // Energie / Kroky
  static const Color textLight = Color(0xFFD7CCC8);    // Světlý pergamen pro texty
  static const Color textError = Color(0xFFD32F2F);    // Krev / Zranění / Chyby

  // 2. Globální téma aplikace
  static ThemeData get darkTheme {
    return ThemeData(
      scaffoldBackgroundColor: bgDark,
      primaryColor: panelWood,
      colorScheme: const ColorScheme.dark(
        primary: accentGold,
        secondary: stepsGreen,
        surface: panelDark,
        error: textError,
      ),
      // Nastavení fontů pro celou aplikaci
      textTheme: TextTheme(
        // Nadpisy (Názvy obrazovek, jména Bossů) - komiksovější, fantasy font
        displayLarge: GoogleFonts.macondo(color: accentGold, fontSize: 32, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.macondo(color: textLight, fontSize: 24, fontWeight: FontWeight.bold),
        titleMedium: GoogleFonts.macondo(color: textLight, fontSize: 20, fontWeight: FontWeight.w600),
        
        // Běžný text (popisky itemů, logy) - čitelný patkový font
        bodyLarge: GoogleFonts.alegreya(color: textLight, fontSize: 16),
        bodyMedium: GoogleFonts.alegreya(color: textLight, fontSize: 14),
      ),
    );
  }
}