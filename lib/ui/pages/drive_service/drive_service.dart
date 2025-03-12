import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';

class DriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file', // Para crear/administrar archivos
      'https://www.googleapis.com/auth/drive.metadata.readonly', // Solo lectura de metadatos
      'email', // Para obtener el correo del usuario
    ],
    clientId:
        '385400839963-90bn451i0kvqmdo0odv4jctkou1snmon.apps.googleusercontent.com',
  );

  Future<void> uploadFiles({
    required File audioFile,
    required Map<String, dynamic> jsonData,
    required String fileName,
    required void Function(double progress, String status) onProgress,
  }) async {
    try {
      final googleUser = await _handleAuthentication();
      final accessToken = await _getAccessToken(googleUser);

      // Subir archivo de audio con seguimiento de progreso
      await _uploadFileToDrive(
        accessToken: accessToken,
        file: audioFile,
        fileName: fileName,
        mimeType: 'audio/wav',
        onProgress: onProgress,
      );

      // Subir JSON
      final jsonFile = await _createTempJsonFile(jsonData, fileName);
      await _uploadFileToDrive(
        accessToken: accessToken,
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

  Future<GoogleSignInAccount> _handleAuthentication() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('El usuario canceló la autenticación');
      }
      return googleUser;
    } catch (e) {
      throw Exception('Error de autenticación: ${e.toString()}');
    }
  }

  Future<String> _getAccessToken(GoogleSignInAccount googleUser) async {
    try {
      final authHeaders = await googleUser.authHeaders;
      return authHeaders['Authorization']?.split(' ')[1] ?? '';
    } catch (e) {
      throw Exception('Error obteniendo token: ${e.toString()}');
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
    required String accessToken,
    required File file,
    required String fileName,
    required String mimeType,
    required void Function(double progress, String status) onProgress,
  }) async {
    try {
      final url = Uri.parse(
          'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart');
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();

      final request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..fields['metadata'] = jsonEncode({
          'name': fileName,
          'mimeType': mimeType,
          'parents': ['root']
        })
        ..files.add(http.MultipartFile(
          'file',
          fileStream,
          fileLength,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ));

      final response = await request.send();
      final completer = Completer<void>();
      double progress = 0.0;

      response.stream.listen(
        (List<int> chunk) {
          final cumulative = response.contentLength ?? fileLength;
          progress = cumulative / fileLength;
          onProgress(progress, 'Subiendo ${file.path.split('/').last}...');
        },
        onDone: () {
          if (response.statusCode == 200) {
            completer.complete();
          } else {
            completer.completeError(
              Exception(
                  'Error ${response.statusCode}: ${response.reasonPhrase}'),
            );
          }
        },
        onError: completer.completeError,
      );

      return await completer.future;
    } catch (e) {
      throw Exception('Error subiendo archivo: ${e.toString()}');
    }
  }

  void dispose() {
    _googleSignIn.signOut();
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
