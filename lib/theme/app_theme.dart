import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide custom colors tailored for a high-density, professional Monaco/VS Code dark theme.
class AppColors {
  static const Color background = Color(0xFF1E1E1E); // Monaco / VS Code deep charcoal background
  static const Color cardBg = Color(0xFF252526); // Slate charcoal for card surfaces, files pane, settings
  static const Color sidebarBg = Color(0xFF181818); // Dark charcoal for activity bar & explorer sidebar
  static const Color border = Color(0xFF2D2D2D); // Subtle grid separators and borders

  // Neon glows for cyberpunk accent elements
  static const Color neonCyan = Color(0xFF00E5FF); // Bright cyan for active cursor/indicator
  static const Color neonGreen = Color(0xFF4CAF50); // Emerald green for git status/compilation success
  static const Color neonPurple = Color(0xFF9C27B0); // Deep violet for agents and AI activities
  static const Color neonPink = Color(0xFFF44336); // Red/Pink for git deletions & compiler errors
  static const Color warning = Color(0xFFFFC107); // Gold yellow for modifications & warnings

  // Font Colors
  static const Color textPrimary = Color(0xFFCCCCCC); // VS Code standard light gray-white for clarity
  static const Color textSecondary = Color(0xFF858585); // Muted gray for descriptions and secondary UI
  static const Color textMuted = Color(0xFF5A5A5A); // Dim gray for disabled/inactive items

  // Code Syntax Colors (Monokai Sublime / VS Code hybrid adaptation)
  static const Color syntaxKeyword = Color(0xFF569CD6); // Blue for keywords
  static const Color syntaxString = Color(0xFFCE9178); // Soft red-orange for strings
  static const Color syntaxFunction = Color(0xFFDCDCAA); // Pale yellow-green for functions
  static const Color syntaxComment = Color(0xFF6A9955); // Forest green for comments
  static const Color syntaxNumber = Color(0xFFB5CEA8); // Light olive green for numbers
  static const Color syntaxClass = Color(0xFF4EC9B0); // Teal for classes/types

  // Gradients for highlights
  static const LinearGradient highlightGradient = LinearGradient(
    colors: [neonCyan, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Dynamic theme styling properties for the app.
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.cardBg,
      dividerColor: AppColors.border,
      primaryColor: AppColors.neonCyan,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonCyan,
        secondary: AppColors.neonGreen,
        surface: AppColors.cardBg,
        error: AppColors.neonPink,
      ),

      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyLarge: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        bodyMedium: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        titleLarge: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.sidebarBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.neonCyan),
        ),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.border),
        radius: const Radius.circular(2),
        thickness: WidgetStateProperty.all(4.0),
      ),
    );
  }

  static ThemeData get lightTheme {
    const Color lightBg = Color(0xFFFFFFFF);
    const Color lightCard = Color(0xFFFBFBFB);
    const Color lightSidebar = Color(0xFFF3F3F3);
    const Color lightBorder = Color(0xFFE0E0E0);
    const Color lightText = Color(0xFF222222);
    const Color lightTextSec = Color(0xFF777777);
    const Color accentCyan = Color(0xFF007ACC);
    const Color accentGreen = Color(0xFF2E7D32);
    const Color accentPink = Color(0xFFC62828);

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      cardColor: lightCard,
      dividerColor: lightBorder,
      primaryColor: accentCyan,

      colorScheme: const ColorScheme.light(
        primary: accentCyan,
        secondary: accentGreen,
        surface: lightCard,
        error: accentPink,
      ),

      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        bodyLarge: const TextStyle(color: lightText, fontSize: 13),
        bodyMedium: const TextStyle(color: lightTextSec, fontSize: 11),
        titleLarge: GoogleFonts.outfit(
          color: lightText,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: lightSidebar,
        elevation: 0,
        iconTheme: const IconThemeData(color: lightText),
        titleTextStyle: GoogleFonts.outfit(
          color: lightText,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(color: lightTextSec),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: accentCyan),
        ),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(lightBorder),
        radius: const Radius.circular(2),
        thickness: WidgetStateProperty.all(4.0),
      ),
    );
  }
}
