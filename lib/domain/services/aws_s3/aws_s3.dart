import 'dart:convert';
import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:path_provider/path_provider.dart';

class AwsAmplifyS3Service {
  /// Sube un archivo de audio y los datos del formulario (como archivo JSON) a S3.
  Future<void> sendFormDataToS3({
    required File audioFile,
    required Map<String, dynamic> jsonData,
    required String fileName,
    required void Function(double progress, String status) onProgress,
  }) async {
    try {
      // 1. Subir archivo de audio
      onProgress(0.0, 'Subiendo archivo de audio...');
      final audioUploadOperation = Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(audioFile.path),
        path: StoragePath.fromString('public/audios/$fileName'),
        onProgress: (progress) {
          final fractionCompleted =
              progress.transferredBytes / progress.totalBytes;
          onProgress(fractionCompleted * 0.5, 'Subiendo archivo de audio...');
        },
      );
      await audioUploadOperation.result;
      onProgress(0.5, 'Archivo de audio subido exitosamente');

      // 2. Crear archivo JSON temporal con los datos del formulario
      final jsonFile = await _createTempJsonFile(jsonData, fileName);

      // 3. Subir archivo JSON
      onProgress(0.5, 'Subiendo archivo JSON...');
      final jsonUploadOperation = Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(jsonFile.path),
        path: StoragePath.fromString('public/audios-json/$fileName.json'),
        onProgress: (progress) {
          final fractionCompleted =
              progress.transferredBytes / progress.totalBytes;
          onProgress(0.5 + fractionCompleted * 0.5, 'Subiendo archivo JSON...');
        },
      );
      await jsonUploadOperation.result;
      onProgress(1.0, 'Archivos subidos exitosamente a S3');

      // Elimina el archivo JSON temporal
      await jsonFile.delete();
    } on StorageException catch (e) {
      throw Exception('Error en la subida: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Crea un archivo JSON temporal a partir del Map de datos y lo devuelve como File.
  Future<File> _createTempJsonFile(
      Map<String, dynamic> jsonData, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName.json');
    await file.writeAsString(jsonEncode(jsonData));
    return file;
  }
}
