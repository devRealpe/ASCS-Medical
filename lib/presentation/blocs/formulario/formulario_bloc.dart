// lib/presentation/blocs/formulario/formulario_bloc.dart

import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/network_info.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/storage_preference_service.dart';
import '../../../data/datasources/local/local_storage_datasource.dart';
import '../../../data/datasources/remote/diagnose_remote_datasource.dart';
import '../../../data/datasources/remote/diagnostico_remote_datasource.dart';
import '../../../data/datasources/remote/sample_train_remote_datasource.dart';
import '../../../domain/entities/audio_metadata.dart';
import '../../../domain/entities/formulario_completo.dart';
import '../../../domain/usecases/enviar_formulario_usecase.dart';
import '../../../domain/usecases/generar_nombre_archivo_usecase.dart';
import 'formulario_event.dart';
import 'formulario_state.dart';

class FormularioBloc extends Bloc<FormularioEvent, FormularioState> {
  final EnviarFormularioUseCase enviarFormularioUseCase;
  final GenerarNombreArchivoUseCase generarNombreArchivoUseCase;
  final NetworkInfo networkInfo;
  final LocalStorageDataSource localStorageDataSource;
  final SampleTrainRemoteDataSource sampleTrainRemoteDataSource;
  final DiagnoseRemoteDataSource diagnoseRemoteDataSource;
  final DiagnosticoRemoteDataSource diagnosticoRemoteDataSource;

  FormularioBloc({
    required this.enviarFormularioUseCase,
    required this.generarNombreArchivoUseCase,
    required this.networkInfo,
    required this.localStorageDataSource,
    required this.sampleTrainRemoteDataSource,
    required this.diagnoseRemoteDataSource,
    required this.diagnosticoRemoteDataSource,
  }) : super(FormularioInitial()) {
    on<EnviarFormularioEvent>(_onEnviarFormulario);
    on<ResetFormularioEvent>(_onResetFormulario);
    on<EnviarMuestraEntrenamientoEvent>(_onEnviarMuestraEntrenamiento);
    on<DiagnosticarAudioEvent>(_onDiagnosticarAudio);
  }

  Future<void> _onEnviarFormulario(
    EnviarFormularioEvent event,
    Emitter<FormularioState> emit,
  ) async {
    final storageMode = await StoragePreferenceService.getStorageMode();

    switch (storageMode) {
      case StorageMode.local:
        await _enviarLocal(event, emit);
        break;
      case StorageMode.cloud:
        await _enviarNube(event, emit);
        break;
      case StorageMode.training:
        await _enviarEntrenamiento(event, emit);
        break;
    }
  }

  // ── Modo LOCAL ────────────────────────────────────────────────────────────

  Future<void> _enviarLocal(
    EnviarFormularioEvent event,
    Emitter<FormularioState> emit,
  ) async {
    emit(const FormularioEnviando(
      progress: 0.0,
      status: 'Preparando almacenamiento local...',
    ));

    emit(const FormularioEnviando(
      progress: 0.03,
      status: 'Generando identificador único...',
    ));

    final nombreArchivoResult = await generarNombreArchivoUseCase(
      fechaNacimiento: event.fechaNacimiento,
      codigoConsultorio: event.codigoConsultorio,
      codigoHospital: event.codigoHospital,
      codigoFoco: event.codigoFoco,
      estado: event.estado,
      observaciones: event.observaciones,
    );

    await nombreArchivoResult.fold(
      (failure) async => emit(FormularioError(mensaje: failure.message)),
      (fileName) async {
        final edad =
            DateTime.now().difference(event.fechaNacimiento).inDays ~/ 365;

        // Los nombres reales de los 4 archivos se asignan dentro del repositorio
        // después de guardar; aquí usamos el baseFileName como placeholder.
        final baseFileName = fileName.replaceAll('.wav', '');
        final metadata = AudioMetadata(
          fechaNacimiento: event.fechaNacimiento,
          edad: edad,
          fechaGrabacion: DateTime.now(),
          // Placeholders: el repositorio los reemplaza al guardar
          nombreAudioPrincipal: '$baseFileName.wav',
          nombreAudioEcg: '${baseFileName}_ECG.wav',
          nombreAudioEcg1: '${baseFileName}_ECG_1.wav',
          nombreAudioEcg2: '${baseFileName}_ECG_2.wav',
          hospital: event.hospital,
          codigoHospital: event.codigoHospital,
          consultorio: event.consultorio,
          codigoConsultorio: event.codigoConsultorio,
          estado: event.estado,
          focoAuscultacion: event.focoAuscultacion,
          codigoFoco: event.codigoFoco,
          observaciones: event.observaciones,
          genero: event.genero,
          pesoCkg: event.pesoCkg,
          alturaCm: event.alturaCm,
          categoriaAnomalia: event.categoriaAnomalia,
          codigoCategoriaAnomalia: event.codigoCategoriaAnomalia,
          enfermedadesBase: event.enfermedadesBase,
        );

        final formulario = FormularioCompleto(
          metadata: metadata,
          fileName: fileName,
        );

        final result = await enviarFormularioUseCase(
          formulario: formulario,
          zipFile: event.zipFile,
          onProgress: (progress, status) {
            emit(FormularioEnviando(
              progress: 0.05 + (progress * 0.95),
              status: status,
            ));
          },
        );

        result.fold(
          (failure) => emit(FormularioError(mensaje: failure.message)),
          (_) => emit(const FormularioEnviadoExitosamente(
            mensaje: 'Datos guardados localmente con éxito',
          )),
        );
      },
    );
  }

  // ── Modo NUBE ─────────────────────────────────────────────────────────────

  Future<void> _enviarNube(
    EnviarFormularioEvent event,
    Emitter<FormularioState> emit,
  ) async {
    emit(const FormularioEnviando(
      progress: 0.0,
      status: 'Verificando conexión a Internet...',
    ));

    final hasConnection = await networkInfo.isConnected;

    if (!hasConnection) {
      emit(const FormularioError(
        mensaje: 'No hay conexión a Internet. Por favor, verifica:\n'
            '• Que estés conectado a WiFi o datos móviles\n'
            '• Que tu conexión tenga acceso a Internet\n'
            '• Que no estés en modo avión',
      ));
      return;
    }

    final quality = await networkInfo.connectionQuality;

    if (quality == ConnectionQuality.veryPoor) {
      emit(const FormularioEnviando(
        progress: 0.0,
        status:
            'Conexión detectada pero es muy lenta. Esto puede tomar tiempo...',
      ));
      await Future.delayed(const Duration(seconds: 2));
    } else if (quality == ConnectionQuality.poor) {
      emit(const FormularioEnviando(
        progress: 0.0,
        status: 'Conexión lenta detectada. Ten paciencia...',
      ));
      await Future.delayed(const Duration(seconds: 1));
    }

    emit(const FormularioEnviando(
      progress: 0.05,
      status: 'Generando identificador único...',
    ));

    final nombreArchivoResult = await generarNombreArchivoUseCase(
      fechaNacimiento: event.fechaNacimiento,
      codigoConsultorio: event.codigoConsultorio,
      codigoHospital: event.codigoHospital,
      codigoFoco: event.codigoFoco,
      estado: event.estado,
      observaciones: event.observaciones,
    );

    await nombreArchivoResult.fold(
      (failure) async => emit(FormularioError(mensaje: failure.message)),
      (fileName) async {
        final edad =
            DateTime.now().difference(event.fechaNacimiento).inDays ~/ 365;

        final baseFileName = fileName.replaceAll('.wav', '');
        final metadata = AudioMetadata(
          fechaNacimiento: event.fechaNacimiento,
          edad: edad,
          fechaGrabacion: DateTime.now(),
          nombreAudioPrincipal: '$baseFileName.wav',
          nombreAudioEcg: '${baseFileName}_ECG.wav',
          nombreAudioEcg1: '${baseFileName}_ECG_1.wav',
          nombreAudioEcg2: '${baseFileName}_ECG_2.wav',
          hospital: event.hospital,
          codigoHospital: event.codigoHospital,
          consultorio: event.consultorio,
          codigoConsultorio: event.codigoConsultorio,
          estado: event.estado,
          focoAuscultacion: event.focoAuscultacion,
          codigoFoco: event.codigoFoco,
          observaciones: event.observaciones,
          genero: event.genero,
          pesoCkg: event.pesoCkg,
          alturaCm: event.alturaCm,
          categoriaAnomalia: event.categoriaAnomalia,
          codigoCategoriaAnomalia: event.codigoCategoriaAnomalia,
          enfermedadesBase: event.enfermedadesBase,
        );

        final formulario = FormularioCompleto(
          metadata: metadata,
          fileName: fileName,
        );

        final result = await enviarFormularioUseCase(
          formulario: formulario,
          zipFile: event.zipFile,
          onProgress: (progress, status) {
            emit(FormularioEnviando(
              progress: 0.05 + (progress * 0.95),
              status: status,
            ));
          },
        );

        result.fold(
          (failure) {
            String errorMessage = failure.message;

            if (failure.message.toLowerCase().contains('conexión') ||
                failure.message.toLowerCase().contains('network')) {
              errorMessage = 'Error de conexión:\n${failure.message}\n\n'
                  'Sugerencias:\n'
                  '• Verifica tu conexión a Internet\n'
                  '• Intenta acercarte a tu router WiFi\n'
                  '• Si usas datos móviles, verifica tu señal';
            } else if (failure.message.toLowerCase().contains('tiempo')) {
              errorMessage =
                  'La operación tomó demasiado tiempo:\n${failure.message}\n\n'
                  'Tu conexión puede ser muy lenta. Intenta:\n'
                  '• Conectarte a una red WiFi más rápida\n'
                  '• Verificar que no haya otras descargas activas\n'
                  '• Intentar nuevamente más tarde';
            }

            emit(FormularioError(mensaje: errorMessage));
          },
          (_) => emit(const FormularioEnviadoExitosamente(
            mensaje: 'Datos enviados a la nube exitosamente',
          )),
        );
      },
    );
  }

  void _onResetFormulario(
    ResetFormularioEvent event,
    Emitter<FormularioState> emit,
  ) {
    emit(FormularioInitial());
  }

  // ── Modo ENTRENAMIENTO (Servicio 2) — via StorageMode ─────────────────────

  Future<void> _enviarEntrenamiento(
    EnviarFormularioEvent event,
    Emitter<FormularioState> emit,
  ) async {
    emit(const FormularioEnviando(
      progress: 0.0,
      status: 'Verificando conexión a Internet...',
    ));

    final hasConnection = await networkInfo.isConnected;
    if (!hasConnection) {
      emit(const FormularioError(
        mensaje: 'No hay conexión a Internet. Por favor, verifica:\n'
            '• Que estés conectado a WiFi o datos móviles\n'
            '• Que tu conexión tenga acceso a Internet\n'
            '• Que no estés en modo avión',
      ));
      return;
    }

    emit(const FormularioEnviando(
      progress: 0.05,
      status: 'Extrayendo archivos de audio del ZIP...',
    ));

    late ZipAudioFiles audios;
    try {
      audios = await localStorageDataSource.extraerAudiosDeZip(event.zipFile);
    } catch (e) {
      emit(FormularioError(mensaje: 'Error al extraer audios del ZIP: $e'));
      return;
    }

    emit(const FormularioEnviando(
      progress: 0.15,
      status: 'Preparando metadatos...',
    ));

    final edad = DateTime.now().difference(event.fechaNacimiento).inDays ~/ 365;

    final metadataJson = {
      'metadata': {
        'fecha_nacimiento': event.fechaNacimiento.toIso8601String(),
        'edad': edad,
        'fecha_grabacion': DateTime.now().toIso8601String(),
      },
      'ubicacion': {
        'hospital': event.hospital,
        'codigo_hospital': event.codigoHospital,
        'consultorio': event.consultorio,
        'codigo_consultorio': event.codigoConsultorio,
      },
      'diagnostico': {
        'estado': event.estado,
        'foco_auscultacion': event.focoAuscultacion,
        'codigo_foco': event.codigoFoco,
        'observaciones': event.observaciones ?? 'No aplica',
        'categoria_anomalia': event.categoriaAnomalia,
        'codigo_categoria_anomalia': event.codigoCategoriaAnomalia,
      },
      'paciente': {
        'genero': event.genero,
        'peso_kg': event.pesoCkg,
        'altura_cm': event.alturaCm,
        'enfermedades_base': event.enfermedadesBase,
      },
    };

    try {
      await sampleTrainRemoteDataSource.enviarMuestra(
        audios: audios,
        metadataJson: metadataJson,
        onStatus: (status) {
          emit(FormularioEnviando(
            progress: 0.20,
            status: status,
          ));
        },
      );

      emit(const FormularioEnviadoExitosamente(
        mensaje: 'Muestra de entrenamiento enviada exitosamente',
      ));
    } catch (e) {
      emit(FormularioError(
        mensaje: 'Error al enviar muestra de entrenamiento:\n$e',
      ));
    }
  }

  // ── Modo ENTRENAMIENTO (Servicio 2) — via evento directo ──────────────────

  Future<void> _onEnviarMuestraEntrenamiento(
    EnviarMuestraEntrenamientoEvent event,
    Emitter<FormularioState> emit,
  ) async {
    emit(const FormularioEnviando(
      progress: 0.0,
      status: 'Verificando conexión a Internet...',
    ));

    final hasConnection = await networkInfo.isConnected;
    if (!hasConnection) {
      emit(const FormularioError(
        mensaje: 'No hay conexión a Internet. Verifica tu red.',
      ));
      return;
    }

    emit(const FormularioEnviando(
      progress: 0.05,
      status: 'Extrayendo archivos de audio del ZIP...',
    ));

    late ZipAudioFiles audios;
    try {
      audios = await localStorageDataSource.extraerAudiosDeZip(event.zipFile);
    } catch (e) {
      emit(FormularioError(mensaje: 'Error al extraer audios del ZIP: $e'));
      return;
    }

    emit(const FormularioEnviando(
      progress: 0.15,
      status: 'Preparando metadatos...',
    ));

    final edad = DateTime.now().difference(event.fechaNacimiento).inDays ~/ 365;

    final metadataJson = {
      'metadata': {
        'fecha_nacimiento': event.fechaNacimiento.toIso8601String(),
        'edad': edad,
        'fecha_grabacion': DateTime.now().toIso8601String(),
      },
      'ubicacion': {
        'hospital': event.hospital,
        'codigo_hospital': event.codigoHospital,
        'consultorio': event.consultorio,
        'codigo_consultorio': event.codigoConsultorio,
      },
      'diagnostico': {
        'estado': event.estado,
        'foco_auscultacion': event.focoAuscultacion,
        'codigo_foco': event.codigoFoco,
        'observaciones': event.observaciones ?? 'No aplica',
        'categoria_anomalia': event.categoriaAnomalia,
        'codigo_categoria_anomalia': event.codigoCategoriaAnomalia,
      },
      'paciente': {
        'genero': event.genero,
        'peso_kg': event.pesoCkg,
        'altura_cm': event.alturaCm,
        'enfermedades_base': event.enfermedadesBase,
      },
    };

    try {
      await sampleTrainRemoteDataSource.enviarMuestra(
        audios: audios,
        metadataJson: metadataJson,
        onStatus: (status) {
          emit(FormularioEnviando(
            progress: 0.20,
            status: status,
          ));
        },
      );

      emit(const FormularioEnviadoExitosamente(
        mensaje: 'Muestra de entrenamiento enviada exitosamente',
      ));
    } catch (e) {
      emit(FormularioError(
        mensaje: 'Error al enviar muestra de entrenamiento:\n$e',
      ));
    }
  }

  // ── Modo DIAGNÓSTICO IA (Servicio 3) ──────────────────────────────────────

  Future<void> _onDiagnosticarAudio(
    DiagnosticarAudioEvent event,
    Emitter<FormularioState> emit,
  ) async {
    developer.log('══ [BLOC] _onDiagnosticarAudio INICIADO ══',
        name: 'DIAGNOSE');
    developer.log('ZIP path: ${event.zipFile.path}', name: 'DIAGNOSE');
    developer.log('ZIP existe: ${event.zipFile.existsSync()}',
        name: 'DIAGNOSE');

    emit(const FormularioEnviando(
      progress: 0.0,
      status: 'Verificando conexión a Internet...',
    ));

    final hasConnection = await networkInfo.isConnected;
    if (!hasConnection) {
      emit(const FormularioError(
        mensaje: 'No hay conexión a Internet. Verifica tu red.',
      ));
      return;
    }

    emit(const FormularioEnviando(
      progress: 0.05,
      status: 'Extrayendo audio principal del ZIP...',
    ));

    late ZipAudioFiles audios;
    try {
      audios = await localStorageDataSource.extraerAudiosDeZip(event.zipFile);
      developer.log('Audio principal: ${audios.principal.path}',
          name: 'DIAGNOSE');
      developer.log('Audio existe: ${audios.principal.existsSync()}',
          name: 'DIAGNOSE');
      developer.log(
          'Audio tamaño: ${audios.principal.existsSync() ? audios.principal.lengthSync() : 0} bytes',
          name: 'DIAGNOSE');
    } catch (e) {
      developer.log('ERROR extraer audios: $e', name: 'DIAGNOSE');
      emit(FormularioError(mensaje: 'Error al extraer audios del ZIP: $e'));
      return;
    }

    emit(const FormularioEnviando(
      progress: 0.15,
      status: 'Preparando metadatos para diagnóstico...',
    ));

    final edad = DateTime.now().difference(event.fechaNacimiento).inDays ~/ 365;

    final metadataJson = {
      'metadata': {
        'fecha_nacimiento': event.fechaNacimiento.toIso8601String(),
        'edad': edad,
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
        'observaciones': event.observaciones ?? 'No aplica',
        'categoria_anomalia': event.categoriaAnomalia,
        'codigo_categoria_anomalia': event.codigoCategoriaAnomalia,
      },
      'paciente': {
        'genero': event.genero,
        'peso_kg': event.pesoCkg,
        'altura_cm': event.alturaCm,
        'enfermedades_base': event.enfermedadesBase,
      },
    };

    developer.log('Metadata JSON preparado', name: 'DIAGNOSE');

    emit(const FormularioEnviando(
      progress: 0.25,
      status: 'Enviando audio al servicio de diagnóstico IA...',
    ));

    try {
      final resultado = await diagnoseRemoteDataSource.diagnosticar(
        audioFile: audios.principal,
        metadataJson: metadataJson,
      );

      developer.log('Respuesta IA recibida:', name: 'DIAGNOSE');
      developer.log('  diagnostico: ${resultado.resultadoIA.diagnostico}',
          name: 'DIAGNOSE');
      developer.log(
          '  tieneValvulopatia: ${resultado.resultadoIA.tieneValvulopatia}',
          name: 'DIAGNOSE');
      developer.log('  confianza: ${resultado.resultadoIA.confianza}',
          name: 'DIAGNOSE');
      developer.log('  paciente.edad: ${resultado.paciente.edad}',
          name: 'DIAGNOSE');
      developer.log('  focoAuscultacion: ${resultado.focoAuscultacion}',
          name: 'DIAGNOSE');

      // ── Guardar diagnóstico: POST /api/diagnostics ────────────────────
      emit(const FormularioEnviando(
        progress: 0.80,
        status: 'Guardando diagnóstico en el servidor...',
      ));

      final usuarioId = SessionService.instance.usuario?.id;
      final esNormal =
          resultado.resultadoIA.diagnostico.toLowerCase() == 'normal';

      if (usuarioId != null && event.focoId != null) {
        try {
          await diagnosticoRemoteDataSource.crearDiagnostico(
            institucionId: event.institucionId!,
            esNormal: esNormal,
            edad: resultado.paciente.edad,
            genero: resultado.paciente.genero,
            altura: resultado.paciente.alturaCm / 100.0,
            peso: resultado.paciente.pesoKg,
            diagnosticoTexto: resultado.resultadoIA.diagnostico,
            focoId: event.focoId!,
            categoriaAnomaliaId: event.categoriaAnomaliaId,
            usuarioCreaId: usuarioId,
            valvulopatia: resultado.resultadoIA.tieneValvulopatia,
            enfermedadesBaseIds: event.enfermedadesBaseIds,
          );
        } catch (_) {
          // Si falla guardar el diagnóstico, aún mostramos el resultado IA
        }
      }

      emit(DiagnosticoIARecibido(resultado: resultado));
    } catch (e) {
      emit(FormularioError(
        mensaje: 'Error al obtener diagnóstico IA:\n$e',
      ));
    }
  }
}
