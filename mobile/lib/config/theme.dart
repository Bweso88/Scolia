import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const navy   = Color(0xFF0D1B3E);
  static const amber  = Color(0xFFF5A623);
  static const bg     = Color(0xFFF2F4F9);
  static const white  = Color(0xFFFFFFFF);
  static const border = Color(0xFFDDE2EF);
  static const body   = Color(0xFF4B5670);
  static const muted  = Color(0xFF8E99B4);
  static const green  = Color(0xFF059669);
  static const red    = Color(0xFFDC2626);
  static const blue   = Color(0xFF2563EB);
  static const purple = Color(0xFF7C3AED);
  static const orange = Color(0xFFF97316);
  static const light  = Color(0xFFEFF2FA);
}

/// [primary]/[secondary] : couleurs de l'école chargées au runtime depuis
/// son branding (docs/PRODUCT_ARCHITECTURE.md §16). À défaut (avant
/// connexion, ou école n'ayant pas personnalisé ses couleurs), on retombe
/// sur l'identité visuelle par défaut de Scolia.
ThemeData buildTheme({Color? primary, Color? secondary}) {
  final couleurPrimaire   = primary ?? AppColors.navy;
  final couleurSecondaire = secondary ?? AppColors.amber;

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: couleurPrimaire,
      primary: couleurPrimaire,
      secondary: couleurSecondaire,
      surface: AppColors.bg,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
      bodyMedium: GoogleFonts.plusJakartaSans(color: AppColors.body),
      bodySmall:  GoogleFonts.plusJakartaSans(color: AppColors.muted),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: couleurPrimaire,
      foregroundColor: AppColors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.white,
      surfaceTintColor: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: AppColors.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: couleurPrimaire,
        foregroundColor: AppColors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: couleurPrimaire, width: 2),
      ),
    ),
  );
  return base;
}
