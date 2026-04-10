// lib/data/datasources/remote/config_remote_datasource.dart
//
// Reemplaza config_local_datasource.dart para los datos que ahora vienen
// de la API: focos, categorías de anomalía, instituciones y consultorios.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/config/medical_config_model.dart';
import '../../models/config/hospital_model.dart';
import '../../models/config/consultorio_model.dart';
import '../../models/config/foco_auscultacion_model.dart';
import '../../models/config/categoria_anomalia_model.dart';
import '../../models/config/enfermedad_model.dart';

/// Contrato para el data source remoto de configuración
abstract class ConfigRemoteDataSource {
  Future<MedicalConfigModel> obtenerConfiguracion();
}

/// Implementación que consulta la API REST
class ConfigRemoteDataSourceImpl implements ConfigRemoteDataSource {
  final http.Client httpClient;

  ConfigRemoteDataSourceImpl({required this.httpClient});

  // ── Público ──────────────────────────────────────────────────────────────

  @override
  Future<MedicalConfigModel> obtenerConfiguracion() async {
    // Las 4 peticiones se lanzan en paralelo para mayor velocidad
    final results = await Future.wait([
      _fetchList(ApiConstants.instituciones),
      _fetchList(ApiConstants.focos),
      _fetchList(ApiConstants.categoriasAnomalias),
      _fetchList(ApiConstants.enfermedades),
    ]);

    final institucionesJson = results[0];
    final focosJson = results[1];
    final categoriasJson = results[2];
    final enfermedadesJson = results[3];

    // Construir hospitales desde instituciones
    final hospitales = institucionesJson
        .map((j) => _hospitalFromInstitucion(j))
        .where((h) => h != null)
        .cast<HospitalModel>()
        .toList();

    // Focos
    final focos =
        focosJson.map((j) => FocoAuscultacionModel.fromJson(j)).toList();

    // Categorías
    final categorias =
        categoriasJson.map((j) => CategoriaAnomaliaModel.fromJson(j)).toList();

    // Enfermedades
    final enfermedades =
        enfermedadesJson.map((j) => EnfermedadModel.fromJson(j)).toList();

    // Consultorios: necesitamos una petición por institución activa
    final consultorios = await _fetchTodosConsultorios(institucionesJson);

    return MedicalConfigModel(
      hospitales: hospitales,
      consultorios: consultorios,
      focos: focos,
      categoriasAnomalias: categorias,
      enfermedades: enfermedades,
    );
  }

  // ── Privados ─────────────────────────────────────────────────────────────

  /// Hace GET a [path] y devuelve la lista parseada
  Future<List<Map<String, dynamic>>> _fetchList(String path) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$path');
    late http.Response response;

    try {
      response = await httpClient.get(url, headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw NetworkException('Sin conexión al obtener $path: $e');
    }

    if (response.statusCode != 200) {
      throw ServerException('Error al obtener $path (${response.statusCode})');
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      // Algunos backends envuelven en { data: [...] }
      if (decoded is Map && decoded['data'] is List) {
        return (decoded['data'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      throw CacheException('Respuesta inválida de $path');
    }
  }

  /// Convierte una institución de la API en [HospitalModel]
  /// Devuelve null si la institución está inactiva
  HospitalModel? _hospitalFromInstitucion(Map<String, dynamic> json) {
    final activo = json['activo'] as bool? ?? true;
    if (!activo) return null;

    final id = json['id'];
    return HospitalModel(
      id: id as int?,
      nombre: json['nombre'] as String? ?? '',
      // El código del hospital es el id numérico convertido a String
      codigo: id?.toString() ?? '',
    );
  }

  /// Obtiene los consultorios de todas las instituciones activas
  Future<List<ConsultorioModel>> _fetchTodosConsultorios(
    List<Map<String, dynamic>> instituciones,
  ) async {
    final activas = instituciones.where((i) => i['activo'] as bool? ?? true);

    final futures = activas.map((inst) async {
      final id = inst['id'] as int?;
      if (id == null) return <ConsultorioModel>[];
      return await _fetchConsultoriosPorInstitucion(id);
    });

    final listas = await Future.wait(futures);
    return listas.expand((l) => l).toList();
  }

  /// Obtiene consultorios de UNA institución
  Future<List<ConsultorioModel>> _fetchConsultoriosPorInstitucion(
      int institucionId) async {
    final path = ApiConstants.consultoriosPorInstitucion(institucionId);
    final url = Uri.parse('${ApiConstants.baseUrl}$path');

    try {
      final response = await httpClient.get(url, headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) return [];
      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final lista = decoded['consultorios'] as List? ?? [];

      return lista.map((j) {
        final map = j as Map<String, dynamic>;
        return ConsultorioModel(
          nombre: map['nombre'] as String? ?? '',
          codigo: map['codigo'] as String? ?? (map['id']?.toString() ?? ''),
          codigoHospital: (map['institucionId'] ?? institucionId).toString(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
