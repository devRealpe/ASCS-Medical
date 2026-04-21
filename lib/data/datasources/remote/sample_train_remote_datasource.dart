// lib/data/datasources/remote/sample_train_remote_datasource.dart
//
// Servicio 2 — POST /ingest
// Envía archivos de audio + metadatos JSON para ingesta de diagnósticos.

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../local/local_storage_datasource.dart';

/// Respuesta del servicio de ingesta de archivos diagnósticos
class SampleTrainResponse {
  final String status;
  final String categoria;
  final int uploadStatus;
  final String respuestaLocal;

  const SampleTrainResponse({
    required this.status,
    required this.categoria,
    this.uploadStatus = 0,
    this.respuestaLocal = '',
  });

  factory SampleTrainResponse.fromJson(Map<String, dynamic> json) {
    return SampleTrainResponse(
      status: json['status'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
      uploadStatus: json['upload_status'] as int? ?? 0,
      respuestaLocal: json['respuesta_local'] as String? ?? '',
    );
  }
}

/// Contrato para el datasource de ingesta de archivos diagnósticos (Servicio 2)
abstract class SampleTrainRemoteDataSource {
  /// Envía los 4 audios y metadatos JSON al endpoint /ingest.
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
        Uri.parse('${ApiConstants.service2BaseUrl}${ApiConstants.ingest}');

    final request = http.MultipartRequest('POST', uri);

    // Campo: audios (múltiples archivos con el mismo nombre de campo)
    onStatus('Adjuntando audio principal...');
    request.files.add(
      await http.MultipartFile.fromPath(
        'audios',
        audios.principal.path,
        filename: audios.principal.path.split(Platform.pathSeparator).last,
        contentType: MediaType('audio', 'wav'),
      ),
    );

    onStatus('Adjuntando audio ECG...');
    request.files.add(
      await http.MultipartFile.fromPath(
        'audios',
        audios.ecg.path,
        filename: audios.ecg.path.split(Platform.pathSeparator).last,
        contentType: MediaType('audio', 'wav'),
      ),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'audios',
        audios.ecg1.path,
        filename: audios.ecg1.path.split(Platform.pathSeparator).last,
        contentType: MediaType('audio', 'wav'),
      ),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'audios',
        audios.ecg2.path,
        filename: audios.ecg2.path.split(Platform.pathSeparator).last,
        contentType: MediaType('audio', 'wav'),
      ),
    );

    // Campo: metadata_file (archivo JSON)
    onStatus('Preparando metadatos...');
    final jsonString = jsonEncode(metadataJson);
    final baseName = audios.principal.path
        .split(Platform.pathSeparator)
        .last
        .replaceAll('.wav', '');
    request.files.add(
      http.MultipartFile.fromString(
        'metadata_file',
        jsonString,
        filename: '$baseName.json',
        contentType: MediaType('application', 'json'),
      ),
    );

    onStatus('Enviando archivos al servidor de ingesta...');

    late http.StreamedResponse streamedResponse;
    try {
      streamedResponse =
          await request.send().timeout(const Duration(seconds: 180));
    } catch (_) {
      throw const NetworkException(
        'No se pudo conectar con el servicio de ingesta',
      );
    }

    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200 &&
        streamedResponse.statusCode != 201) {
      throw const ServerException(
        'No pudimos enviar los archivos en este momento.',
      );
    }

    try {
      final body = jsonDecode(responseBody) as Map<String, dynamic>;
      return SampleTrainResponse.fromJson(body);
    } catch (e) {
      // Si no se puede parsear pero el status fue exitoso, retornar OK
      return const SampleTrainResponse(
        status: 'ok',
        categoria: '',
      );
    }
  }
}
