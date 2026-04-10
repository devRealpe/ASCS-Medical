// lib/data/datasources/remote/sample_train_remote_datasource.dart
//
// Servicio 2 — POST /api/v1/train/sample
// Envía una muestra de entrenamiento con metadatos JSON + archivos de audio.

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../local/local_storage_datasource.dart';

/// Respuesta del servicio de muestras de entrenamiento
class SampleTrainResponse {
  final String status;
  final String message;

  const SampleTrainResponse({required this.status, required this.message});

  factory SampleTrainResponse.fromJson(Map<String, dynamic> json) {
    return SampleTrainResponse(
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

/// Contrato para el datasource de muestras de entrenamiento (Servicio 2)
abstract class SampleTrainRemoteDataSource {
  /// Envía una muestra de entrenamiento con los 4 audios y metadatos JSON.
  Future<SampleTrainResponse> enviarMuestra({
    required ZipAudioFiles audios,
    required Map<String, dynamic> metadataJson,
    required void Function(String status) onStatus,
  });
}

class SampleTrainRemoteDataSourceImpl implements SampleTrainRemoteDataSource {
  final http.Client httpClient;

  SampleTrainRemoteDataSourceImpl({required this.httpClient});

  @override
  Future<SampleTrainResponse> enviarMuestra({
    required ZipAudioFiles audios,
    required Map<String, dynamic> metadataJson,
    required void Function(String status) onStatus,
  }) async {
    final uri =
        Uri.parse('${ApiConstants.service2BaseUrl}${ApiConstants.trainSample}');

    final request = http.MultipartRequest('POST', uri);

    // Campo: json_metadata (string JSON)
    onStatus('Preparando metadatos...');
    request.fields['json_metadata'] = jsonEncode(metadataJson);

    // Campo: audio_principal (requerido)
    onStatus('Adjuntando audio principal...');
    request.files.add(
      await http.MultipartFile.fromPath(
        'audio_principal',
        audios.principal.path,
        filename: audios.principal.path.split(Platform.pathSeparator).last,
        contentType: MediaType('audio', 'wav'),
      ),
    );

    // Campo: audio_ecg (opcional)
    onStatus('Adjuntando audio ECG...');
    request.files.add(
      await http.MultipartFile.fromPath(
        'audio_ecg',
        audios.ecg.path,
        filename: audios.ecg.path.split(Platform.pathSeparator).last,
        contentType: MediaType('audio', 'wav'),
      ),
    );

    // Campo: audio_ecg_1 (opcional)
    request.files.add(
      await http.MultipartFile.fromPath(
        'audio_ecg_1',
        audios.ecg1.path,
        filename: audios.ecg1.path.split(Platform.pathSeparator).last,
        contentType: MediaType('audio', 'wav'),
      ),
    );

    // Campo: audio_ecg_2 (opcional)
    request.files.add(
      await http.MultipartFile.fromPath(
        'audio_ecg_2',
        audios.ecg2.path,
        filename: audios.ecg2.path.split(Platform.pathSeparator).last,
        contentType: MediaType('audio', 'wav'),
      ),
    );

    onStatus('Enviando muestra al servidor de entrenamiento...');

    late http.StreamedResponse streamedResponse;
    try {
      streamedResponse =
          await request.send().timeout(const Duration(seconds: 180));
    } catch (e) {
      throw NetworkException(
          'No se pudo conectar con el servicio de entrenamiento: $e');
    }

    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200 &&
        streamedResponse.statusCode != 201) {
      String errorMsg;
      try {
        final body = jsonDecode(responseBody) as Map<String, dynamic>;
        errorMsg = body['detail'] as String? ??
            body['message'] as String? ??
            'Error del servidor de entrenamiento';
      } catch (_) {
        errorMsg =
            'Error del servidor (${streamedResponse.statusCode}): $responseBody';
      }
      throw ServerException(errorMsg);
    }

    try {
      final body = jsonDecode(responseBody) as Map<String, dynamic>;
      return SampleTrainResponse.fromJson(body);
    } catch (e) {
      // Si no se puede parsear pero el status fue exitoso, retornar OK
      return const SampleTrainResponse(
        status: 'ok',
        message: 'Muestra enviada exitosamente',
      );
    }
  }
}
