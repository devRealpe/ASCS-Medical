// lib/presentation/blocs/entrenamiento/entrenamiento_state.dart

import 'package:equatable/equatable.dart';
import '../../../data/models/diagnostico/diagnose_response_model.dart';

abstract class EntrenamientoState extends Equatable {
  const EntrenamientoState();

  @override
  List<Object?> get props => [];
}

class EntrenamientoInitial extends EntrenamientoState {}

class EntrenamientoEnviando extends EntrenamientoState {
  final String status;

  const EntrenamientoEnviando({required this.status});

  @override
  List<Object?> get props => [status];
}

class EntrenamientoExitoso extends EntrenamientoState {
  final DiagnoseResponseModel response;
  final bool guardadoEnServidor;

  const EntrenamientoExitoso({
    required this.response,
    this.guardadoEnServidor = false,
  });

  @override
  List<Object?> get props => [response, guardadoEnServidor];
}

class EntrenamientoError extends EntrenamientoState {
  final String mensaje;

  const EntrenamientoError({required this.mensaje});

  @override
  List<Object?> get props => [mensaje];
}
