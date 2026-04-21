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
    double? precision,
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
    } catch (_) {
      throw const NetworkException('No se pudo conectar con el servidor');
    }

    if (response.statusCode == 401) {
      throw ServerException('Sesión expirada. Inicia sesión nuevamente.');
    }

    if (response.statusCode != 200) {
      throw const ServerException(
        'No pudimos cargar los diagnósticos en este momento.',
      );
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List? ?? [];
      return data
          .map((g) => DiagnosticoGrupoModel.fromJson(g as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const ServerException(
        'No pudimos interpretar la respuesta del servidor.',
      );
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
    } catch (_) {
      throw const NetworkException('No se pudo conectar con el servidor');
    }

    if (response.statusCode == 401) {
      throw ServerException('Sesión expirada. Inicia sesión nuevamente.');
    }

    if (response.statusCode != 200) {
      throw const ServerException(
        'No pudimos actualizar el diagnóstico en este momento.',
      );
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

  @override
  Future<DiagnosticoModel> crearDiagnostico({
    required int institucionId,
    required bool esNormal,
    required int edad,
    required String genero,
    required double altura,
    required double peso,
    double? precision,
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
      if (precision != null) 'precision': precision,
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
    } catch (_) {
      throw const NetworkException('No se pudo conectar con el servidor');
    }

    if (response.statusCode == 401) {
      throw ServerException('Sesión expirada. Inicia sesión nuevamente.');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw const ServerException(
        'No pudimos guardar el diagnóstico en el servidor.',
      );
    }

    final respBody = jsonDecode(response.body) as Map<String, dynamic>;
    return DiagnosticoModel.fromJson(respBody);
  }
}
