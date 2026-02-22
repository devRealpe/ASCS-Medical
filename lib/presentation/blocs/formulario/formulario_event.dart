// lib/presentation/blocs/formulario/formulario_event.dart

import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class FormularioEvent extends Equatable {
  const FormularioEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para enviar el formulario completo
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
  final File audioFile;

  // Nuevos campos
  final String genero;
  final double pesoCkg;
  final double alturaCm;
  final String? categoriaAnomalia;
  final String? codigoCategoriaAnomalia;

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
    this.observaciones,
    this.categoriaAnomalia,
    this.codigoCategoriaAnomalia,
    required this.audioFile,
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
        audioFile,
        genero,
        pesoCkg,
        alturaCm,
        categoriaAnomalia,
        codigoCategoriaAnomalia,
      ];
}

/// Evento para resetear el formulario después de envío exitoso
class ResetFormularioEvent extends FormularioEvent {}
