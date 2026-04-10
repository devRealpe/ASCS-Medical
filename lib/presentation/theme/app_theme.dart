// lib/presentation/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'medical_colors.dart';

/// Configuración de temas de la aplicación
class AppTheme {
  AppTheme._();

  // ═════════════════════════════════════════════════════════════════════════
  //  TEMA CLARO
  // ═════════════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: MedicalColors.primaryBlue,
      secondary: MedicalColors.secondaryTeal,
      tertiary: MedicalColors.accentCyan,
      brightness: Brightness.light,
      error: MedicalColors.errorRed,
      surface: Colors.white,
      onSurface: MedicalColors.textPrimary,
      onSurfaceVariant: MedicalColors.textSecondary,
    );

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: MedicalColors.primaryBlue,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: MedicalColors.backgroundLight,
      cardColor: MedicalColors.cardWhite,
      dividerColor: MedicalColors.dividerGrey,
      textTheme: _buildTextTheme(Brightness.light),
      elevatedButtonTheme: _buildElevatedButtonTheme(Brightness.light),
      textButtonTheme: _buildTextButtonTheme(Brightness.light),
      outlinedButtonTheme: _buildOutlinedButtonTheme(Brightness.light),
      inputDecorationTheme: _buildInputDecorationTheme(Brightness.light),
      cardTheme: _buildCardTheme(Brightness.light),
      appBarTheme: _buildAppBarTheme(Brightness.light),
      dialogTheme: _buildDialogTheme(Brightness.light),
      dividerTheme: _buildDividerTheme(Brightness.light),
      snackBarTheme: _buildSnackBarTheme(Brightness.light),
      bottomSheetTheme: _buildBottomSheetTheme(Brightness.light),
      iconTheme:
          const IconThemeData(color: MedicalColors.primaryBlue, size: 24),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: MedicalColors.primaryBlue,
        circularTrackColor: Color(0xFFE3F2FD),
      ),
      expansionTileTheme: _buildExpansionTileTheme(Brightness.light),
      chipTheme: _buildChipTheme(Brightness.light),
      useMaterial3: true,
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  TEMA OSCURO
  // ═════════════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: MedicalColors.darkPrimary,
      secondary: MedicalColors.darkSecondary,
      tertiary: MedicalColors.darkAccent,
      brightness: Brightness.dark,
      error: const Color(0xFFEF5350),
      surface: MedicalColors.darkCard,
      onSurface: MedicalColors.darkTextPrimary,
      onSurfaceVariant: MedicalColors.darkTextSecondary,
    );

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: MedicalColors.darkPrimary,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: MedicalColors.darkBackground,
      cardColor: MedicalColors.darkCard,
      dividerColor: MedicalColors.darkDivider,
      textTheme: _buildTextTheme(Brightness.dark),
      elevatedButtonTheme: _buildElevatedButtonTheme(Brightness.dark),
      textButtonTheme: _buildTextButtonTheme(Brightness.dark),
      outlinedButtonTheme: _buildOutlinedButtonTheme(Brightness.dark),
      inputDecorationTheme: _buildInputDecorationTheme(Brightness.dark),
      cardTheme: _buildCardTheme(Brightness.dark),
      appBarTheme: _buildAppBarTheme(Brightness.dark),
      dialogTheme: _buildDialogTheme(Brightness.dark),
      dividerTheme: _buildDividerTheme(Brightness.dark),
      snackBarTheme: _buildSnackBarTheme(Brightness.dark),
      bottomSheetTheme: _buildBottomSheetTheme(Brightness.dark),
      iconTheme:
          const IconThemeData(color: MedicalColors.darkPrimary, size: 24),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: MedicalColors.darkPrimary,
        circularTrackColor: Color(0xFF1A2744),
      ),
      expansionTileTheme: _buildExpansionTileTheme(Brightness.dark),
      chipTheme: _buildChipTheme(Brightness.dark),
      useMaterial3: true,
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  CONSTRUCTORES DE COMPONENTES
  // ═════════════════════════════════════════════════════════════════════════

  static bool _isDark(Brightness b) => b == Brightness.dark;

  static TextTheme _buildTextTheme(Brightness b) {
    final dark = _isDark(b);
    final primary =
        dark ? MedicalColors.darkPrimary : MedicalColors.primaryBlue;
    final onSurface =
        dark ? MedicalColors.darkTextPrimary : MedicalColors.textPrimary;
    final secondary =
        dark ? MedicalColors.darkTextSecondary : MedicalColors.textSecondary;
    final hint = dark ? MedicalColors.darkTextHint : MedicalColors.textHint;

    return TextTheme(
      headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primary,
          letterSpacing: 0.5),
      headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: onSurface,
          letterSpacing: 0.5),
      headlineSmall: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: onSurface),
      titleLarge: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: onSurface),
      titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
      bodyLarge: TextStyle(fontSize: 16, color: secondary, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, color: secondary, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, color: hint),
      labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(Brightness b) {
    final dark = _isDark(b);
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            dark ? MedicalColors.darkPrimary : MedicalColors.primaryBlue,
        foregroundColor: dark ? MedicalColors.darkBackground : Colors.white,
        elevation: dark ? 4 : 2,
        shadowColor:
            (dark ? MedicalColors.darkPrimary : MedicalColors.primaryBlue)
                .withAlpha(60),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(Brightness b) {
    final dark = _isDark(b);
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor:
            dark ? MedicalColors.darkPrimary : MedicalColors.primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(Brightness b) {
    final dark = _isDark(b);
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor:
            dark ? MedicalColors.darkPrimary : MedicalColors.primaryBlue,
        side: BorderSide(
            color:
                dark ? MedicalColors.darkDivider : MedicalColors.dividerGrey),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(Brightness b) {
    final dark = _isDark(b);
    final fill = dark ? MedicalColors.darkSurface : const Color(0xFFFAFAFA);
    final border = dark ? MedicalColors.darkDivider : const Color(0xFFE0E0E0);
    final focusBorder =
        dark ? MedicalColors.darkPrimary : MedicalColors.primaryBlue;
    final label =
        dark ? MedicalColors.darkTextSecondary : MedicalColors.textSecondary;
    final hintColor =
        dark ? MedicalColors.darkTextHint : const Color(0xFFBDBDBD);

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: focusBorder, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: dark ? const Color(0xFFEF5350) : MedicalColors.errorRed,
            width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: dark ? const Color(0xFFEF5350) : MedicalColors.errorRed,
            width: 2.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: label, fontWeight: FontWeight.w500),
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
    );
  }

  static CardThemeData _buildCardTheme(Brightness b) {
    final dark = _isDark(b);
    return CardThemeData(
      elevation: dark ? 2 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: dark ? MedicalColors.darkCard : Colors.white,
      shadowColor: dark
          ? Colors.black.withAlpha(80)
          : MedicalColors.primaryBlue.withAlpha(38),
      margin: const EdgeInsets.symmetric(vertical: 8),
    );
  }

  static AppBarTheme _buildAppBarTheme(Brightness b) {
    final dark = _isDark(b);
    return AppBarTheme(
      backgroundColor:
          dark ? MedicalColors.darkSurface : MedicalColors.primaryBlue,
      foregroundColor: dark ? MedicalColors.darkTextPrimary : Colors.white,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle:
          dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: dark ? MedicalColors.darkTextPrimary : Colors.white,
      ),
      iconTheme: IconThemeData(
        color: dark ? MedicalColors.darkTextPrimary : Colors.white,
        size: 24,
      ),
    );
  }

  static DialogThemeData _buildDialogTheme(Brightness b) {
    final dark = _isDark(b);
    return DialogThemeData(
      backgroundColor: dark ? MedicalColors.darkCard : Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: dark ? MedicalColors.darkTextPrimary : MedicalColors.textPrimary,
      ),
      contentTextStyle: TextStyle(
        fontSize: 14,
        color: dark
            ? MedicalColors.darkTextSecondary
            : MedicalColors.textSecondary,
      ),
    );
  }

  static DividerThemeData _buildDividerTheme(Brightness b) {
    final dark = _isDark(b);
    return DividerThemeData(
      color: dark ? MedicalColors.darkDivider : const Color(0xFFE0E0E0),
      thickness: 1,
      space: 20,
    );
  }

  static SnackBarThemeData _buildSnackBarTheme(Brightness b) {
    final dark = _isDark(b);
    return SnackBarThemeData(
      backgroundColor:
          dark ? MedicalColors.darkCard : MedicalColors.textPrimary,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    );
  }

  static BottomSheetThemeData _buildBottomSheetTheme(Brightness b) {
    final dark = _isDark(b);
    return BottomSheetThemeData(
      backgroundColor: dark ? MedicalColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  static ExpansionTileThemeData _buildExpansionTileTheme(Brightness b) {
    final dark = _isDark(b);
    return ExpansionTileThemeData(
      backgroundColor: dark ? MedicalColors.darkCard : Colors.white,
      collapsedBackgroundColor: dark ? MedicalColors.darkCard : Colors.white,
      iconColor: dark ? MedicalColors.darkPrimary : MedicalColors.primaryBlue,
      textColor:
          dark ? MedicalColors.darkTextPrimary : MedicalColors.textPrimary,
    );
  }

  static ChipThemeData _buildChipTheme(Brightness b) {
    final dark = _isDark(b);
    return ChipThemeData(
      backgroundColor:
          dark ? MedicalColors.darkSurface : const Color(0xFFF5F7FA),
      labelStyle: TextStyle(
        color: dark ? MedicalColors.darkTextPrimary : MedicalColors.textPrimary,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
