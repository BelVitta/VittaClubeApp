import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Cores principais
  static const Color primaryColor = Color(0xFF2C4156);
  static const Color secondaryColor = Color(0xFF39586D);
  static const Color gradientLight = Color(0xFF91BDEA);
  static const Color gradientDark = Color(0xFF2C4156);

  // Cores de background
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color secondaryBackground = Color(0xFFF5F5F5);
  static const Color inputBackground = Color(0xFFF6F8FE); // Figma design

  // Cores de texto
  static const Color primaryText = Color(0xFF031535); // Figma design
  static const Color secondaryText = Color(0xFF6D7F95); // Figma design
  static const Color labelColor = Color(0xFF7B61FF); // Figma design - input label

  // Cores de borda e estados
  static const Color borderColor = Color(0xFFE0E3E7);
  static const Color errorColor = Color(0xFFFF5963);
  static const Color successColor = Color(0xFF249689);

  // Cores dos indicadores
  static const Color indicatorActive = Color(0xFF121515);
  static const Color indicatorInactive = Color(0xFFF0F0F0);

  /// ThemeData principal
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: backgroundColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.outfitTextTheme(),
    );
  }

  // Estilos de texto
  static TextStyle get headingLarge => GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: primaryText,
      );

  static TextStyle get headingMedium => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: primaryText,
      );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: primaryText,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: primaryText,
      );

  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: labelColor,
      );

  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: secondaryText,
      );

  static TextStyle get buttonText => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      );

  // Input decoration padrão
  static InputDecoration inputDecoration({
    required String label,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: secondaryText,
      ),
      filled: true,
      fillColor: inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(24),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(24),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: errorColor, width: 1),
        borderRadius: BorderRadius.circular(24),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: errorColor, width: 1),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  // Gradientes
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [gradientLight, gradientLight, gradientDark],
        stops: [0, 0.5, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient overlayGradient(Color endColor) => LinearGradient(
        colors: [Colors.transparent, endColor],
        stops: const [0, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}
