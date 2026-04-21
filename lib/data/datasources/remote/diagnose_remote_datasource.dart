// lib/data/datasources/remote/diagnose_remote_datasource.dart
//
// Servicio 3 — POST /predict
// Envía un audio + metadatos para obtener predicción de la IA.

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/diagnostico/diagnose_response_model.dart';

/// Contrato para el datasource de diagnóstico IA (Servicio 3)
abstract class DiagnoseRemoteDataSource {
  /// Envía un audio .wav y metadatos JSON al endpoint /predict.
  /// Retorna el resultado de la predicción de la IA.
  Future<DiagnoseResponseModel> diagnosticar({
    required File audioFile,
    required Map<String, dynamic> metadataJson,
  });
}

class DiagnoseRemoteDataSourceImpl implements DiagnoseRemoteDataSource {
  final http.Client httpClient;

  DiagnoseRemoteDataSourceImpl({required this.httpClient});

  @override
  Future<DiagnoseResponseModel> diagnosticar({
    required File audioFile,
    required Map<String, dynamic> metadataJson,
  }) async {
    if (!audioFile.existsSync()) {
      throw const FileException('El archivo de audio no existe.');
    }

    final uri =
        Uri.parse('${ApiConstants.service3BaseUrl}${ApiConstants.predict}');

    developer.log('═══════════════════════════════════════', name: 'DIAGNOSE');
    developer.log('URL: $uri', name: 'DIAGNOSE');
    developer.log('Audio path: ${audioFile.path}', name: 'DIAGNOSE');
    developer.log('Audio size: ${audioFile.lengthSync()} bytes',
        name: 'DIAGNOSE');
    developer.log('JSON metadata: ${jsonEncode(metadataJson)}',
        name: 'DIAGNOSE');

    final request = http.MultipartRequest('POST', uri);

    // Campo: audio (archivo .wav)
    request.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
        filename: audioFile.path.split(Platform.pathSeparator).last,
        contentType: MediaType('audio', 'wav'),
      ),
    );

    // Campo: metadata_file (archivo JSON)
    final jsonString = jsonEncode(metadataJson);
    final audioFileName = audioFile.path
        .split(Platform.pathSeparator)
        .last
        .replaceAll('.wav', '');
    request.files.add(
      http.MultipartFile.fromString(
        'metadata_file',
        jsonString,
        filename: '$audioFileName.json',
        contentType: MediaType('application', 'json'),
      ),
    );

    developer.log('Fields enviados: ${request.fields.keys.toList()}',
        name: 'DIAGNOSE');
    developer.log(
        'Files enviados: ${request.files.map((f) => '${f.field}: ${f.filename} (${f.length} bytes)').toList()}',
        name: 'DIAGNOSE');

    late http.StreamedResponse streamedResponse;
    try {
      streamedResponse =
          await request.send().timeout(const Duration(seconds: 120));
    } catch (e) {
      developer.log('ERROR de conexión: $e', name: 'DIAGNOSE');
      throw const NetworkException(
        'No se pudo conectar con el servicio de diagnóstico',
      );
    }

    final responseBody = await streamedResponse.stream.bytesToString();

    developer.log('Status code: ${streamedResponse.statusCode}',
        name: 'DIAGNOSE');
    developer.log('Response body: $responseBody', name: 'DIAGNOSE');
    developer.log('═══════════════════════════════════════', name: 'DIAGNOSE');

    if (streamedResponse.statusCode != 200) {
      throw const ServerException(
        'No pudimos obtener el diagnóstico en este momento.',
      );
    }

    try {
      final body = jsonDecode(responseBody) as Map<String, dynamic>;
      developer.log('Parsed body OK: ${body.keys.toList()}', name: 'DIAGNOSE');
      return DiagnoseResponseModel.fromJson(body);
    } catch (e) {
      developer.log('ERROR parsing response: $e', name: 'DIAGNOSE');
      throw const ServerException(
        'No pudimos interpretar la respuesta del servicio de diagnóstico.',
      );
    }
  }
}
