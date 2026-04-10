// lib/presentation/blocs/formulario/formulario_event.dart

import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class FormularioEvent extends Equatable {
  const FormularioEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para enviar el formulario completo con un ZIP de 4 audios
class EnviarFormularioEvent extends FormularioEvent {
  final DateTime fechaNacimiento;
  final String hospital;
  final String codigoHospital;
  final String consultorio;
  final String codigoConsultorio;
  final String estado;
  final String focoAuscultacion;
  final String codigoFoco;
  final String? observaciones;

  /// Archivo ZIP que contiene los 4 sonidos cardíacos
  final File zipFile;

  // Datos del paciente
  final String genero;
  final double pesoCkg;
  final double alturaCm;
  final String? categoriaAnomalia;
  final String? codigoCategoriaAnomalia;
  final List<String> enfermedadesBase;

  // IDs numéricos para POST /api/diagnostics
  final int? focoId;
  final int? categoriaAnomaliaId;
  final List<int> enfermedadesBaseIds;

  const EnviarFormularioEvent({
    required this.fechaNacimiento,
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
    required this.zipFile,
    this.observaciones,
    this.categoriaAnomalia,
    this.codigoCategoriaAnomalia,
    this.enfermedadesBase = const [],
    this.focoId,
    this.categoriaAnomaliaId,
    this.enfermedadesBaseIds = const [],
  });

  @override
  List<Object?> get props => [
        fechaNacimiento,
        hospital,
        codigoHospital,
        consultorio,
        codigoConsultorio,
        estado,
        focoAuscultacion,
        codigoFoco,
        observaciones,
        zipFile,
        genero,
        pesoCkg,
        alturaCm,
        categoriaAnomalia,
        codigoCategoriaAnomalia,
        enfermedadesBase,
        focoId,
        categoriaAnomaliaId,
        enfermedadesBaseIds,
      ];
}

/// Evento para resetear el formulario después de envío exitoso
class ResetFormularioEvent extends FormularioEvent {}

/// Evento para enviar muestra de entrenamiento al Servicio 2
/// POST /api/v1/train/sample (multipart con 4 audios + JSON)
class EnviarMuestraEntrenamientoEvent extends FormularioEvent {
  final DateTime fechaNacimiento;
  final String hospital;
  final String codigoHospital;
  final String consultorio;
  final String codigoConsultorio;
  final String estado;
  final String focoAuscultacion;
  final String codigoFoco;
  final String? observaciones;
  final File zipFile;
  final String genero;
  final double pesoCkg;
  final double alturaCm;
  final String? categoriaAnomalia;
  final String? codigoCategoriaAnomalia;
  final List<String> enfermedadesBase;

  const EnviarMuestraEntrenamientoEvent({
    required this.fechaNacimiento,
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
    required this.zipFile,
    this.observaciones,
    this.categoriaAnomalia,
    this.codigoCategoriaAnomalia,
    this.enfermedadesBase = const [],
  });

  @override
  List<Object?> get props => [
        fechaNacimiento,
        hospital,
        codigoHospital,
        consultorio,
        codigoConsultorio,
        estado,
        focoAuscultacion,
        codigoFoco,
        observaciones,
        zipFile,
        genero,
        pesoCkg,
        alturaCm,
        categoriaAnomalia,
        codigoCategoriaAnomalia,
        enfermedadesBase,
      ];
}

/// Evento para solicitar diagnóstico IA al Servicio 3
/// POST /api/v1/diagnose (multipart con 1 audio + JSON)
/// y luego guardar el resultado via POST /api/diagnostics
class DiagnosticarAudioEvent extends FormularioEvent {
  final DateTime fechaNacimiento;
  final String hospital;
  final String codigoHospital;
  final String consultorio;
  final String codigoConsultorio;
  final String focoAuscultacion;
  final String codigoFoco;
  final String? observaciones;
  final File zipFile;
  final String genero;
  final double pesoCkg;
  final double alturaCm;
  final String? categoriaAnomalia;
  final String? codigoCategoriaAnomalia;
  final List<String> enfermedadesBase;

  // IDs numéricos para POST /api/diagnostics
  final int? institucionId;
  final int? focoId;
  final int? categoriaAnomaliaId;
  final List<int> enfermedadesBaseIds;

  const DiagnosticarAudioEvent({
    required this.fechaNacimiento,
    required this.hospital,
    required this.codigoHospital,
    required this.consultorio,
    required this.codigoConsultorio,
    required this.focoAuscultacion,
    required this.codigoFoco,
    required this.genero,
    required this.pesoCkg,
    required this.alturaCm,
    required this.zipFile,
    this.observaciones,
    this.categoriaAnomalia,
    this.codigoCategoriaAnomalia,
    this.enfermedadesBase = const [],
    this.institucionId,
    this.focoId,
    this.categoriaAnomaliaId,
    this.enfermedadesBaseIds = const [],
  });

  @override
  List<Object?> get props => [
        fechaNacimiento,
        hospital,
        codigoHospital,
        consultorio,
        codigoConsultorio,
        focoAuscultacion,
        codigoFoco,
        observaciones,
        zipFile,
        genero,
        pesoCkg,
        alturaCm,
        categoriaAnomalia,
        codigoCategoriaAnomalia,
        enfermedadesBase,
        institucionId,
        focoId,
        categoriaAnomaliaId,
        enfermedadesBaseIds,
      ];
}
