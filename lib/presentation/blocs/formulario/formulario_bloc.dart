// lib/presentation/blocs/formulario/formulario_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/network_info.dart';
import '../../../core/services/storage_preference_service.dart';
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

  FormularioBloc({
    required this.enviarFormularioUseCase,
    required this.generarNombreArchivoUseCase,
    required this.networkInfo,
  }) : super(FormularioInitial()) {
    on<EnviarFormularioEvent>(_onEnviarFormulario);
    on<ResetFormularioEvent>(_onResetFormulario);
  }

  Future<void> _onEnviarFormulario(
    EnviarFormularioEvent event,
    Emitter<FormularioState> emit,
  ) async {
    // Determinar el modo de almacenamiento actual
    final storageMode = await StoragePreferenceService.getStorageMode();
    final isLocalMode = storageMode == StorageMode.local;

    if (isLocalMode) {
      // Modo local: no necesita verificación de conectividad
      await _enviarLocal(event, emit);
    } else {
      // Modo nube: verificar conectividad
      await _enviarNube(event, emit);
    }
  }

  Future<void> _enviarLocal(
    EnviarFormularioEvent event,
    Emitter<FormularioState> emit,
  ) async {
    emit(const FormularioEnviando(
      progress: 0.0,
      status: 'Preparando almacenamiento local...',
    ));

    // Generar nombre de archivo con UUID único verificado localmente
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
      (failure) async {
        emit(FormularioError(mensaje: failure.message));
      },
      (fileName) async {
        final edad =
            DateTime.now().difference(event.fechaNacimiento).inDays ~/ 365;

        final metadata = AudioMetadata(
          fechaNacimiento: event.fechaNacimiento,
          edad: edad,
          fechaGrabacion: DateTime.now(),
          urlAudio: '', // Se llenará con la ruta local
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
        );

        final formulario = FormularioCompleto(
          metadata: metadata,
          fileName: fileName,
        );

        final result = await enviarFormularioUseCase(
          formulario: formulario,
          audioFile: event.audioFile,
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

  Future<void> _enviarNube(
    EnviarFormularioEvent event,
    Emitter<FormularioState> emit,
  ) async {
    // 1. Verificar conectividad REAL antes de iniciar
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

    // 2. Verificar calidad de conexión
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

    // 3. Generar nombre de archivo
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
      (failure) async {
        emit(FormularioError(mensaje: failure.message));
      },
      (fileName) async {
        final edad =
            DateTime.now().difference(event.fechaNacimiento).inDays ~/ 365;

        final metadata = AudioMetadata(
          fechaNacimiento: event.fechaNacimiento,
          edad: edad,
          fechaGrabacion: DateTime.now(),
          urlAudio: '',
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
        );

        final formulario = FormularioCompleto(
          metadata: metadata,
          fileName: fileName,
        );

        final result = await enviarFormularioUseCase(
          formulario: formulario,
          audioFile: event.audioFile,
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
          (_) => emit(const FormularioEnviadoExitosamente()),
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
}
