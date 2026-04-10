// lib/presentation/blocs/diagnostico/diagnostico_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/exceptions.dart';
import '../../../data/datasources/remote/diagnostico_remote_datasource.dart';
import '../../../data/models/diagnostico/diagnostico_model.dart';
import 'diagnostico_event.dart';
import 'diagnostico_state.dart';

class DiagnosticoBloc extends Bloc<DiagnosticoEvent, DiagnosticoState> {
  final DiagnosticoRemoteDataSource dataSource;

  DiagnosticoBloc({required this.dataSource}) : super(DiagnosticoInitial()) {
    on<CargarDiagnosticosEvent>(_onCargar);
    on<ConfirmarValvulopatiaEvent>(_onConfirmarValvulopatia);
  }

  Future<void> _onCargar(
    CargarDiagnosticosEvent event,
    Emitter<DiagnosticoState> emit,
  ) async {
    emit(DiagnosticoLoading());
    try {
      final grupos = await dataSource.obtenerPorCreador(event.usuarioCreaId);
      emit(DiagnosticoLoaded(grupos: grupos));
    } on NetworkException catch (e) {
      emit(
          DiagnosticoError('Sin conexión al servidor.\nDetalle: ${e.message}'));
    } on ServerException catch (e) {
      emit(DiagnosticoError(e.message));
    } catch (e) {
      emit(DiagnosticoError('Error inesperado: $e'));
    }
  }

  Future<void> _onConfirmarValvulopatia(
    ConfirmarValvulopatiaEvent event,
    Emitter<DiagnosticoState> emit,
  ) async {
    // Guardar la lista actual para actualizar en sitio
    final currentGroups = _currentGroups;

    try {
      await dataSource.confirmarValvulopatia(
        diagnosticoId: event.diagnosticoId,
        valvulopatia: event.valvulopatia,
      );

      // Actualizar la lista local
      final updatedGroups = currentGroups.map((group) {
        final updatedDiagnosticos = group.diagnosticos.map((d) {
          if (d.id == event.diagnosticoId) {
            return d.copyWith(
              verificado: true,
              valvulopatia: event.valvulopatia,
            );
          }
          return d;
        }).toList();
        return DiagnosticoGrupoModel(
          usuarioCreadorId: group.usuarioCreadorId,
          nombreUsuario: group.nombreUsuario,
          totalDiagnosticos: group.totalDiagnosticos,
          diagnosticos: updatedDiagnosticos,
        );
      }).toList();

      emit(ValvulopatiaConfirmada(
        diagnosticoId: event.diagnosticoId,
        valvulopatia: event.valvulopatia,
        grupos: updatedGroups,
      ));
    } on NetworkException catch (e) {
      emit(
          DiagnosticoError('Sin conexión al servidor.\nDetalle: ${e.message}'));
    } on ServerException catch (e) {
      emit(DiagnosticoError(e.message));
    } catch (e) {
      emit(DiagnosticoError('Error inesperado: $e'));
    }
  }

  List<DiagnosticoGrupoModel> get _currentGroups {
    final s = state;
    if (s is DiagnosticoLoaded) return s.grupos;
    if (s is ValvulopatiaConfirmada) return s.grupos;
    return [];
  }
}
