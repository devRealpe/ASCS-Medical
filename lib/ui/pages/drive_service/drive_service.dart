import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DriveService {
  Future<void> uploadFiles({
    required File audioFile,
    required Map<String, dynamic> jsonData,
    required String fileName,
    required void Function(double progress, String status) onProgress,
  }) async {
    try {
      // 🔹 1. Cargar credenciales de cuenta de servicio
      final jsonString =
          await rootBundle.loadString('lib/assets/credenciales.json');
      final credentials =
          auth.ServiceAccountCredentials.fromJson(json.decode(jsonString));

      // 🔹 2. Crear cliente de autenticación
      final client = await auth.clientViaServiceAccount(
          credentials, [drive.DriveApi.driveFileScope]);

      // Subir archivo de audio con seguimiento de progreso
      await _uploadFileToDrive(
        client: client,
        file: audioFile,
        fileName: fileName,
        mimeType: 'audio/wav',
        onProgress: onProgress,
      );

      // Subir JSON
      final jsonFile = await _createTempJsonFile(jsonData, fileName);
      await _uploadFileToDrive(
        client: client,
        file: jsonFile,
        fileName: '$fileName.json',
        mimeType: 'application/json',
        onProgress: onProgress,
      );
      await jsonFile.delete();

      onProgress(1.0, 'Archivos subidos exitosamente');
    } on SocketException catch (e) {
      throw Exception('Error de conexión: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('Error en la solicitud HTTP: ${e.message}');
    } catch (e) {
      throw Exception('Error crítico: ${e.toString()}');
    }
  }

  Future<File> _createTempJsonFile(
    Map<String, dynamic> jsonData,
    String fileName,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName.json');
    return file.writeAsString(jsonEncode(jsonData));
  }

  Future<void> _uploadFileToDrive({
    required auth.AuthClient client,
    required File file,
    required String fileName,
    required String mimeType,
    required void Function(double progress, String status) onProgress,
  }) async {
    try {
      var driveApi = drive.DriveApi(client);

      var media = drive.Media(file.openRead(), file.lengthSync());

      var fileMetadata = drive.File();
      fileMetadata.name = fileName;
      fileMetadata.parents = [
        "1T65JYEFuePon7gXO-HQc5ooXzZZAqSK4"
      ]; // ID de la carpeta en Drive

      var response =
          await driveApi.files.create(fileMetadata, uploadMedia: media);
      double progress = 0.0;
      double totalBytes = file.lengthSync().toDouble();
      file.openRead().listen(
        (chunk) {
          progress += chunk.length;
          onProgress(progress / totalBytes, 'Subiendo $fileName...');
        },
        onDone: () => onProgress(
            1.0, 'Archivo subido exitosamente con ID: ${response.id}'),
        onError: (e) => throw Exception('Error subiendo archivo: $e'),
      );
    } catch (e) {
      throw Exception('Error subiendo archivo: ${e.toString()}');
    }
  }

  void dispose() {
    // No es necesario cerrar sesión ya que no usamos GoogleSignIn
  }

  // Método para pruebas
  Future<void> testUpload() async {
    final testFile = File('${(await getTemporaryDirectory()).path}/test.txt');
    await testFile.writeAsString('Archivo de prueba');

    await uploadFiles(
      audioFile: testFile,
      jsonData: {'test': true},
      fileName: 'test_file',
      onProgress: (p, s) =>
          // ignore: avoid_print
          print('Progreso: ${(p * 100).toStringAsFixed(1)}% - $s'),
    );

    // ignore: avoid_print
    print('Prueba exitosa!');
    await testFile.delete();
  }
}
