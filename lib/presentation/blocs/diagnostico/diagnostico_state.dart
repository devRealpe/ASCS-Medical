// lib/presentation/blocs/diagnostico/diagnostico_state.dart

import 'package:equatable/equatable.dart';
import '../../../data/models/diagnostico/diagnostico_model.dart';

abstract class DiagnosticoState extends Equatable {
  const DiagnosticoState();

  @override
  List<Object?> get props => [];
}

class DiagnosticoInitial extends DiagnosticoState {}

class DiagnosticoLoading extends DiagnosticoState {}

class DiagnosticoLoaded extends DiagnosticoState {
  final List<DiagnosticoGrupoModel> grupos;

  const DiagnosticoLoaded({required this.grupos});

  @override
  List<Object?> get props => [grupos];
}

class DiagnosticoError extends DiagnosticoState {
  final String mensaje;
  const DiagnosticoError(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}

class ValvulopatiaConfirmada extends DiagnosticoState {
  final int diagnosticoId;
  final bool valvulopatia;
  final List<DiagnosticoGrupoModel> grupos;

  const ValvulopatiaConfirmada({
    required this.diagnosticoId,
    required this.valvulopatia,
    required this.grupos,
  });

  @override
  List<Object?> get props => [diagnosticoId, valvulopatia, grupos];
}
