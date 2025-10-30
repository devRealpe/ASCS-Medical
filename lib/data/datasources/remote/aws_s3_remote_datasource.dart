// lib/data/datasources/remote/aws_s3_remote_datasource.dart

import 'dart:convert';
import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart' hide StorageException;
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';

/// Contrato para el data source remoto de AWS S3
abstract class AwsS3RemoteDataSource {
  /// Sube un archivo de audio a S3
  /// Retorna la URL pública del archivo subido
  Future<String> subirAudio({
    required File audioFile,
    required String fileName,
    void Function(double progress)? onProgress,
  });

  /// Sube los metadatos en formato JSON a S3
  Future<void> subirMetadata({
    required Map<String, dynamic> metadata,
    required String fileName,
    void Function(double progress)? onProgress,
  });

  /// Obtiene el siguiente ID disponible para un archivo de audio
  Future<String> obtenerSiguienteAudioId();
}

/// Implementación del data source remoto usando AWS Amplify S3
class AwsS3RemoteDataSourceImpl implements AwsS3RemoteDataSource {
  @override
  Future<String> subirAudio({
    required File audioFile,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Validar que el archivo existe
      if (!audioFile.existsSync()) {
        throw const FileException('El archivo de audio no existe');
      }

      // Ruta en S3
      final s3Path = '${AppConstants.s3AudioPrefix}$fileName';

      // Subir archivo
      final uploadOperation = Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(audioFile.path),
        path: StoragePath.fromString(s3Path),
        onProgress: (uploadProgress) {
          final fraction =
              uploadProgress.transferredBytes / uploadProgress.totalBytes;
          onProgress?.call(fraction);
        },
      );

      await uploadOperation.result;

      // Construir URL pública
      final audioUrl =
          'https://${AppConstants.s3BucketName}.s3.${AppConstants.s3Region}.amazonaws.com/$s3Path';

      return audioUrl;
    } on AmplifyException catch (e) {
      // Captura excepciones de Amplify
      throw StorageException('Error al subir audio: ${e.message}');
    } catch (e) {
      throw StorageException('Error inesperado al subir audio: $e');
    }
  }

  @override
  Future<void> subirMetadata({
    required Map<String, dynamic> metadata,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Crear archivo JSON temporal
      final jsonFile = await _createTempJsonFile(metadata, fileName);

      // Ruta en S3 (sin extensión .wav, agregamos .json)
      final fileNameWithoutExt = fileName.replaceAll('.wav', '');
      final s3Path = '${AppConstants.s3JsonPrefix}$fileNameWithoutExt.json';

      // Subir archivo JSON
      final uploadOperation = Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(jsonFile.path),
        path: StoragePath.fromString(s3Path),
        onProgress: (uploadProgress) {
          final fraction =
              uploadProgress.transferredBytes / uploadProgress.totalBytes;
          onProgress?.call(fraction);
        },
      );

      await uploadOperation.result;

      // Eliminar archivo temporal
      await jsonFile.delete();
    } on AmplifyException catch (e) {
      // Captura excepciones de Amplify
      throw StorageException('Error al subir metadatos: ${e.message}');
    } catch (e) {
      throw StorageException('Error inesperado al subir metadatos: $e');
    }
  }

  @override
  Future<String> obtenerSiguienteAudioId() async {
    try {
      // Listar archivos en la carpeta de audios
      final result = await Amplify.Storage.list(
        path: StoragePath.fromString(AppConstants.s3AudioPrefix),
        options: const StorageListOptions(
          pageSize: 1000, // Ajustar según necesidad
        ),
      ).result;

      // Contar archivos y calcular siguiente ID
      final count = result.items.length;
      final nextId = count + 1;

      // Formatear con padding según configuración
      return nextId.toString().padLeft(AppConstants.audioIdPadding, '0');
    } on AmplifyException catch (e) {
      // Captura excepciones de Amplify
      throw ServerException('Error al obtener ID de audio: ${e.message}');
    } catch (e) {
      throw ServerException('Error inesperado al obtener ID: $e');
    }
  }

  /// Crea un archivo JSON temporal
  Future<File> _createTempJsonFile(
    Map<String, dynamic> jsonData,
    String fileName,
  ) async {
    try {
      final dir = await getTemporaryDirectory();
      final fileNameWithoutExt = fileName.replaceAll('.wav', '');
      final file = File('${dir.path}/$fileNameWithoutExt.json');

      await file.writeAsString(
        jsonEncode(jsonData),
        flush: true,
      );

      return file;
    } catch (e) {
      throw FileException('Error al crear archivo JSON temporal: $e');
    }
  }
}
