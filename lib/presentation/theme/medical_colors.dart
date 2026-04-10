// lib/presentation/theme/medical_colors.dart
import 'package:flutter/material.dart';

/// Paleta de colores médicos de la aplicación
class MedicalColors {
  MedicalColors._(); // Prevenir instanciación

  // ─── Colores primarios ─────────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color secondaryTeal = Color(0xFF00897B);
  static const Color accentCyan = Color(0xFF00ACC1);
  static const Color lightBlue = Color(0xFF42A5F5);

  // ─── Colores de estado ─────────────────────────────────────────────────
  static const Color successGreen = Color(0xFF43A047);
  static const Color warningOrange = Color(0xFFFF6F00);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color infoBlue = Color(0xFF1976D2);

  // ─── Light mode ────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color surfaceGrey = Color(0xFFFAFAFA);
  static const Color dividerGrey = Color(0xFFE0E0E0);

  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color textHint = Color(0xFF90A4AE);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // ─── Dark mode ─────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F1118);
  static const Color darkSurface = Color(0xFF1A1C25);
  static const Color darkCard = Color(0xFF222430);
  static const Color darkDivider = Color(0xFF2E3140);

  static const Color darkTextPrimary = Color(0xFFE2E4EA);
  static const Color darkTextSecondary = Color(0xFF9A9DAE);
  static const Color darkTextHint = Color(0xFF636678);

  static const Color darkPrimary = Color(0xFF64B5F6);
  static const Color darkSecondary = Color(0xFF4DB6AC);
  static const Color darkAccent = Color(0xFF4DD0E1);

  // ─── Gradientes ────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkPrimaryGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F7FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF222430), Color(0xFF1A1C25)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// Extensión para obtener colores adaptativos según el tema actual.
extension MedicalColorScheme on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  Color get background =>
      _isDark ? MedicalColors.darkBackground : MedicalColors.backgroundLight;
  Color get surface =>
      _isDark ? MedicalColors.darkCard : MedicalColors.cardWhite;
  Color get divider =>
      _isDark ? MedicalColors.darkDivider : MedicalColors.dividerGrey;
  Color get onSurface =>
      _isDark ? MedicalColors.darkTextPrimary : MedicalColors.textPrimary;
  Color get onSurfaceSecondary =>
      _isDark ? MedicalColors.darkTextSecondary : MedicalColors.textSecondary;
  Color get hint =>
      _isDark ? MedicalColors.darkTextHint : MedicalColors.textHint;
  Color get primary =>
      _isDark ? MedicalColors.darkPrimary : MedicalColors.primaryBlue;
  Color get secondary =>
      _isDark ? MedicalColors.darkSecondary : MedicalColors.secondaryTeal;
  Color get accent =>
      _isDark ? MedicalColors.darkAccent : MedicalColors.accentCyan;

  LinearGradient get primaryGradient => _isDark
      ? MedicalColors.darkPrimaryGradient
      : MedicalColors.primaryGradient;

  LinearGradient get cardGradient =>
      _isDark ? MedicalColors.darkCardGradient : MedicalColors.cardGradient;

  Color get inputFill =>
      _isDark ? MedicalColors.darkSurface : const Color(0xFFFAFAFA);
  Color get inputBorder =>
      _isDark ? MedicalColors.darkDivider : const Color(0xFFE0E0E0);
}
