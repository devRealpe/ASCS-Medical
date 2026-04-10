// lib/data/datasources/remote/train_remote_datasource.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/entrenamiento/train_response_model.dart';

abstract class TrainRemoteDataSource {
  /// Envía un audio .wav y su metadata JSON al endpoint /train.
  /// Retorna la respuesta del modelo de entrenamiento.
  Future<TrainResponseModel> enviarEntrenamiento({
    required File audioFile,
    required Map<String, dynamic> metadataJson,
  });
}

class TrainRemoteDataSourceImpl implements TrainRemoteDataSource {
  final http.Client httpClient;

  TrainRemoteDataSourceImpl({required this.httpClient});

  @override
  Future<TrainResponseModel> enviarEntrenamiento({
    required File audioFile,
    required Map<String, dynamic> metadataJson,
  }) async {
    // Validar que el archivo existe y es .wav
    if (!audioFile.existsSync()) {
      throw const FileException('El archivo de audio no existe.');
    }
    if (!audioFile.path.toLowerCase().endsWith('.wav')) {
      throw const FileException('El archivo debe ser formato .wav');
    }

    final uri = Uri.parse('${ApiConstants.trainBaseUrl}${ApiConstants.train}');

    final request = http.MultipartRequest('POST', uri);

    // Campo 1: audio (.wav)
    request.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
        filename: audioFile.path.split(Platform.pathSeparator).last,
      ),
    );

    // Campo 2: metadata (.json) — se envía como archivo en memoria
    final jsonString = jsonEncode(metadataJson);
    final audioFileName = audioFile.path
        .split(Platform.pathSeparator)
        .last
        .replaceAll('.wav', '');
    request.files.add(
      http.MultipartFile.fromString(
        'metadata',
        jsonString,
        filename: '$audioFileName.json',
        contentType: MediaType('application', 'json'),
      ),
    );

    late http.StreamedResponse streamedResponse;
    try {
      streamedResponse =
          await request.send().timeout(const Duration(seconds: 120));
    } catch (e) {
      throw NetworkException(
          'No se pudo conectar con el servidor de entrenamiento: $e');
    }

    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200) {
      String errorMsg;
      try {
        final body = jsonDecode(responseBody) as Map<String, dynamic>;
        errorMsg =
            body['message'] as String? ?? 'Error del servidor de entrenamiento';
      } catch (_) {
        errorMsg =
            'Error del servidor (${streamedResponse.statusCode}): $responseBody';
      }
      throw ServerException(errorMsg);
    }

    try {
      final body = jsonDecode(responseBody) as Map<String, dynamic>;
      return TrainResponseModel.fromJson(body);
    } catch (e) {
      throw ServerException('Error al interpretar la respuesta: $e');
    }
  }
}
