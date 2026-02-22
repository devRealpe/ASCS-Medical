// lib/data/datasources/remote/aws_s3_remote_datasource.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart'
    hide StorageException, NetworkException;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';

/// Contrato para el data source remoto de AWS S3
abstract class AwsS3RemoteDataSource {
  Future<String> subirAudio({
    required File audioFile,
    required String fileName,
    void Function(double progress)? onProgress,
  });

  Future<void> subirMetadata({
    required Map<String, dynamic> metadata,
    required String fileName,
    void Function(double progress)? onProgress,
  });

  /// Genera un UUID v4 único verificando que no exista en S3
  Future<String> generarAudioIdUnico();
}

/// Implementación del data source remoto usando AWS Amplify S3
class AwsS3RemoteDataSourceImpl implements AwsS3RemoteDataSource {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _uploadTimeout = Duration(minutes: 5);
  static const Duration _listTimeout = Duration(seconds: 30);

  // Máximo de intentos para generar un UUID único
  static const int _maxUuidAttempts = 5;

  final _uuid = const Uuid();

  @override
  Future<String> subirAudio({
    required File audioFile,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    return await _executeWithRetry(
      operation: () => _uploadAudioOperation(audioFile, fileName, onProgress),
      operationName: 'subir audio',
    );
  }

  @override
  Future<void> subirMetadata({
    required Map<String, dynamic> metadata,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    return await _executeWithRetry(
      operation: () => _uploadMetadataOperation(metadata, fileName, onProgress),
      operationName: 'subir metadata',
    );
  }

  @override
  Future<String> generarAudioIdUnico() async {
    return await _executeWithRetry(
      operation: _generarAudioIdUnicoOperation,
      operationName: 'generar ID de audio único',
      maxRetries: 2,
    );
  }

  /// Genera un UUID v4 y verifica que no exista ya en S3.
  /// Reintenta hasta [_maxUuidAttempts] veces.
  Future<String> _generarAudioIdUnicoOperation() async {
    for (int attempt = 0; attempt < _maxUuidAttempts; attempt++) {
      final candidateId =
          _uuid.v4().replaceAll('-', '').substring(0, 12).toUpperCase();

      // Verificar si ya existe un archivo con este ID en S3
      final exists = await _audioIdExistsEnS3(candidateId);
      if (!exists) {
        return candidateId;
      }
    }

    // Si por alguna razón todos los intentos colisionan (extremadamente improbable),
    // usar el UUID completo sin guiones para máxima unicidad
    return _uuid.v4().replaceAll('-', '').toUpperCase();
  }

  /// Verifica si un audio con el ID dado ya existe en el bucket S3
  Future<bool> _audioIdExistsEnS3(String audioId) async {
    try {
      final result = await Amplify.Storage.list(
        path: StoragePath.fromString(AppConstants.s3AudioPrefix),
        options: const StorageListOptions(pageSize: 1000),
      ).result.timeout(_listTimeout);

      // Buscar si algún archivo en S3 contiene el ID en su nombre
      return result.items.any((item) {
        final key = item.path;
        return key.contains(audioId);
      });
    } catch (_) {
      // Si no podemos verificar, asumimos que no existe (el UUID es estadísticamente único)
      return false;
    }
  }

  /// Ejecuta una operación con estrategia de reintentos
  Future<T> _executeWithRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = _maxRetries,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } on SocketException {
        attempts++;
        if (attempts >= maxRetries) {
          throw NetworkException(
            'Sin conexión a Internet al $operationName. Verifica tu conexión.',
          );
        }
        await Future.delayed(_retryDelay * attempts);
      } on TimeoutException {
        attempts++;
        if (attempts >= maxRetries) {
          throw NetworkException(
            'Tiempo de espera agotado al $operationName. La conexión es muy lenta.',
          );
        }
        await Future.delayed(_retryDelay * attempts);
      } on AmplifyException catch (e) {
        if (_isNetworkError(e)) {
          attempts++;
          if (attempts >= maxRetries) {
            throw NetworkException(
                'Error de red al $operationName: ${e.message}');
          }
          await Future.delayed(_retryDelay * attempts);
        } else if (_isAuthError(e)) {
          throw StorageException(
              'Error de autenticación al $operationName: ${e.message}');
        } else if (_isStorageError(e)) {
          throw StorageException(
              'Error de almacenamiento al $operationName: ${e.message}');
        } else {
          throw StorageException('Error al $operationName: ${e.message}');
        }
      } catch (e) {
        throw StorageException('Error inesperado al $operationName: $e');
      }
    }

    throw NetworkException('Máximo de reintentos alcanzado al $operationName');
  }

  Future<String> _uploadAudioOperation(
    File audioFile,
    String fileName,
    void Function(double progress)? onProgress,
  ) async {
    if (!audioFile.existsSync()) {
      throw const FileException('El archivo de audio no existe');
    }

    final fileSize = audioFile.lengthSync();
    final fileSizeMB = fileSize / (1024 * 1024);
    if (fileSizeMB > AppConstants.maxAudioFileSizeMB) {
      throw FileException(
        'El archivo es demasiado grande (${fileSizeMB.toStringAsFixed(1)} MB). '
        'Máximo permitido: ${AppConstants.maxAudioFileSizeMB} MB',
      );
    }

    final s3Path = '${AppConstants.s3AudioPrefix}$fileName';

    final uploadOperation = Amplify.Storage.uploadFile(
      localFile: AWSFile.fromPath(audioFile.path),
      path: StoragePath.fromString(s3Path),
      onProgress: (uploadProgress) {
        final fraction =
            uploadProgress.transferredBytes / uploadProgress.totalBytes;
        onProgress?.call(fraction);
      },
    );

    await uploadOperation.result.timeout(
      _uploadTimeout,
      onTimeout: () {
        throw TimeoutException(
          'Tiempo de espera agotado al subir audio',
          _uploadTimeout,
        );
      },
    );

    final audioUrl =
        'https://${AppConstants.s3BucketName}.s3.${AppConstants.s3Region}.amazonaws.com/$s3Path';

    return audioUrl;
  }

  Future<void> _uploadMetadataOperation(
    Map<String, dynamic> metadata,
    String fileName,
    void Function(double progress)? onProgress,
  ) async {
    final jsonFile = await _createTempJsonFile(metadata, fileName);

    try {
      final fileNameWithoutExt = fileName.replaceAll('.wav', '');
      final s3Path = '${AppConstants.s3JsonPrefix}$fileNameWithoutExt.json';

      final uploadOperation = Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(jsonFile.path),
        path: StoragePath.fromString(s3Path),
        onProgress: (uploadProgress) {
          final fraction =
              uploadProgress.transferredBytes / uploadProgress.totalBytes;
          onProgress?.call(fraction);
        },
      );

      await uploadOperation.result.timeout(
        _uploadTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Tiempo de espera agotado al subir metadata',
            _uploadTimeout,
          );
        },
      );
    } finally {
      if (await jsonFile.exists()) {
        await jsonFile.delete();
      }
    }
  }

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

  bool _isNetworkError(AmplifyException e) {
    final message = e.message.toLowerCase();
    return message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('unreachable') ||
        message.contains('socket');
  }

  bool _isAuthError(AmplifyException e) {
    final message = e.message.toLowerCase();
    return message.contains('auth') ||
        message.contains('credential') ||
        message.contains('permission') ||
        message.contains('unauthorized');
  }

  bool _isStorageError(AmplifyException e) {
    final message = e.message.toLowerCase();
    return message.contains('not found') ||
        message.contains('does not exist') ||
        message.contains('no such key');
  }
}
