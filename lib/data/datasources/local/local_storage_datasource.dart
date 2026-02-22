// lib/data/datasources/local/local_storage_datasource.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/errors/exceptions.dart';

/// Contrato para almacenamiento local
abstract class LocalStorageDataSource {
  /// Copia el archivo de audio al repositorio local
  /// Retorna la ruta local donde fue guardado
  Future<String> guardarAudioLocal({
    required File audioFile,
    required String fileName,
  });

  /// Guarda el metadata JSON localmente
  Future<void> guardarMetadataLocal({
    required Map<String, dynamic> metadata,
    required String fileName,
  });

  /// Genera un ID único verificando que no exista ya localmente
  Future<String> generarAudioIdUnicoLocal();

  /// Obtiene la ruta del directorio local de repositorio
  Future<Directory> obtenerDirectorioRepositorio();
}

/// Implementación de almacenamiento local
class LocalStorageDataSourceImpl implements LocalStorageDataSource {
  static const String _repositorioDir = 'repositorio';
  static const String _audiosDir = 'audios';
  static const String _jsonDir = 'audios-json';
  static const int _maxUuidAttempts = 10;

  final _uuid = const Uuid();

  @override
  Future<Directory> obtenerDirectorioRepositorio() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final repoDir = Directory('${baseDir.path}/$_repositorioDir');
    if (!await repoDir.exists()) {
      await repoDir.create(recursive: true);
    }
    return repoDir;
  }

  Future<Directory> _obtenerDirAudios() async {
    final repoDir = await obtenerDirectorioRepositorio();
    final dir = Directory('${repoDir.path}/$_audiosDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _obtenerDirJson() async {
    final repoDir = await obtenerDirectorioRepositorio();
    final dir = Directory('${repoDir.path}/$_jsonDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  Future<String> guardarAudioLocal({
    required File audioFile,
    required String fileName,
  }) async {
    try {
      if (!audioFile.existsSync()) {
        throw const FileException('El archivo de audio no existe');
      }

      final dirAudios = await _obtenerDirAudios();
      final destino = File('${dirAudios.path}/$fileName');

      // Copiar el archivo al repositorio local
      await audioFile.copy(destino.path);

      return destino.path;
    } on FileException {
      rethrow;
    } catch (e) {
      throw FileException('Error al guardar audio localmente: $e');
    }
  }

  @override
  Future<void> guardarMetadataLocal({
    required Map<String, dynamic> metadata,
    required String fileName,
  }) async {
    try {
      final dirJson = await _obtenerDirJson();
      final fileNameSinExt = fileName.replaceAll('.wav', '');
      final archivo = File('${dirJson.path}/$fileNameSinExt.json');

      await archivo.writeAsString(
        const JsonEncoder.withIndent('  ').convert(metadata),
        flush: true,
      );
    } catch (e) {
      throw FileException('Error al guardar metadata localmente: $e');
    }
  }

  @override
  Future<String> generarAudioIdUnicoLocal() async {
    final dirAudios = await _obtenerDirAudios();

    for (int i = 0; i < _maxUuidAttempts; i++) {
      final candidateId =
          _uuid.v4().replaceAll('-', '').substring(0, 12).toUpperCase();

      // Verificar que no exista ningún archivo con ese ID en audios o json
      final existe = await _idExisteLocalmente(candidateId, dirAudios);
      if (!existe) {
        return candidateId;
      }
    }

    // Fallback con UUID completo si hubo muchas colisiones (extremadamente improbable)
    return _uuid.v4().replaceAll('-', '').toUpperCase();
  }

  /// Verifica si un ID ya existe en el directorio de audios locales
  Future<bool> _idExisteLocalmente(String audioId, Directory dirAudios) async {
    try {
      if (!await dirAudios.exists()) return false;
      final archivos = await dirAudios.list().toList();
      return archivos.any((f) => f.path.contains(audioId));
    } catch (_) {
      return false;
    }
  }
}
