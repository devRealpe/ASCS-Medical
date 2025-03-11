import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';

class DriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.file'],
  );

  Future<void> uploadFiles({
    required File audioFile,
    required Map<String, dynamic> jsonData,
    required String fileName,
    required Null Function(dynamic progress, dynamic status) onProgress,
  }) async {
    try {
      final googleUser = await _handleAuthentication();
      final accessToken = await _getAccessToken(googleUser);

      await _uploadFileToDrive(
        accessToken: accessToken,
        file: audioFile,
        fileName: fileName,
        mimeType: 'audio/wav',
      );

      final jsonFile = await _createTempJsonFile(jsonData, fileName);
      await _uploadFileToDrive(
        accessToken: accessToken,
        file: jsonFile,
        fileName: '$fileName.json',
        mimeType: 'application/json',
      );
      await jsonFile.delete();
    } catch (e) {
      throw Exception('Error en la subida: ${e.toString()}');
    }
  }

  Future<GoogleSignInAccount> _handleAuthentication() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Autenticación cancelada');
    return googleUser;
  }

  Future<String> _getAccessToken(GoogleSignInAccount googleUser) async {
    final authHeaders = await googleUser.authHeaders;
    return authHeaders['Authorization']?.split(' ')[1] ?? '';
  }

  Future<File> _createTempJsonFile(
      Map<String, dynamic> jsonData, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName.json');
    return file.writeAsString(jsonEncode(jsonData));
  }

  Future<void> _uploadFileToDrive({
    required String accessToken,
    required File file,
    required String fileName,
    required String mimeType,
  }) async {
    final url =
        'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart';

    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..fields['metadata'] = jsonEncode({
        'name': fileName,
        'mimeType': mimeType,
        'parents': ['root']
      })
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: mimeType == 'audio/wav'
            ? MediaType('audio', 'wav')
            : MediaType('application', 'json'),
      ));

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception(
          'Error al subir archivo: ${await response.stream.bytesToString()}');
    }
  }
}
