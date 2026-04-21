// lib/presentation/blocs/entrenamiento/entrenamiento_bloc.dart

import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/user_friendly_error_mapper.dart';
import '../../../core/services/session_service.dart';
import '../../../data/datasources/remote/diagnose_remote_datasource.dart';
import '../../../data/datasources/remote/diagnostico_remote_datasource.dart';
import 'entrenamiento_event.dart';
import 'entrenamiento_state.dart';

class EntrenamientoBloc extends Bloc<EntrenamientoEvent, EntrenamientoState> {
  final DiagnoseRemoteDataSource diagnoseDataSource;
  final DiagnosticoRemoteDataSource diagnosticoDataSource;

  EntrenamientoBloc({
    required this.diagnoseDataSource,
    required this.diagnosticoDataSource,
  }) : super(EntrenamientoInitial()) {
    on<EnviarEntrenamientoEvent>(_onEnviar);
    on<ResetEntrenamientoEvent>(_onReset);
  }

  Future<void> _onEnviar(
    EnviarEntrenamientoEvent event,
    Emitter<EntrenamientoState> emit,
  ) async {
    emit(const EntrenamientoEnviando(
      status: 'Preparando datos para envío...',
    ));

    // Construir el JSON de metadata según la estructura de /api/v1/diagnose
    final metadataJson = {
      'metadata': {
        'fecha_nacimiento':
            '${event.fechaNacimiento.toIso8601String().split('T')[0]}T00:00:00.000',
        'edad': event.edad,
        'fecha_grabacion': DateTime.now().toIso8601String(),
      },
      'ubicacion': {
        'hospital': event.hospital,
        'codigo_hospital': event.codigoHospital,
        'consultorio': event.consultorio,
        'codigo_consultorio': event.codigoConsultorio,
      },
      'diagnostico': {
        'foco_auscultacion': event.focoAuscultacion,
        'codigo_foco': event.codigoFoco,
        'observaciones': 'Sin observaciones',
        'categoria_anomalia': null,
        'codigo_categoria_anomalia': null,
      },
      'paciente': {
        'genero': event.genero,
        'peso_kg': event.pesoKg,
        'altura_cm': event.alturaCm,
        'enfermedades_base': [],
      },
    };

    emit(const EntrenamientoEnviando(
      status: 'Enviando audio al servicio de diagnóstico IA...',
    ));

    try {
      final response = await diagnoseDataSource.diagnosticar(
        audioFile: event.audioFile,
        metadataJson: metadataJson,
      );

      // ── Guardar diagnóstico: POST /api/diagnostics ────────────────────
      emit(const EntrenamientoEnviando(
        status: 'Guardando diagnóstico en el servidor...',
      ));

      final usuarioId = SessionService.instance.usuario?.id;
      final esNormal = response.esNormal;

      bool guardado = false;

      developer.log('── POST /api/diagnostics ──', name: 'ENTRENAMIENTO');
      developer.log('  usuarioId: $usuarioId', name: 'ENTRENAMIENTO');
      developer.log('  focoId: ${event.focoId}', name: 'ENTRENAMIENTO');
      developer.log('  institucionId: ${event.institucionId}',
          name: 'ENTRENAMIENTO');

      if (usuarioId != null &&
          event.focoId != null &&
          event.institucionId != null) {
        try {
          developer.log('  genero: ${event.genero}', name: 'ENTRENAMIENTO');
          developer.log('  altura: ${event.alturaCm} cm',
              name: 'ENTRENAMIENTO');
          developer.log('  esNormal: $esNormal, estado: ${response.estado}',
              name: 'ENTRENAMIENTO');
          developer.log('  peso: ${event.pesoKg}, edad: ${event.edad}',
              name: 'ENTRENAMIENTO');

          // Seleccionar categoría de anomalía: la primera disponible si no es normal
          final int? catAnomaliaId = event.categoriaAnomaliaIds.isNotEmpty
              ? event.categoriaAnomaliaIds.first
              : null;

          await diagnosticoDataSource.crearDiagnostico(
            institucionId: event.institucionId!,
            esNormal: esNormal,
            edad: event.edad,
            genero: event.genero,
            altura: event.alturaCm / 100.0,
            peso: event.pesoKg,
            precision: response.precision,
            diagnosticoTexto: response.estado,
            focoId: event.focoId!,
            categoriaAnomaliaId: catAnomaliaId,
            usuarioCreaId: usuarioId,
            valvulopatia: !esNormal,
          );
          guardado = true;
          developer.log('  ✓ Diagnóstico guardado exitosamente',
              name: 'ENTRENAMIENTO');
        } catch (e, stack) {
          developer.log('  ✗ Error al guardar diagnóstico: $e',
              name: 'ENTRENAMIENTO');
          developer.log('  Stack: $stack', name: 'ENTRENAMIENTO');
        }
      } else {
        developer.log(
            '  ✗ No se guardó: faltan datos (usuario=$usuarioId, foco=${event.focoId}, institucion=${event.institucionId})',
            name: 'ENTRENAMIENTO');
      }

      emit(EntrenamientoExitoso(
        response: response,
        guardadoEnServidor: guardado,
      ));
    } on FileException catch (e) {
      emit(EntrenamientoError(
        mensaje: UserFriendlyErrorMapper.fromError(e),
      ));
    } on NetworkException catch (e) {
      emit(EntrenamientoError(
        mensaje: UserFriendlyErrorMapper.fromError(e),
      ));
    } on ServerException catch (e) {
      emit(EntrenamientoError(
        mensaje: UserFriendlyErrorMapper.fromError(e),
      ));
    } catch (e) {
      developer.log('Error inesperado entrenamiento: $e',
          name: 'ENTRENAMIENTO');
      emit(const EntrenamientoError(
        mensaje: UserFriendlyErrorMapper.unexpectedErrorMessage,
      ));
    }
  }

  void _onReset(
    ResetEntrenamientoEvent event,
    Emitter<EntrenamientoState> emit,
  ) {
    emit(EntrenamientoInitial());
  }
}
