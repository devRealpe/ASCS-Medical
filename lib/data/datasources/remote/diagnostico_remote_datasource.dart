// lib/data/datasources/remote/diagnostico_remote_datasource.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/services/session_service.dart';
import '../../models/diagnostico/diagnostico_model.dart';

abstract class DiagnosticoRemoteDataSource {
  /// Obtiene diagnósticos agrupados por creador.
  Future<List<DiagnosticoGrupoModel>> obtenerPorCreador(int usuarioCreaId);

  /// Confirma o descarta la valvulopatía de un diagnóstico.
  /// Marca automáticamente `verificado = true`.
  Future<DiagnosticoModel> confirmarValvulopatia({
    required int diagnosticoId,
    required bool valvulopatia,
  });

  /// Crea un nuevo diagnóstico: POST /api/diagnostics
  Future<DiagnosticoModel> crearDiagnostico({
    required int institucionId,
    required bool esNormal,
    required int edad,
    required String genero,
    required double altura,
    required double peso,
    required String diagnosticoTexto,
    required int focoId,
    int? categoriaAnomaliaId,
    required int usuarioCreaId,
    bool? valvulopatia,
    List<int> enfermedadesBaseIds,
  });
}

class DiagnosticoRemoteDataSourceImpl implements DiagnosticoRemoteDataSource {
  final http.Client httpClient;

  DiagnosticoRemoteDataSourceImpl({required this.httpClient});

  Map<String, String> get _authHeaders {
    final token = SessionService.instance.token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<DiagnosticoGrupoModel>> obtenerPorCreador(
      int usuarioCreaId) async {
    final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.diagnosticosByCreator}?usuarioCreaId=$usuarioCreaId');

    late http.Response response;
    try {
      response = await httpClient
          .get(url, headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw NetworkException('No se pudo conectar con el servidor: $e');
    }

    if (response.statusCode == 401) {
      throw ServerException('Sesión expirada. Inicia sesión nuevamente.');
    }

    if (response.statusCode != 200) {
      throw ServerException(
          'Error al obtener diagnósticos (${response.statusCode})');
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List? ?? [];
      return data
          .map((g) => DiagnosticoGrupoModel.fromJson(g as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Error al parsear diagnósticos: $e');
    }
  }

  @override
  Future<DiagnosticoModel> confirmarValvulopatia({
    required int diagnosticoId,
    required bool valvulopatia,
  }) async {
    final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.confirmValvulopatia(diagnosticoId)}');

    late http.Response response;
    try {
      response = await httpClient
          .patch(
            url,
            headers: _authHeaders,
            body: jsonEncode({'valvulopatia': valvulopatia}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw NetworkException('No se pudo conectar con el servidor: $e');
    }

    if (response.statusCode == 401) {
      throw ServerException('Sesión expirada. Inicia sesión nuevamente.');
    }

    if (response.statusCode != 200) {
      final body = _tryDecodeBody(response);
      final message = body is Map
          ? (body['message'] ?? 'Error desconocido').toString()
          : 'Error del servidor';
      throw ServerException(
          'Error al confirmar valvulopatía (${response.statusCode}): $message');
    }

    // La respuesta contiene el resumen, pero reconstruimos el modelo
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return DiagnosticoModel(
      id: body['id'] as int,
      verificado: body['verificado'] as bool? ?? true,
      valvulopatia: body['valvulopatia'] as bool? ?? valvulopatia,
      creadoEn: body['creadoEn'] as String?,
    );
  }

  dynamic _tryDecodeBody(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  @override
  Future<DiagnosticoModel> crearDiagnostico({
    required int institucionId,
    required bool esNormal,
    required int edad,
    required String genero,
    required double altura,
    required double peso,
    required String diagnosticoTexto,
    required int focoId,
    int? categoriaAnomaliaId,
    required int usuarioCreaId,
    bool? valvulopatia,
    List<int> enfermedadesBaseIds = const [],
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.diagnostics}');

    final body = {
      'institucionId': institucionId,
      'esNormal': esNormal,
      'edad': edad,
      'genero': genero,
      'altura': altura,
      'peso': peso,
      'diagnosticoTexto': diagnosticoTexto,
      'focoId': focoId,
      'categoriaAnomaliaId': categoriaAnomaliaId,
      'usuarioCreaId': usuarioCreaId,
      'verificado': false,
      'valvulopatia': valvulopatia ?? false,
      'enfermedadesBaseIds': enfermedadesBaseIds,
    };

    late http.Response response;
    try {
      response = await httpClient
          .post(
            url,
            headers: _authHeaders,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw NetworkException('No se pudo conectar con el servidor: $e');
    }

    if (response.statusCode == 401) {
      throw ServerException('Sesión expirada. Inicia sesión nuevamente.');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      final respBody = _tryDecodeBody(response);
      // Incluir detalles de validación en el mensaje de error
      String message;
      if (respBody is Map) {
        final msg = (respBody['message'] ?? 'Error desconocido').toString();
        final errors =
            respBody['errors'] ?? respBody['details'] ?? respBody['data'];
        message = errors != null
            ? '$msg | Detalles: $errors'
            : '$msg | Body: $respBody';
      } else {
        message = 'Error del servidor: $respBody';
      }
      throw ServerException(
          'Error al crear diagnóstico (${response.statusCode}): $message');
    }

    final respBody = jsonDecode(response.body) as Map<String, dynamic>;
    return DiagnosticoModel.fromJson(respBody);
  }
}
