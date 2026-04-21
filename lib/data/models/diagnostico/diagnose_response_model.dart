// lib/data/models/diagnostico/diagnose_response_model.dart
//
// Modelo de respuesta del Servicio 3 — POST /predict

class DiagnoseResponseModel {
  final String estado;
  final double precision;
  final double umbral;
  final DiagnoseScores scores;
  final DiagnoseLimpieza limpieza;

  const DiagnoseResponseModel({
    required this.estado,
    required this.precision,
    required this.umbral,
    required this.scores,
    required this.limpieza,
  });

  factory DiagnoseResponseModel.fromJson(Map<String, dynamic> json) {
    return DiagnoseResponseModel(
      estado: json['estado'] as String? ?? '',
      precision: (json['precision'] as num?)?.toDouble() ?? 0.0,
      umbral: (json['umbral'] as num?)?.toDouble() ?? 0.0,
      scores: DiagnoseScores.fromJson(
          json['scores'] as Map<String, dynamic>? ?? {}),
      limpieza: DiagnoseLimpieza.fromJson(
          json['limpieza'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// Helper: true si el estado es "normal"
  bool get esNormal => estado.toLowerCase() == 'normal';
}

class DiagnoseScores {
  final double anormal;
  final double normal;

  const DiagnoseScores({
    required this.anormal,
    required this.normal,
  });

  factory DiagnoseScores.fromJson(Map<String, dynamic> json) {
    return DiagnoseScores(
      anormal: (json['anormal'] as num?)?.toDouble() ?? 0.0,
      normal: (json['normal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DiagnoseLimpieza {
  final int sampleRate;
  final double durationSeconds;

  const DiagnoseLimpieza({
    required this.sampleRate,
    required this.durationSeconds,
  });

  factory DiagnoseLimpieza.fromJson(Map<String, dynamic> json) {
    return DiagnoseLimpieza(
      sampleRate: json['sample_rate'] as int? ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
