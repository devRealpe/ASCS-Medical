// lib/data/models/audio_metadata_model.dart

import '../../domain/entities/audio_metadata.dart';

/// Modelo de datos para AudioMetadata con serialización JSON.
///
/// En modo **local** los campos `nombreAudio*` contienen el nombre del archivo
/// (ej: `SC_20240101_0101_01_N_ABCD12345678.wav`).
///
/// En modo **nube** los campos `nombreAudio*` contienen la URL pública en S3
/// (ej: `https://bucket.s3.region.amazonaws.com/public/Audios/SC_....wav`).
class AudioMetadataModel extends AudioMetadata {
  const AudioMetadataModel({
    required super.fechaNacimiento,
    required super.edad,
    required super.fechaGrabacion,
    required super.nombreAudioPrincipal,
    required super.nombreAudioEcg,
    required super.nombreAudioEcg1,
    required super.nombreAudioEcg2,
    required super.hospital,
    required super.codigoHospital,
    required super.consultorio,
    required super.codigoConsultorio,
    required super.estado,
    required super.focoAuscultacion,
    required super.codigoFoco,
    required super.genero,
    required super.pesoCkg,
    required super.alturaCm,
    super.observaciones,
    super.categoriaAnomalia,
    super.codigoCategoriaAnomalia,
  });

  // ── Deserialización ───────────────────────────────────────────────────────

  /// Crea un modelo desde JSON (soporta tanto nombres como URLs en [archivos]).
  factory AudioMetadataModel.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>;
    final archivos = json['archivos'] as Map<String, dynamic>;
    final ubicacion = json['ubicacion'] as Map<String, dynamic>;
    final diagnostico = json['diagnostico'] as Map<String, dynamic>;
    final paciente = json['paciente'] as Map<String, dynamic>;

    return AudioMetadataModel(
      fechaNacimiento: DateTime.parse(metadata['fecha_nacimiento'] as String),
      edad: metadata['edad'] as int,
      fechaGrabacion: DateTime.parse(metadata['fecha_grabacion'] as String),
      nombreAudioPrincipal: archivos['audio_principal'] as String,
      nombreAudioEcg: archivos['audio_ecg'] as String,
      nombreAudioEcg1: archivos['audio_ecg_1'] as String,
      nombreAudioEcg2: archivos['audio_ecg_2'] as String,
      hospital: ubicacion['hospital'] as String,
      codigoHospital: ubicacion['codigo_hospital'] as String,
      consultorio: ubicacion['consultorio'] as String,
      codigoConsultorio: ubicacion['codigo_consultorio'] as String,
      estado: diagnostico['estado'] as String,
      focoAuscultacion: diagnostico['foco_auscultacion'] as String,
      codigoFoco: diagnostico['codigo_foco'] as String,
      observaciones: diagnostico['observaciones'] as String?,
      categoriaAnomalia: diagnostico['categoria_anomalia'] as String?,
      codigoCategoriaAnomalia:
          diagnostico['codigo_categoria_anomalia'] as String?,
      genero: paciente['genero'] as String,
      pesoCkg: (paciente['peso_kg'] as num).toDouble(),
      alturaCm: (paciente['altura_cm'] as num).toDouble(),
    );
  }

  // ── Serialización ─────────────────────────────────────────────────────────

  /// Convierte el modelo a JSON.
  ///
  /// La sección [archivos] contendrá:
  /// - En modo **local**: nombres de archivo
  ///   (`SC_20240101_0101_01_N_ABCD12345678.wav`)
  /// - En modo **nube**: URLs públicas de S3
  ///   (`https://bucket.s3.region.amazonaws.com/public/Audios/SC_....wav`)
  Map<String, dynamic> toJson() {
    return {
      'metadata': {
        'fecha_nacimiento': fechaNacimiento.toIso8601String(),
        'edad': edad,
        'fecha_grabacion': fechaGrabacion.toIso8601String(),
      },
      'archivos': {
        'audio_principal': nombreAudioPrincipal,
        'audio_ecg': nombreAudioEcg,
        'audio_ecg_1': nombreAudioEcg1,
        'audio_ecg_2': nombreAudioEcg2,
      },
      'ubicacion': {
        'hospital': hospital,
        'codigo_hospital': codigoHospital,
        'consultorio': consultorio,
        'codigo_consultorio': codigoConsultorio,
      },
      'diagnostico': {
        'estado': estado,
        'foco_auscultacion': focoAuscultacion,
        'codigo_foco': codigoFoco,
        'observaciones': observaciones ?? 'No aplica',
        'categoria_anomalia': categoriaAnomalia,
        'codigo_categoria_anomalia': codigoCategoriaAnomalia,
      },
      'paciente': {
        'genero': genero,
        'peso_kg': pesoCkg,
        'altura_cm': alturaCm,
      },
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  AudioMetadataModel copyWith({
    DateTime? fechaNacimiento,
    int? edad,
    DateTime? fechaGrabacion,
    String? nombreAudioPrincipal,
    String? nombreAudioEcg,
    String? nombreAudioEcg1,
    String? nombreAudioEcg2,
    String? hospital,
    String? codigoHospital,
    String? consultorio,
    String? codigoConsultorio,
    String? estado,
    String? focoAuscultacion,
    String? codigoFoco,
    String? observaciones,
    String? genero,
    double? pesoCkg,
    double? alturaCm,
    String? categoriaAnomalia,
    String? codigoCategoriaAnomalia,
  }) {
    return AudioMetadataModel(
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      edad: edad ?? this.edad,
      fechaGrabacion: fechaGrabacion ?? this.fechaGrabacion,
      nombreAudioPrincipal: nombreAudioPrincipal ?? this.nombreAudioPrincipal,
      nombreAudioEcg: nombreAudioEcg ?? this.nombreAudioEcg,
      nombreAudioEcg1: nombreAudioEcg1 ?? this.nombreAudioEcg1,
      nombreAudioEcg2: nombreAudioEcg2 ?? this.nombreAudioEcg2,
      hospital: hospital ?? this.hospital,
      codigoHospital: codigoHospital ?? this.codigoHospital,
      consultorio: consultorio ?? this.consultorio,
      codigoConsultorio: codigoConsultorio ?? this.codigoConsultorio,
      estado: estado ?? this.estado,
      focoAuscultacion: focoAuscultacion ?? this.focoAuscultacion,
      codigoFoco: codigoFoco ?? this.codigoFoco,
      observaciones: observaciones ?? this.observaciones,
      genero: genero ?? this.genero,
      pesoCkg: pesoCkg ?? this.pesoCkg,
      alturaCm: alturaCm ?? this.alturaCm,
      categoriaAnomalia: categoriaAnomalia ?? this.categoriaAnomalia,
      codigoCategoriaAnomalia:
          codigoCategoriaAnomalia ?? this.codigoCategoriaAnomalia,
    );
  }
}
