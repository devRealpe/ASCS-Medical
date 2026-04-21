// lib/data/datasources/remote/auth_remote_datasource.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/auth/usuario_model.dart';

/// Contrato para el data source remoto de autenticación
abstract class AuthRemoteDataSource {
  /// Registra un nuevo usuario en el servidor.
  /// Lanza [ServerException] si la respuesta no es 2xx.
  Future<UsuarioModel> registrar({
    required String nombreUsuario,
    required String email,
    required String contrasena,
  });

  /// Inicia sesión con nombre de usuario y contraseña.
  /// Devuelve un [UsuarioModel] con token incluido.
  Future<UsuarioModel> login({
    required String nombreUsuario,
    required String contrasena,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client httpClient;

  AuthRemoteDataSourceImpl({required this.httpClient});

  @override
  Future<UsuarioModel> registrar({
    required String nombreUsuario,
    required String email,
    required String contrasena,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}');

    late http.Response response;
    try {
      response = await httpClient
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nombreUsuario': nombreUsuario,
              'email': email,
              'contrasena': contrasena,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw NetworkException('No se pudo conectar con el servidor');
    }

    final body = _decodeBody(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Algunos backends devuelven el objeto directamente; otros lo envuelven
      final data = body is Map<String, dynamic>
          ? body
          : (body['usuario'] ?? body['user'] ?? body) as Map<String, dynamic>;
      return UsuarioModel.fromJson(data);
    }

    // Errores conocidos
    final message = body is Map
        ? (body['message'] ?? body['error'] ?? 'Error desconocido').toString()
        : 'Error del servidor';

    if (response.statusCode == 409 || message.toLowerCase().contains('exist')) {
      throw ServerException('El correo o usuario ya está registrado');
    }
    if (response.statusCode == 400) {
      throw ServerException('Datos inválidos: $message');
    }

    throw ServerException(
        'Error del servidor (${response.statusCode}): $message');
  }

  dynamic _decodeBody(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  @override
  Future<UsuarioModel> login({
    required String nombreUsuario,
    required String contrasena,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}');

    late http.Response response;
    try {
      response = await httpClient
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nombreUsuario': nombreUsuario,
              'contrasena': contrasena,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw NetworkException('No se pudo conectar con el servidor');
    }

    final body = _decodeBody(response);

    if (response.statusCode == 200) {
      return UsuarioModel.fromLoginJson(body as Map<String, dynamic>);
    }

    final message = body is Map
        ? (body['message'] ?? body['error'] ?? 'Error desconocido').toString()
        : 'Error del servidor';

    if (response.statusCode == 401) {
      throw ServerException('Usuario o contraseña incorrectos');
    }
    if (response.statusCode == 404) {
      throw ServerException('Usuario no encontrado');
    }

    throw ServerException(
        'Error del servidor (${response.statusCode}): $message');
  }
}
