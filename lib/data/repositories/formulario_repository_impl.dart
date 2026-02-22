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
    required File audioFile,
    void Function(double progress, String status)? onProgress,
  }) async {
    // Determinar modo de almacenamiento
    final mode = await StoragePreferenceService.getStorageMode();

    if (mode == StorageMode.local) {
      return await _enviarFormularioLocal(
        formulario: formulario,
        audioFile: audioFile,
        onProgress: onProgress,
      );
    } else {
      return await _enviarFormularioNube(
        formulario: formulario,
        audioFile: audioFile,
        onProgress: onProgress,
      );
    }
  }

  /// Envía el formulario guardando localmente
  Future<Either<Failure, void>> _enviarFormularioLocal({
    required FormularioCompleto formulario,
    required File audioFile,
    void Function(double progress, String status)? onProgress,
  }) async {
    try {
      // 1. Guardar archivo de audio localmente
      onProgress?.call(0.1, 'Guardando archivo de audio...');

      final rutaAudioLocal = await localDataSource.guardarAudioLocal(
        audioFile: audioFile,
        fileName: formulario.fileName,
      );

      onProgress?.call(0.5, 'Audio guardado localmente');

      // 2. En modo local, url_audio = nombre del archivo (identificador)
      // Ya tenemos el ID único en el nombre del archivo, lo usamos como referencia
      final metadataModel = AudioMetadataModel(
        fechaNacimiento: formulario.metadata.fechaNacimiento,
        edad: formulario.metadata.edad,
        fechaGrabacion: formulario.metadata.fechaGrabacion,
        urlAudio: rutaAudioLocal, // Ruta local en lugar de URL
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

      // 3. Guardar metadata JSON localmente
      onProgress?.call(0.6, 'Guardando metadatos...');

      await localDataSource.guardarMetadataLocal(
        metadata: metadataModel.toJson(),
        fileName: formulario.fileName,
      );

      onProgress?.call(1.0, 'Datos guardados localmente');

      return const Right(null);
    } on FileException catch (e) {
      return Left(FileFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  /// Envía el formulario a AWS S3 (comportamiento original)
  Future<Either<Failure, void>> _enviarFormularioNube({
    required FormularioCompleto formulario,
    required File audioFile,
    void Function(double progress, String status)? onProgress,
  }) async {
    try {
      // 1. Subir archivo de audio
      onProgress?.call(0.0, 'Subiendo archivo de audio...');

      final audioUrl = await remoteDataSource.subirAudio(
        audioFile: audioFile,
        fileName: formulario.fileName,
        onProgress: (progress) {
          onProgress?.call(progress * 0.5, 'Subiendo archivo de audio...');
        },
      );

      onProgress?.call(0.5, 'Archivo de audio subido exitosamente');

      // 2. Actualizar metadata con la URL del audio
      final metadataModel = AudioMetadataModel(
        fechaNacimiento: formulario.metadata.fechaNacimiento,
        edad: formulario.metadata.edad,
        fechaGrabacion: formulario.metadata.fechaGrabacion,
        urlAudio: audioUrl,
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

      // 3. Subir archivo JSON con metadata
      onProgress?.call(0.5, 'Subiendo metadatos...');

      await remoteDataSource.subirMetadata(
        metadata: metadataModel.toJson(),
        fileName: formulario.fileName,
        onProgress: (progress) {
          onProgress?.call(0.5 + progress * 0.5, 'Subiendo metadatos...');
        },
      );

      onProgress?.call(1.0, 'Formulario enviado exitosamente');

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generarNombreArchivo({
    required DateTime fechaNacimiento,
    required String codigoConsultorio,
    required String codigoHospital,
    required String codigoFoco,
    required String estado,
    String? observaciones,
  }) async {
    // Determinar modo de almacenamiento
    final mode = await StoragePreferenceService.getStorageMode();

    try {
      final ahora = DateTime.now();

      // Formato YYYYMMDD
      final anio = ahora.year.toString();
      final mes = ahora.month.toString().padLeft(2, '0');
      final dia = ahora.day.toString().padLeft(2, '0');
      final fechaStr = '$anio$mes$dia';

      // Estado: N (Normal) o A (Anormal)
      final estStr = estado.toLowerCase() == 'normal' ? 'N' : 'A';

      // Generar ID único según el modo
      final String audioId;
      if (mode == StorageMode.local) {
        audioId = await localDataSource.generarAudioIdUnicoLocal();
      } else {
        audioId = await remoteDataSource.generarAudioIdUnico();
      }

      // Formato: SC_YYYYMMDD_HHCC_FF_EST_AAAA.wav
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
