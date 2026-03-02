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
import '../local/local_storage_datasource.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Resultado de subida de los 4 audios a S3
// ─────────────────────────────────────────────────────────────────────────────

/// Contiene las URLs públicas de los 4 archivos WAV subidos a S3.
class S3AudioUrls {
  /// URL del audio principal (carpeta public/Audios/)
  final String urlPrincipal;

  /// URL del audio ECG (carpeta public/ECG/)
  final String urlEcg;

  /// URL del audio ECG_1 (carpeta public/ECG_1/)
  final String urlEcg1;

  /// URL del audio ECG_2 (carpeta public/ECG_2/)
  final String urlEcg2;

  const S3AudioUrls({
    required this.urlPrincipal,
    required this.urlEcg,
    required this.urlEcg1,
    required this.urlEcg2,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Contrato
// ─────────────────────────────────────────────────────────────────────────────

/// Contrato para el data source remoto de AWS S3
abstract class AwsS3RemoteDataSource {
  /// Sube los 4 archivos WAV (extraídos del ZIP) a sus carpetas en S3.
  ///
  /// Estructura en S3:
  ///   public/Audios/   → audio principal (sin sufijo ECG)
  ///   public/ECG/      → audio con sufijo _ECG
  ///   public/ECG_1/    → audio con sufijo _ECG_1
  ///   public/ECG_2/    → audio con sufijo _ECG_2
  ///
  /// Retorna [S3AudioUrls] con las URLs públicas de cada archivo.
  Future<S3AudioUrls> subirAudiosDesdeZip({
    required ZipAudioFiles audios,
    required String baseFileName,
    void Function(double progress)? onProgress,
  });

  /// Sube el JSON de metadata a S3 (public/audios-json/).
  Future<void> subirMetadata({
    required Map<String, dynamic> metadata,
    required String baseFileName,
    void Function(double progress)? onProgress,
  });

  /// Genera un UUID v4 único verificando que no exista en S3.
  Future<String> generarAudioIdUnico();
}

// ─────────────────────────────────────────────────────────────────────────────
// Implementación
// ─────────────────────────────────────────────────────────────────────────────

/// Implementación del data source remoto usando AWS Amplify S3
class AwsS3RemoteDataSourceImpl implements AwsS3RemoteDataSource {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _uploadTimeout = Duration(minutes: 5);
  static const Duration _listTimeout = Duration(seconds: 30);
  static const int _maxUuidAttempts = 5;

  // Prefijos S3 para cada tipo de audio (espejo de las carpetas locales)
  static const String _s3PrefixAudios = 'public/Audios/';
  static const String _s3PrefixEcg = 'public/ECG/';
  static const String _s3PrefixEcg1 = 'public/ECG_1/';
  static const String _s3PrefixEcg2 = 'public/ECG_2/';
  static const String _s3PrefixJson = 'public/audios-json/';

  final _uuid = const Uuid();

  // ── Subida de los 4 audios ────────────────────────────────────────────────

  @override
  Future<S3AudioUrls> subirAudiosDesdeZip({
    required ZipAudioFiles audios,
    required String baseFileName,
    void Function(double progress)? onProgress,
  }) async {
    // Nombres finales de cada archivo en S3
    final namePrincipal = '$baseFileName.wav';
    final nameEcg = '${baseFileName}_ECG.wav';
    final nameEcg1 = '${baseFileName}_ECG_1.wav';
    final nameEcg2 = '${baseFileName}_ECG_2.wav';

    // Subir los 4 archivos secuencialmente reportando progreso acumulado
    // Cada archivo representa el 25% del progreso total de subida.
    String urlPrincipal = '';
    String urlEcg = '';
    String urlEcg1 = '';
    String urlEcg2 = '';

    // 1/4 — Audio principal
    urlPrincipal = await _executeWithRetry(
      operation: () => _subirAudio(
        file: audios.principal,
        s3Path: '$_s3PrefixAudios$namePrincipal',
        onProgress: (p) => onProgress?.call(p * 0.25),
      ),
      operationName: 'subir audio principal',
    );

    // 2/4 — ECG
    urlEcg = await _executeWithRetry(
      operation: () => _subirAudio(
        file: audios.ecg,
        s3Path: '$_s3PrefixEcg$nameEcg',
        onProgress: (p) => onProgress?.call(0.25 + p * 0.25),
      ),
      operationName: 'subir audio ECG',
    );

    // 3/4 — ECG_1
    urlEcg1 = await _executeWithRetry(
      operation: () => _subirAudio(
        file: audios.ecg1,
        s3Path: '$_s3PrefixEcg1$nameEcg1',
        onProgress: (p) => onProgress?.call(0.50 + p * 0.25),
      ),
      operationName: 'subir audio ECG_1',
    );

    // 4/4 — ECG_2
    urlEcg2 = await _executeWithRetry(
      operation: () => _subirAudio(
        file: audios.ecg2,
        s3Path: '$_s3PrefixEcg2$nameEcg2',
        onProgress: (p) => onProgress?.call(0.75 + p * 0.25),
      ),
      operationName: 'subir audio ECG_2',
    );

    return S3AudioUrls(
      urlPrincipal: urlPrincipal,
      urlEcg: urlEcg,
      urlEcg1: urlEcg1,
      urlEcg2: urlEcg2,
    );
  }

  // ── Metadata JSON ─────────────────────────────────────────────────────────

  @override
  Future<void> subirMetadata({
    required Map<String, dynamic> metadata,
    required String baseFileName,
    void Function(double progress)? onProgress,
  }) async {
    return await _executeWithRetry(
      operation: () =>
          _subirMetadataOperation(metadata, baseFileName, onProgress),
      operationName: 'subir metadata',
    );
  }

  // ── ID único ──────────────────────────────────────────────────────────────

  @override
  Future<String> generarAudioIdUnico() async {
    return await _executeWithRetry(
      operation: _generarAudioIdUnicoOperation,
      operationName: 'generar ID de audio único',
      maxRetries: 2,
    );
  }

  // ── Privados: operaciones S3 ──────────────────────────────────────────────

  /// Sube un único archivo WAV a [s3Path] y devuelve su URL pública.
  Future<String> _subirAudio({
    required File file,
    required String s3Path,
    void Function(double progress)? onProgress,
  }) async {
    if (!file.existsSync()) {
      throw FileException('El archivo no existe: ${file.path}');
    }

    final fileSizeMB = file.lengthSync() / (1024 * 1024);
    if (fileSizeMB > AppConstants.maxAudioFileSizeMB) {
      throw FileException(
        'El archivo es demasiado grande (${fileSizeMB.toStringAsFixed(1)} MB). '
        'Máximo: ${AppConstants.maxAudioFileSizeMB} MB',
      );
    }

    final uploadOperation = Amplify.Storage.uploadFile(
      localFile: AWSFile.fromPath(file.path),
      path: StoragePath.fromString(s3Path),
      onProgress: (p) {
        onProgress?.call(p.transferredBytes / p.totalBytes);
      },
    );

    await uploadOperation.result.timeout(
      _uploadTimeout,
      onTimeout: () => throw TimeoutException(
        'Tiempo de espera agotado subiendo ${file.path}',
        _uploadTimeout,
      ),
    );

    // URL pública del archivo en S3
    return 'https://${AppConstants.s3BucketName}'
        '.s3.${AppConstants.s3Region}.amazonaws.com/$s3Path';
  }

  Future<void> _subirMetadataOperation(
    Map<String, dynamic> metadata,
    String baseFileName,
    void Function(double progress)? onProgress,
  ) async {
    final jsonFile = await _crearArchivoJsonTemporal(metadata, baseFileName);

    try {
      final s3Path = '$_s3PrefixJson$baseFileName.json';

      final uploadOperation = Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(jsonFile.path),
        path: StoragePath.fromString(s3Path),
        onProgress: (p) {
          onProgress?.call(p.transferredBytes / p.totalBytes);
        },
      );

      await uploadOperation.result.timeout(
        _uploadTimeout,
        onTimeout: () => throw TimeoutException(
          'Tiempo de espera agotado subiendo metadata',
          _uploadTimeout,
        ),
      );
    } finally {
      if (await jsonFile.exists()) await jsonFile.delete();
    }
  }

  Future<String> _generarAudioIdUnicoOperation() async {
    for (int attempt = 0; attempt < _maxUuidAttempts; attempt++) {
      final candidateId =
          _uuid.v4().replaceAll('-', '').substring(0, 12).toUpperCase();
      final exists = await _audioIdExistsEnS3(candidateId);
      if (!exists) return candidateId;
    }
    return _uuid.v4().replaceAll('-', '').toUpperCase();
  }

  Future<bool> _audioIdExistsEnS3(String audioId) async {
    try {
      final result = await Amplify.Storage.list(
        path: StoragePath.fromString(_s3PrefixAudios),
        options: const StorageListOptions(pageSize: 1000),
      ).result.timeout(_listTimeout);

      return result.items.any((item) => item.path.contains(audioId));
    } catch (_) {
      return false;
    }
  }

  // ── Utilidades ────────────────────────────────────────────────────────────

  Future<File> _crearArchivoJsonTemporal(
    Map<String, dynamic> jsonData,
    String baseFileName,
  ) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$baseFileName.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(jsonData),
        flush: true,
      );
      return file;
    } catch (e) {
      throw FileException('Error al crear archivo JSON temporal: $e');
    }
  }

  // ── Reintentos ────────────────────────────────────────────────────────────

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
            'Sin conexión al $operationName. Verifica tu conexión.',
          );
        }
        await Future.delayed(_retryDelay * attempts);
      } on TimeoutException {
        attempts++;
        if (attempts >= maxRetries) {
          throw NetworkException(
            'Tiempo agotado al $operationName. La conexión es muy lenta.',
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
        } else {
          throw StorageException('Error al $operationName: ${e.message}');
        }
      } on FileException {
        rethrow;
      } catch (e) {
        throw StorageException('Error inesperado al $operationName: $e');
      }
    }

    throw NetworkException('Máximo de reintentos alcanzado al $operationName');
  }

  bool _isNetworkError(AmplifyException e) {
    final msg = e.message.toLowerCase();
    return msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('timeout') ||
        msg.contains('unreachable') ||
        msg.contains('socket');
  }

  bool _isAuthError(AmplifyException e) {
    final msg = e.message.toLowerCase();
    return msg.contains('auth') ||
        msg.contains('credential') ||
        msg.contains('permission') ||
        msg.contains('unauthorized');
  }
}
