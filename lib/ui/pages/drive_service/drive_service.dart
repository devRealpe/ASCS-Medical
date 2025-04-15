import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DriveService {
  /// Recibe la información del formulario (archivo de audio, datos en formato JSON y nombre del archivo)
  /// y se encarga de realizar el proceso de envío a Google Drive.
  Future<void> sendFormDataToDrive({
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

      // 🔹 3. Subir archivo de audio
      await _uploadFileToDrive(
        client: client,
        file: audioFile,
        fileName: fileName,
        mimeType: 'audio/wav',
        onProgress: onProgress,
      );

      // 🔹 4. Generar archivo JSON temporal a partir de los datos del formulario
      final jsonFile = await _createTempJsonFile(jsonData, fileName);

      // 🔹 5. Subir archivo JSON
      await _uploadFileToDrive(
        client: client,
        file: jsonFile,
        fileName: '$fileName.json',
        mimeType: 'application/json',
        onProgress: onProgress,
      );
      await jsonFile.delete();

      // Notificar que ambos archivos se han subido exitosamente.
      onProgress(1.0, '¡Form data enviada exitosamente!');
    } on SocketException catch (e) {
      throw Exception('Error de conexión: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('Error en la solicitud HTTP: ${e.message}');
    } catch (e) {
      throw Exception('Error crítico: ${e.toString()}');
    }
  }

  /// Crea un archivo JSON temporal a partir de los datos recibidos.
  Future<File> _createTempJsonFile(
    Map<String, dynamic> jsonData,
    String fileName,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName.json');
    return file.writeAsString(jsonEncode(jsonData));
  }

  /// Método encargado de realizar la subida de un archivo a Google Drive.
  /// Se envía el archivo junto con su metadata y se realiza el seguimiento de progreso.
  Future<void> _uploadFileToDrive({
    required auth.AuthClient client,
    required File file,
    required String fileName,
    required String mimeType,
    required void Function(double progress, String status) onProgress,
  }) async {
    try {
      final driveApi = drive.DriveApi(client);
      final media = drive.Media(file.openRead(), file.lengthSync());
      final fileMetadata = drive.File()
        ..name = fileName
        ..parents = [
          "1T65JYEFuePon7gXO-HQc5ooXzZZAqSK4"
        ]; // ID de la carpeta en Drive

      // Se realiza la petición de subida
      final response = await driveApi.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      double progress = 0.0;
      final totalBytes = file.lengthSync().toDouble();

      // Se utiliza listen para ir marcando el progreso de la subida.
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
    // No es necesario cerrar sesión ya que no usamos GoogleSignIn.
  }

  // Método para pruebas (opcional)
  Future<void> testUpload() async {
    final tempDir = await getTemporaryDirectory();
    final testFile = File('${tempDir.path}/test.txt');
    await testFile.writeAsString('Archivo de prueba');

    await sendFormDataToDrive(
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
