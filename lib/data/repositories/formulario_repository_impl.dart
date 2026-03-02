// lib/data/repositories/formulario_repository_impl.dart
import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/services/storage_preference_service.dart';
import '../../domain/entities/formulario_completo.dart';
import '../../domain/repositories/formulario_repository.dart';
import '../datasources/local/local_storage_datasource.dart';
import '../datasources/remote/aws_s3_remote_datasource.dart';
import '../models/audio_metadata_model.dart';

class FormularioRepositoryImpl implements FormularioRepository {
  final AwsS3RemoteDataSource remoteDataSource;
  final LocalStorageDataSource localDataSource;

  FormularioRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, void>> enviarFormulario({
    required FormularioCompleto formulario,
    required File zipFile,
    void Function(double progress, String status)? onProgress,
  }) async {
    final mode = await StoragePreferenceService.getStorageMode();

    if (mode == StorageMode.local) {
      return await _enviarFormularioLocal(
        formulario: formulario,
        zipFile: zipFile,
        onProgress: onProgress,
      );
    } else {
      return await _enviarFormularioNube(
        formulario: formulario,
        zipFile: zipFile,
        onProgress: onProgress,
      );
    }
  }

  // ── Modo LOCAL ────────────────────────────────────────────────────────────

  Future<Either<Failure, void>> _enviarFormularioLocal({
    required FormularioCompleto formulario,
    required File zipFile,
    void Function(double progress, String status)? onProgress,
  }) async {
    try {
      // 1. Extraer los 4 WAV del ZIP
      onProgress?.call(0.05, 'Extrayendo archivos del ZIP...');

      final audios = await localDataSource.extraerAudiosDeZip(zipFile);

      onProgress?.call(0.20, 'Archivos extraídos correctamente');

      // 2. Nombre base (sin extensión) derivado del fileName del formulario
      //    El fileName tiene formato SC_YYYYMMDD_HHCC_FF_EST_ID.wav
      //    Necesitamos quitarle el .wav para usarlo como base.
      final baseFileName = formulario.fileName.replaceAll('.wav', '');

      // 3. Guardar los 4 audios en sus carpetas correspondientes
      onProgress?.call(0.25, 'Guardando archivos de audio...');

      final nombresGuardados = await localDataSource.guardarAudiosLocales(
        audios: audios,
        baseFileName: baseFileName,
      );

      onProgress?.call(0.75, 'Audios guardados correctamente');

      // 4. Construir metadata con los nombres finales de los 4 archivos
      final metadataModel = AudioMetadataModel(
        fechaNacimiento: formulario.metadata.fechaNacimiento,
        edad: formulario.metadata.edad,
        fechaGrabacion: formulario.metadata.fechaGrabacion,
        nombreAudioPrincipal: nombresGuardados['principal']!,
        nombreAudioEcg: nombresGuardados['ecg']!,
        nombreAudioEcg1: nombresGuardados['ecg1']!,
        nombreAudioEcg2: nombresGuardados['ecg2']!,
        hospital: formulario.metadata.hospital,
        codigoHospital: formulario.metadata.codigoHospital,
        consultorio: formulario.metadata.consultorio,
        codigoConsultorio: formulario.metadata.codigoConsultorio,
        estado: formulario.metadata.estado,
        focoAuscultacion: formulario.metadata.focoAuscultacion,
        codigoFoco: formulario.metadata.codigoFoco,
        observaciones: formulario.metadata.observaciones,
        genero: formulario.metadata.genero,
        pesoCkg: formulario.metadata.pesoCkg,
        alturaCm: formulario.metadata.alturaCm,
        categoriaAnomalia: formulario.metadata.categoriaAnomalia,
        codigoCategoriaAnomalia: formulario.metadata.codigoCategoriaAnomalia,
      );

      // 5. Guardar JSON de metadata
      onProgress?.call(0.85, 'Guardando metadatos...');

      await localDataSource.guardarMetadataLocal(
        metadata: metadataModel.toJson(),
        baseFileName: baseFileName,
      );

      onProgress?.call(1.0, 'Datos guardados localmente');

      // 6. Limpiar archivos temporales del ZIP (opcional pero recomendado)
      try {
        final tempDir = audios.principal.parent;
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      } catch (_) {
        // No es crítico si no se puede limpiar
      }

      return const Right(null);
    } on FileException catch (e) {
      return Left(FileFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  // ── Modo NUBE (sin cambios funcionales, preparado para futura extensión) ──

  Future<Either<Failure, void>> _enviarFormularioNube({
    required FormularioCompleto formulario,
    required File zipFile,
    void Function(double progress, String status)? onProgress,
  }) async {
    // TODO: Implementar subida a S3 de los 4 archivos WAV extraídos del ZIP.
    // Por ahora se mantiene la firma actualizada pero retorna error informativo.
    return const Left(
      UnexpectedFailure(
        'El modo nube aún no soporta archivos ZIP. '
        'Usa el almacenamiento local o espera la próxima actualización.',
      ),
    );
  }

  // ── Nombre de archivo ─────────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> generarNombreArchivo({
    required DateTime fechaNacimiento,
    required String codigoConsultorio,
    required String codigoHospital,
    required String codigoFoco,
    required String estado,
    String? observaciones,
  }) async {
    final mode = await StoragePreferenceService.getStorageMode();

    try {
      final ahora = DateTime.now();
      final anio = ahora.year.toString();
      final mes = ahora.month.toString().padLeft(2, '0');
      final dia = ahora.day.toString().padLeft(2, '0');
      final fechaStr = '$anio$mes$dia';

      final estStr = estado.toLowerCase() == 'normal' ? 'N' : 'A';

      final String audioId;
      if (mode == StorageMode.local) {
        audioId = await localDataSource.generarAudioIdUnicoLocal();
      } else {
        audioId = await remoteDataSource.generarAudioIdUnico();
      }

      // El nombre base se usa para todos los archivos; el sufijo (_ECG, etc.)
      // se agrega en LocalStorageDataSource al guardar cada uno.
      // Mantenemos .wav como extensión nominal del formulario (audio principal).
      final fileName = 'SC_${fechaStr}_$codigoHospital$codigoConsultorio'
          '_$codigoFoco'
          '_$estStr'
          '_$audioId.wav';

      return Right(fileName);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
