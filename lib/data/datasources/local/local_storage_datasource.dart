// lib/data/datasources/local/local_storage_datasource.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/storage_preference_service.dart';

/// Contrato para almacenamiento local
abstract class LocalStorageDataSource {
  Future<String> guardarAudioLocal({
    required File audioFile,
    required String fileName,
  });

  Future<void> guardarMetadataLocal({
    required Map<String, dynamic> metadata,
    required String fileName,
  });

  Future<String> generarAudioIdUnicoLocal();

  Future<Directory> obtenerDirectorioRepositorio();
}

/// Implementación de almacenamiento local
class LocalStorageDataSourceImpl implements LocalStorageDataSource {
  static const String _repositorioDir = 'repositorio';
  static const String _audiosDir = 'audios';
  static const String _jsonDir = 'audios-json';
  static const int _maxUuidAttempts = 10;

  final _uuid = const Uuid();

  /// Determina si la ruta apunta a almacenamiento externo (fuera del sandbox).
  bool _esRutaExterna(String path) {
    return path.startsWith('/storage/') ||
        path.startsWith('/sdcard/') ||
        path.startsWith('/mnt/');
  }

  /// Obtiene el directorio base:
  /// - Si el usuario configuró una ruta personalizada y existe → la usa
  ///   (previa verificación de permisos si es externa).
  /// - Si no → usa getApplicationDocumentsDirectory() como fallback.
  Future<Directory> _obtenerDirectorioBase() async {
    final customPath = await StoragePreferenceService.getLocalStoragePath();

    if (customPath != null && customPath.isNotEmpty) {
      // Si la ruta es externa, verificar/solicitar permisos primero
      if (_esRutaExterna(customPath)) {
        final hasPermission = await PermissionService.hasStoragePermission();
        if (!hasPermission) {
          final result = await PermissionService.requestStoragePermission();
          if (!result.granted) {
            throw FileException(
              result.errorMessage ??
                  'Sin permiso para acceder al almacenamiento externo. '
                      'Cambia la carpeta o usa el almacenamiento interno.',
            );
          }
        }
      }

      final customDir = Directory(customPath);
      if (await customDir.exists()) {
        return customDir;
      }

      // Intentar crear la carpeta si no existe (para rutas donde sí tenemos permiso)
      try {
        await customDir.create(recursive: true);
        return customDir;
      } catch (e) {
        // Si falla la creación, limpiar y usar la por defecto
        await StoragePreferenceService.clearLocalStoragePath();
        throw FileException(
          'No se pudo acceder a la carpeta seleccionada: $customPath\n'
          'Se usará el almacenamiento interno. '
          'Selecciona una carpeta diferente en la configuración.',
        );
      }
    }

    return await getApplicationDocumentsDirectory();
  }

  @override
  Future<Directory> obtenerDirectorioRepositorio() async {
    final baseDir = await _obtenerDirectorioBase();
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

      // Usar writeAsBytes en lugar de copy para mayor compatibilidad
      // entre particiones de Android (evita el errno=1 cross-partition)
      final bytes = await audioFile.readAsBytes();
      await destino.writeAsBytes(bytes, flush: true);

      return destino.path;
    } on FileException {
      rethrow;
    } catch (e) {
      // Mejorar el mensaje de error para orientar al usuario
      final msg = e.toString();
      if (msg.contains('Operation not permitted') ||
          msg.contains('errno = 1')) {
        throw FileException(
          'Sin permisos para guardar en la carpeta seleccionada.\n'
          'Ve a Configuración de almacenamiento y selecciona '
          'una carpeta diferente, o usa el almacenamiento interno.',
        );
      }
      if (msg.contains('No space left') || msg.contains('errno = 28')) {
        throw const FileException(
          'No hay espacio suficiente en el dispositivo.',
        );
      }
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
    } on FileException {
      rethrow;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Operation not permitted') ||
          msg.contains('errno = 1')) {
        throw const FileException(
          'Sin permisos para guardar en la carpeta seleccionada.',
        );
      }
      throw FileException('Error al guardar metadata localmente: $e');
    }
  }

  @override
  Future<String> generarAudioIdUnicoLocal() async {
    final dirAudios = await _obtenerDirAudios();

    for (int i = 0; i < _maxUuidAttempts; i++) {
      final candidateId =
          _uuid.v4().replaceAll('-', '').substring(0, 12).toUpperCase();
      final existe = await _idExisteLocalmente(candidateId, dirAudios);
      if (!existe) {
        return candidateId;
      }
    }

    return _uuid.v4().replaceAll('-', '').toUpperCase();
  }

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
