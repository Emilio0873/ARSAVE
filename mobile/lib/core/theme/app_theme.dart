import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palettes commutables : bleu de nuit, minuit, clair.
class AppColors {
  static Color deepTeal = const Color(0xFF070B18);
  static Color teal = const Color(0xFF3B82F6);
  static Color mint = const Color(0xFF60A5FA);
  static Color foam = const Color(0xFF152238);
  static Color mist = const Color(0xFF0B1224);
  static Color ink = const Color(0xFFE8EEF8);
  static Color slate = const Color(0xFF9AA8C7);
  static Color coral = const Color(0xFF5B8DEF);
  static Color sun = const Color(0xFF93C5FD);
  static Color white = const Color(0xFFF4F7FC);
  static Color line = const Color(0xFF243352);
  static Color panel = const Color(0xFF121C33);
  static Color panelSoft = const Color(0xFF182640);
  static Color bgTop = const Color(0xFF050914);
  static Color bgMid = const Color(0xFF0B1224);
  static Color bgBottom = const Color(0xFF0E1A36);
  static bool isLight = false;

  static void apply(String id) {
    switch (id) {
      case 'light':
        isLight = true;
        deepTeal = const Color(0xFF0B1F4D);
        teal = const Color(0xFF1D4ED8);
        mint = const Color(0xFF2563EB);
        foam = const Color(0xFFE7EEFB);
        mist = const Color(0xFFF3F6FB);
        ink = const Color(0xFF0F172A);
        slate = const Color(0xFF475569);
        coral = const Color(0xFF1D4ED8);
        sun = const Color(0xFF3B82F6);
        white = const Color(0xFFFFFFFF);
        line = const Color(0xFFD5DEEF);
        panel = const Color(0xFFFFFFFF);
        panelSoft = const Color(0xFFF8FAFC);
        bgTop = const Color(0xFFE8F0FF);
        bgMid = const Color(0xFFF4F7FC);
        bgBottom = const Color(0xFFDCE7FA);
      case 'abyss':
        isLight = false;
        deepTeal = const Color(0xFF02040A);
        teal = const Color(0xFF2563EB);
        mint = const Color(0xFF38BDF8);
        foam = const Color(0xFF0E1628);
        mist = const Color(0xFF05070E);
        ink = const Color(0xFFE7EEF8);
        slate = const Color(0xFF8B9BB8);
        coral = const Color(0xFF38BDF8);
        sun = const Color(0xFF7DD3FC);
        white = const Color(0xFFF8FAFC);
        line = const Color(0xFF1A2744);
        panel = const Color(0xFF0A1020);
        panelSoft = const Color(0xFF10182C);
        bgTop = const Color(0xFF02040A);
        bgMid = const Color(0xFF05070E);
        bgBottom = const Color(0xFF0B1730);
      default:
        isLight = false;
        deepTeal = const Color(0xFF070B18);
        teal = const Color(0xFF3B82F6);
        mint = const Color(0xFF60A5FA);
        foam = const Color(0xFF152238);
        mist = const Color(0xFF0B1224);
        ink = const Color(0xFFE8EEF8);
        slate = const Color(0xFF9AA8C7);
        coral = const Color(0xFF5B8DEF);
        sun = const Color(0xFF93C5FD);
        white = const Color(0xFFF4F7FC);
        line = const Color(0xFF243352);
        panel = const Color(0xFF121C33);
        panelSoft = const Color(0xFF182640);
        bgTop = const Color(0xFF050914);
        bgMid = const Color(0xFF0B1224);
        bgBottom = const Color(0xFF0E1A36);
    }
  }
}

class AppTheme {
  static ThemeData light() {
    // Nom historique : thème unique bleu de nuit.
    return night();
  }

  static ThemeData night() {
    final dark = !AppColors.isLight;
    final baseText = GoogleFonts.outfitTextTheme(
      dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );
    final colorScheme = dark
        ? ColorScheme.dark(
      primary: AppColors.teal,
      onPrimary: AppColors.white,
      secondary: AppColors.mint,
      onSecondary: AppColors.deepTeal,
      tertiary: AppColors.sun,
      surface: AppColors.panel,
      onSurface: AppColors.ink,
      error: const Color(0xFFF87171),
      outline: AppColors.line,
    )
        : ColorScheme.light(
            primary: AppColors.teal,
            onPrimary: AppColors.white,
            secondary: AppColors.mint,
            onSecondary: AppColors.white,
            tertiary: AppColors.sun,
            surface: AppColors.panel,
            onSurface: AppColors.ink,
            error: const Color(0xFFDC2626),
            outline: AppColors.line,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.mist,
      textTheme: baseText.copyWith(
        displayLarge: baseText.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: -1.2,
        ),
        headlineLarge: baseText.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: -0.8,
        ),
        headlineMedium: baseText.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(color: AppColors.slate),
        bodyMedium: baseText.bodyMedium?.copyWith(color: AppColors.slate),
        labelLarge: baseText.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: AppColors.ink,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ink,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        iconTheme: IconThemeData(color: AppColors.ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.panelSoft,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.teal, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF87171)),
        ),
        labelStyle: GoogleFonts.outfit(color: AppColors.slate),
        prefixIconColor: AppColors.slate,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: AppColors.line, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.mint,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.panelSoft,
        contentTextStyle: GoogleFonts.outfit(color: AppColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.panel.withValues(alpha: 0.96),
        indicatorColor: AppColors.teal.withValues(alpha: 0.22),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: AppColors.mint),
        ),
        elevation: 0,
        height: 72,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.teal,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.panelSoft,
        textStyle: GoogleFonts.outfit(color: AppColors.ink),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.panel,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.outfit(color: AppColors.slate),
      ),
      dividerColor: AppColors.line,
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.teal,
      ),
    );
  }
}
