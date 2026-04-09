// lib/core/constants/api_constants.dart

/// Constantes para la conexión con la API REST del servidor
class ApiConstants {
  ApiConstants._();

  /// URL base del servidor — cambiar por la IP real en producción
  static const String baseUrl = 'http://localhost:4001';

  // ── Endpoints de autenticación ──────────────────────────────────────────
  static const String register = '/api/auth/register';

  // ── Endpoints de configuración médica ───────────────────────────────────
  static const String focos = '/api/focos';
  static const String categoriasAnomalias = '/api/categorias-anomalias';
  static const String enfermedades = '/api/enfermedades';
  static const String instituciones = '/api/instituciones';

  /// Consultorios de una institución: /api/instituciones/{id}/consultorios
  static String consultoriosPorInstitucion(int institucionId) =>
      '/api/instituciones/$institucionId/consultorios';
}
