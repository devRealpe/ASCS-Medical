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

      // 2. Nombre base sin extensión
      final baseFileName = formulario.fileName.replaceAll('.wav', '');

      // 3. Guardar los 4 audios en sus carpetas locales
      onProgress?.call(0.25, 'Guardando archivos de audio...');
      final nombresGuardados = await localDataSource.guardarAudiosLocales(
        audios: audios,
        baseFileName: baseFileName,
      );
      onProgress?.call(0.75, 'Audios guardados correctamente');

      // 4. Construir metadata con los nombres de archivo (modo local)
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

      // 6. Limpiar archivos temporales del ZIP
      try {
        final tempDir = audios.principal.parent;
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      } catch (_) {
        // No es crítico
      }

      return const Right(null);
    } on FileException catch (e) {
      return Left(FileFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  // ── Modo NUBE ─────────────────────────────────────────────────────────────

  Future<Either<Failure, void>> _enviarFormularioNube({
    required FormularioCompleto formulario,
    required File zipFile,
    void Function(double progress, String status)? onProgress,
  }) async {
    try {
      // 1. Extraer los 4 WAV del ZIP (igual que en local)
      onProgress?.call(0.03, 'Extrayendo archivos del ZIP...');
      final audios = await localDataSource.extraerAudiosDeZip(zipFile);
      onProgress?.call(0.10, 'Archivos extraídos. Iniciando subida a S3...');

      final baseFileName = formulario.fileName.replaceAll('.wav', '');

      // 2. Subir los 4 WAV a S3 en sus carpetas correspondientes
      //    El datasource reporta progreso 0.0→1.0 para los 4 archivos en total;
      //    lo mapeamos al rango 0.10→0.85 del flujo global.
      onProgress?.call(0.10, 'Subiendo audio principal...');

      final s3Urls = await remoteDataSource.subirAudiosDesdeZip(
        audios: audios,
        baseFileName: baseFileName,
        onProgress: (p) {
          // p va de 0.0 a 1.0 cubriendo los 4 archivos secuencialmente
          final globalProgress = 0.10 + (p * 0.75);
          final statusMsg = _statusParaProgreso(p);
          onProgress?.call(globalProgress, statusMsg);
        },
      );

      onProgress?.call(0.85, 'Audios subidos. Guardando metadatos...');

      // 3. Construir metadata con las URLs de S3 (en vez de nombres de archivo)
      final metadataModel = AudioMetadataModel(
        fechaNacimiento: formulario.metadata.fechaNacimiento,
        edad: formulario.metadata.edad,
        fechaGrabacion: formulario.metadata.fechaGrabacion,
        // En modo nube los campos guardan las URLs públicas de S3
        nombreAudioPrincipal: s3Urls.urlPrincipal,
        nombreAudioEcg: s3Urls.urlEcg,
        nombreAudioEcg1: s3Urls.urlEcg1,
        nombreAudioEcg2: s3Urls.urlEcg2,
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

      // 4. Subir JSON de metadata a S3 (public/audios-json/)
      await remoteDataSource.subirMetadata(
        metadata: metadataModel.toJson(),
        baseFileName: baseFileName,
        onProgress: (p) =>
            onProgress?.call(0.85 + (p * 0.14), 'Subiendo metadatos...'),
      );

      onProgress?.call(1.0, 'Datos enviados a la nube correctamente');

      // 5. Limpiar archivos temporales del ZIP
      try {
        final tempDir = audios.principal.parent;
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      } catch (_) {
        // No es crítico
      }

      return const Right(null);
    } on FileException catch (e) {
      return Left(FileFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  /// Texto de estado según el progreso acumulado de subida de los 4 audios.
  String _statusParaProgreso(double p) {
    if (p < 0.25) return 'Subiendo audio principal...';
    if (p < 0.50) return 'Subiendo audio ECG...';
    if (p < 0.75) return 'Subiendo audio ECG_1...';
    return 'Subiendo audio ECG_2...';
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
      final fechaStr =
          '${ahora.year}${ahora.month.toString().padLeft(2, '0')}${ahora.day.toString().padLeft(2, '0')}';

      final estStr = estado.toLowerCase() == 'normal' ? 'N' : 'A';

      final String audioId;
      if (mode == StorageMode.local) {
        audioId = await localDataSource.generarAudioIdUnicoLocal();
      } else {
        audioId = await remoteDataSource.generarAudioIdUnico();
      }

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
