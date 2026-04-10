// lib/presentation/blocs/entrenamiento/entrenamiento_event.dart

import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class EntrenamientoEvent extends Equatable {
  const EntrenamientoEvent();

  @override
  List<Object?> get props => [];
}

class EnviarEntrenamientoEvent extends EntrenamientoEvent {
  final File audioFile;
  final DateTime fechaNacimiento;
  final int edad;
  final String genero;
  final double pesoKg;
  final double alturaCm;
  final String estado;
  final String focoAuscultacion;
  final String codigoFoco;
  // Ubicación
  final String hospital;
  final String codigoHospital;
  final String consultorio;
  final String codigoConsultorio;
  // IDs numéricos para POST /api/diagnostics
  final int? institucionId;
  final int? focoId;

  /// IDs de categorías de anomalía disponibles (para asignar al guardar)
  final List<int> categoriaAnomaliaIds;

  const EnviarEntrenamientoEvent({
    required this.audioFile,
    required this.fechaNacimiento,
    required this.edad,
    required this.genero,
    required this.pesoKg,
    required this.alturaCm,
    required this.estado,
    required this.focoAuscultacion,
    required this.codigoFoco,
    required this.hospital,
    required this.codigoHospital,
    required this.consultorio,
    required this.codigoConsultorio,
    this.institucionId,
    this.focoId,
    this.categoriaAnomaliaIds = const [],
  });

  @override
  List<Object?> get props => [
        audioFile,
        fechaNacimiento,
        edad,
        genero,
        pesoKg,
        alturaCm,
        estado,
        focoAuscultacion,
        codigoFoco,
        hospital,
        codigoHospital,
        consultorio,
        codigoConsultorio,
        institucionId,
        focoId,
        categoriaAnomaliaIds,
      ];
}

class ResetEntrenamientoEvent extends EntrenamientoEvent {}
