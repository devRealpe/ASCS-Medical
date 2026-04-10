// lib/data/models/diagnostico/diagnose_response_model.dart
//
// Modelo de respuesta del Servicio 3 — POST /api/v1/diagnose

class DiagnoseResponseModel {
  final String timestampDiagnostico;
  final String archivoAnalizado;
  final DiagnosePaciente paciente;
  final String focoAuscultacion;
  final DiagnoseResultadoIA resultadoIA;
  final String recomendacion;

  const DiagnoseResponseModel({
    required this.timestampDiagnostico,
    required this.archivoAnalizado,
    required this.paciente,
    required this.focoAuscultacion,
    required this.resultadoIA,
    required this.recomendacion,
  });

  factory DiagnoseResponseModel.fromJson(Map<String, dynamic> json) {
    return DiagnoseResponseModel(
      timestampDiagnostico: json['timestamp_diagnostico'] as String? ?? '',
      archivoAnalizado: json['archivo_analizado'] as String? ?? '',
      paciente: DiagnosePaciente.fromJson(
          json['paciente'] as Map<String, dynamic>? ?? {}),
      focoAuscultacion: json['foco_auscultacion'] as String? ?? '',
      resultadoIA: DiagnoseResultadoIA.fromJson(
          json['resultado_ia'] as Map<String, dynamic>? ?? {}),
      recomendacion: json['recomendacion'] as String? ?? '',
    );
  }
}

class DiagnosePaciente {
  final int edad;
  final String genero;
  final double pesoKg;
  final double alturaCm;

  const DiagnosePaciente({
    required this.edad,
    required this.genero,
    required this.pesoKg,
    required this.alturaCm,
  });

  factory DiagnosePaciente.fromJson(Map<String, dynamic> json) {
    return DiagnosePaciente(
      edad: json['edad'] as int? ?? 0,
      genero: json['genero'] as String? ?? '',
      pesoKg: (json['peso_kg'] as num?)?.toDouble() ?? 0.0,
      alturaCm: (json['altura_cm'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DiagnoseResultadoIA {
  final String diagnostico;
  final bool tieneValvulopatia;
  final double probabilidadAnomalia;
  final double probabilidadNormal;
  final String confianza;
  final int modeloEntrenadoCon;

  const DiagnoseResultadoIA({
    required this.diagnostico,
    required this.tieneValvulopatia,
    required this.probabilidadAnomalia,
    required this.probabilidadNormal,
    required this.confianza,
    required this.modeloEntrenadoCon,
  });

  factory DiagnoseResultadoIA.fromJson(Map<String, dynamic> json) {
    return DiagnoseResultadoIA(
      diagnostico: json['diagnostico'] as String? ?? '',
      tieneValvulopatia: json['tiene_valvulopatia'] as bool? ?? false,
      probabilidadAnomalia:
          (json['probabilidad_anomalia'] as num?)?.toDouble() ?? 0.0,
      probabilidadNormal:
          (json['probabilidad_normal'] as num?)?.toDouble() ?? 0.0,
      confianza: json['confianza'] as String? ?? '',
      modeloEntrenadoCon: json['modelo_entrenado_con'] as int? ?? 0,
    );
  }
}
