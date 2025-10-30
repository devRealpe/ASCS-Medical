// lib/presentation/blocs/formulario/formulario_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/audio_metadata.dart';
import '../../../domain/entities/formulario_completo.dart';
import '../../../domain/usecases/enviar_formulario_usecase.dart';
import '../../../domain/usecases/generar_nombre_archivo_usecase.dart';
import 'formulario_event.dart';
import 'formulario_state.dart';

class FormularioBloc extends Bloc<FormularioEvent, FormularioState> {
  final EnviarFormularioUseCase enviarFormularioUseCase;
  final GenerarNombreArchivoUseCase generarNombreArchivoUseCase;

  FormularioBloc({
    required this.enviarFormularioUseCase,
    required this.generarNombreArchivoUseCase,
  }) : super(FormularioInitial()) {
    on<EnviarFormularioEvent>(_onEnviarFormulario);
    on<ResetFormularioEvent>(_onResetFormulario);
  }

  Future<void> _onEnviarFormulario(
    EnviarFormularioEvent event,
    Emitter<FormularioState> emit,
  ) async {
    emit(const FormularioEnviando(
      progress: 0.0,
      status: 'Generando nombre de archivo...',
    ));

    // 1. Generar nombre de archivo
    final nombreArchivoResult = await generarNombreArchivoUseCase(
      fechaNacimiento: event.fechaNacimiento,
      codigoConsultorio: event.codigoConsultorio,
      codigoHospital: event.codigoHospital,
      codigoFoco: event.codigoFoco,
      observaciones: event.observaciones,
    );

    // Verificar si hubo error en la generación del nombre
    await nombreArchivoResult.fold(
      (failure) async {
        emit(FormularioError(mensaje: failure.message));
      },
      (fileName) async {
        // 2. Calcular edad
        final edad =
            DateTime.now().difference(event.fechaNacimiento).inDays ~/ 365;

        // 3. Crear metadata (sin URL del audio por ahora, se actualizará en el repository)
        final metadata = AudioMetadata(
          fechaNacimiento: event.fechaNacimiento,
          edad: edad,
          fechaGrabacion: DateTime.now(),
          urlAudio: '', // Se actualizará después de subir el audio
          hospital: event.hospital,
          codigoHospital: event.codigoHospital,
          consultorio: event.consultorio,
          codigoConsultorio: event.codigoConsultorio,
          estado: event.estado,
          focoAuscultacion: event.focoAuscultacion,
          codigoFoco: event.codigoFoco,
          observaciones: event.observaciones,
        );

        // 4. Crear formulario completo
        final formulario = FormularioCompleto(
          metadata: metadata,
          fileName: fileName,
        );

        // 5. Enviar formulario
        final result = await enviarFormularioUseCase(
          formulario: formulario,
          audioFile: event.audioFile,
          onProgress: (progress, status) {
            emit(FormularioEnviando(
              progress: progress,
              status: status,
            ));
          },
        );

        // 6. Emitir resultado final
        result.fold(
          (failure) => emit(FormularioError(mensaje: failure.message)),
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
