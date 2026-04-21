// lib/core/constants/api_constants.dart

/// Constantes para la conexión con la API REST del servidor
class ApiConstants {
  ApiConstants._();

  /// URL base del servidor principal (auth, config, diagnósticos)
  static const String baseUrl = 'https://cardioai.app';

  /// URL base del servidor de entrenamiento
  static const String trainBaseUrl = 'http://35.231.170.12:5000';

  /// URL base del servicio 2 — ingesta de archivos diagnósticos
  static const String service2BaseUrl = 'http://34.138.217.86:3002';

  /// URL base del servicio 3 — predicción IA
  static const String service3BaseUrl = 'http://34.138.217.86:3004';

  // ── Endpoint de entrenamiento ───────────────────────────────────────────
  static const String train = '/train';

  // ── Endpoints de servicios v1 ───────────────────────────────────────────
  static const String ingest = '/ingest';
  static const String predict = '/predict';

  // ── Endpoints de autenticación ──────────────────────────────────────────
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';

  // ── Endpoints de configuración médica ───────────────────────────────────
  static const String focos = '/api/focos';
  static const String categoriasAnomalias = '/api/categorias-anomalias';
  static const String enfermedades = '/api/enfermedades';
  static const String instituciones = '/api/instituciones';

  /// Consultorios de una institución: /api/instituciones/{id}/consultorios
  static String consultoriosPorInstitucion(int institucionId) =>
      '/api/instituciones/$institucionId/consultorios';

  // ── Endpoints de diagnósticos ───────────────────────────────────────────
  static const String diagnostics = '/api/diagnostics';
  static const String diagnosticosByCreator = '/api/diagnostics/by-creator';

  /// Confirmar valvulopatía: PATCH /api/diagnostics/{id}/confirm-valvulopatia
  static String confirmValvulopatia(int diagnosticoId) =>
      '/api/diagnostics/$diagnosticoId/confirm-valvulopatia';
}
