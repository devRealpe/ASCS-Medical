// lib/presentation/blocs/diagnostico/diagnostico_event.dart

import 'package:equatable/equatable.dart';

abstract class DiagnosticoEvent extends Equatable {
  const DiagnosticoEvent();

  @override
  List<Object?> get props => [];
}

class CargarDiagnosticosEvent extends DiagnosticoEvent {
  final int usuarioCreaId;

  const CargarDiagnosticosEvent({required this.usuarioCreaId});

  @override
  List<Object?> get props => [usuarioCreaId];
}

class ConfirmarValvulopatiaEvent extends DiagnosticoEvent {
  final int diagnosticoId;
  final bool valvulopatia;

  const ConfirmarValvulopatiaEvent({
    required this.diagnosticoId,
    required this.valvulopatia,
  });

  @override
  List<Object?> get props => [diagnosticoId, valvulopatia];
}
