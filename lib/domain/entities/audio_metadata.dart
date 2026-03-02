import 'package:equatable/equatable.dart';

/// Entidad que representa los metadatos de un audio cardíaco
class AudioMetadata extends Equatable {
  // Información temporal
  final DateTime fechaNacimiento;
  final int edad;
  final DateTime fechaGrabacion;

  // Nombres de los 4 archivos de audio (sin extensión .wav)
  // Se completan después de guardar/subir cada uno
  final String nombreAudioPrincipal; // carpeta Audios/ (sin sufijo)
  final String nombreAudioEcg; // carpeta ECG/    (sufijo _ECG)
  final String nombreAudioEcg1; // carpeta ECG_1/  (sufijo _ECG_1)
  final String nombreAudioEcg2; // carpeta ECG_2/  (sufijo _ECG_2)

  // Información de ubicación
  final String hospital;
  final String codigoHospital;
  final String consultorio;
  final String codigoConsultorio;

  // Información médica
  final String estado;
  final String focoAuscultacion;
  final String codigoFoco;
  final String? observaciones;

  // Datos del paciente
  final String genero; // 'M' o 'F'
  final double pesoCkg;
  final double alturaCm;
  final String? categoriaAnomalia;
  final String? codigoCategoriaAnomalia;

  const AudioMetadata({
    required this.fechaNacimiento,
    required this.edad,
    required this.fechaGrabacion,
    required this.nombreAudioPrincipal,
    required this.nombreAudioEcg,
    required this.nombreAudioEcg1,
    required this.nombreAudioEcg2,
    required this.hospital,
    required this.codigoHospital,
    required this.consultorio,
    required this.codigoConsultorio,
    required this.estado,
    required this.focoAuscultacion,
    required this.codigoFoco,
    required this.genero,
    required this.pesoCkg,
    required this.alturaCm,
    this.observaciones,
    this.categoriaAnomalia,
    this.codigoCategoriaAnomalia,
  });

  @override
  List<Object?> get props => [
        fechaNacimiento,
        edad,
        fechaGrabacion,
        nombreAudioPrincipal,
        nombreAudioEcg,
        nombreAudioEcg1,
        nombreAudioEcg2,
        hospital,
        codigoHospital,
        consultorio,
        codigoConsultorio,
        estado,
        focoAuscultacion,
        codigoFoco,
        observaciones,
        genero,
        pesoCkg,
        alturaCm,
        categoriaAnomalia,
        codigoCategoriaAnomalia,
      ];
}
