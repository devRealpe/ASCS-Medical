// lib/data/datasources/local/local_storage_datasource.dart

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/storage_preference_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Resultado de extracción del ZIP
// ─────────────────────────────────────────────────────────────────────────────

/// Contiene los 4 archivos WAV extraídos del ZIP, clasificados por tipo.
class ZipAudioFiles {
  /// Sonido principal (sin sufijo ECG)
  final File principal;

  /// Sonido ECG (sufijo _ECG)
  final File ecg;

  /// Sonido ECG_1 (sufijo _ECG_1)
  final File ecg1;

  /// Sonido ECG_2 (sufijo _ECG_2)
  final File ecg2;

  const ZipAudioFiles({
    required this.principal,
    required this.ecg,
    required this.ecg1,
    required this.ecg2,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Contrato
// ─────────────────────────────────────────────────────────────────────────────

/// Contrato para almacenamiento local
abstract class LocalStorageDataSource {
  /// Extrae los 4 archivos WAV del ZIP y los clasifica por tipo.
  Future<ZipAudioFiles> extraerAudiosDeZip(File zipFile);

  /// Guarda los 4 archivos WAV en sus carpetas correspondientes y devuelve
  /// un mapa con los nombres finales asignados a cada uno.
  ///
  /// Carpetas creadas dentro de [repositorio/]:
  ///   - Audios/    → archivo principal (sin sufijo ECG)
  ///   - ECG/       → archivo con sufijo _ECG
  ///   - ECG_1/     → archivo con sufijo _ECG_1
  ///   - ECG_2/     → archivo con sufijo _ECG_2
  ///
  /// Retorna un mapa:
  /// ```dart
  /// {
  ///   'principal': 'SC_20240101_0101_01_N_ABCD12345678.wav',
  ///   'ecg':       'SC_20240101_0101_01_N_ABCD12345678_ECG.wav',
  ///   'ecg1':      'SC_20240101_0101_01_N_ABCD12345678_ECG_1.wav',
  ///   'ecg2':      'SC_20240101_0101_01_N_ABCD12345678_ECG_2.wav',
  /// }
  /// ```
  Future<Map<String, String>> guardarAudiosLocales({
    required ZipAudioFiles audios,
    required String
        baseFileName, // Nombre base SIN extensión, ej: SC_20240101_0101_01_N_ABCD12345678
  });

  Future<void> guardarMetadataLocal({
    required Map<String, dynamic> metadata,
    required String baseFileName, // Nombre base SIN .wav
  });

  Future<String> generarAudioIdUnicoLocal();

  Future<Directory> obtenerDirectorioRepositorio();
}

// ─────────────────────────────────────────────────────────────────────────────
// Implementación
// ─────────────────────────────────────────────────────────────────────────────

/// Implementación de almacenamiento local
class LocalStorageDataSourceImpl implements LocalStorageDataSource {
  static const String _repositorioDir = 'repositorio';

  // Carpetas de destino para cada tipo de audio
  static const String _audiosDir = 'Audios';
  static const String _ecgDir = 'ECG';
  static const String _ecg1Dir = 'ECG_1';
  static const String _ecg2Dir = 'ECG_2';

  // Carpeta para los JSON de metadata
  static const String _jsonDir = 'audios-json';

  static const int _maxUuidAttempts = 10;

  final _uuid = const Uuid();

  // ── Helpers: directorio base ──────────────────────────────────────────────

  bool _esRutaExterna(String path) =>
      path.startsWith('/storage/') ||
      path.startsWith('/sdcard/') ||
      path.startsWith('/mnt/');

  Future<Directory> _obtenerDirectorioBase() async {
    final customPath = await StoragePreferenceService.getLocalStoragePath();

    if (customPath != null && customPath.isNotEmpty) {
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
      if (await customDir.exists()) return customDir;

      try {
        await customDir.create(recursive: true);
        return customDir;
      } catch (e) {
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
    if (!await repoDir.exists()) await repoDir.create(recursive: true);
    return repoDir;
  }

  /// Crea (si no existe) y retorna un subdirectorio dentro de repositorio/
  Future<Directory> _obtenerSubdir(String nombre) async {
    final repoDir = await obtenerDirectorioRepositorio();
    final dir = Directory('${repoDir.path}/$nombre');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ── ZIP ───────────────────────────────────────────────────────────────────

  @override
  Future<ZipAudioFiles> extraerAudiosDeZip(File zipFile) async {
    if (!zipFile.existsSync()) {
      throw const FileException('El archivo ZIP no existe');
    }

    // Extraer en directorio temporal
    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory(
        '${tempDir.path}/ascs_zip_${DateTime.now().millisecondsSinceEpoch}');
    await extractDir.create(recursive: true);

    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (!file.isFile) continue;
        final outPath = '${extractDir.path}/${file.name}';
        // Crear subdirectorios si los hay dentro del ZIP
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }

      return _clasificarAudios(extractDir);
    } catch (e) {
      // Limpiar directorio temporal si falla
      if (await extractDir.exists()) await extractDir.delete(recursive: true);
      if (e is FileException) rethrow;
      throw FileException('Error al extraer el archivo ZIP: $e');
    }
  }

  /// Clasifica los archivos WAV extraídos según su sufijo:
  ///   sin sufijo ECG → principal
  ///   _ECG           → ecg
  ///   _ECG_1         → ecg1
  ///   _ECG_2         → ecg2
  ZipAudioFiles _clasificarAudios(Directory dir) {
    final wavFiles = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.wav'))
        .toList();

    if (wavFiles.length != 4) {
      throw FileException(
        'El ZIP debe contener exactamente 4 archivos WAV. '
        'Se encontraron: ${wavFiles.length}',
      );
    }

    File? principal, ecg, ecg1, ecg2;

    for (final f in wavFiles) {
      final name = _basenameWithoutExtension(f.path).toUpperCase();

      if (name.endsWith('_ECG_2')) {
        ecg2 = f;
      } else if (name.endsWith('_ECG_1')) {
        ecg1 = f;
      } else if (name.endsWith('_ECG')) {
        ecg = f;
      } else {
        principal = f;
      }
    }

    if (principal == null || ecg == null || ecg1 == null || ecg2 == null) {
      throw const FileException(
        'No se pudieron identificar los 4 tipos de audio en el ZIP. '
        'Verifica que contenga archivos con sufijos: sin sufijo, _ECG, _ECG_1, _ECG_2.',
      );
    }

    return ZipAudioFiles(
      principal: principal,
      ecg: ecg,
      ecg1: ecg1,
      ecg2: ecg2,
    );
  }

  // ── Guardar audios ────────────────────────────────────────────────────────

  @override
  Future<Map<String, String>> guardarAudiosLocales({
    required ZipAudioFiles audios,
    required String baseFileName,
  }) async {
    final dirPrincipal = await _obtenerSubdir(_audiosDir);
    final dirEcg = await _obtenerSubdir(_ecgDir);
    final dirEcg1 = await _obtenerSubdir(_ecg1Dir);
    final dirEcg2 = await _obtenerSubdir(_ecg2Dir);

    final namePrincipal = '$baseFileName.wav';
    final nameEcg = '${baseFileName}_ECG.wav';
    final nameEcg1 = '${baseFileName}_ECG_1.wav';
    final nameEcg2 = '${baseFileName}_ECG_2.wav';

    await _copiarArchivo(
        audios.principal, '${dirPrincipal.path}/$namePrincipal');
    await _copiarArchivo(audios.ecg, '${dirEcg.path}/$nameEcg');
    await _copiarArchivo(audios.ecg1, '${dirEcg1.path}/$nameEcg1');
    await _copiarArchivo(audios.ecg2, '${dirEcg2.path}/$nameEcg2');

    return {
      'principal': namePrincipal,
      'ecg': nameEcg,
      'ecg1': nameEcg1,
      'ecg2': nameEcg2,
    };
  }

  /// Copia bytes de [origen] a [destinoPath] (compatible cross-partition en Android).
  Future<void> _copiarArchivo(File origen, String destinoPath) async {
    try {
      final bytes = await origen.readAsBytes();
      await File(destinoPath).writeAsBytes(bytes, flush: true);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Operation not permitted') ||
          msg.contains('errno = 1')) {
        throw const FileException(
          'Sin permisos para guardar en la carpeta seleccionada.\n'
          'Ve a Configuración de almacenamiento y selecciona '
          'una carpeta diferente, o usa el almacenamiento interno.',
        );
      }
      if (msg.contains('No space left') || msg.contains('errno = 28')) {
        throw const FileException(
            'No hay espacio suficiente en el dispositivo.');
      }
      throw FileException('Error al guardar audio localmente: $e');
    }
  }

  // ── Metadata JSON ─────────────────────────────────────────────────────────

  @override
  Future<void> guardarMetadataLocal({
    required Map<String, dynamic> metadata,
    required String baseFileName,
  }) async {
    try {
      final dirJson = await _obtenerSubdir(_jsonDir);
      final archivo = File('${dirJson.path}/$baseFileName.json');
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
            'Sin permisos para guardar en la carpeta seleccionada.');
      }
      throw FileException('Error al guardar metadata localmente: $e');
    }
  }

  // ── ID único ──────────────────────────────────────────────────────────────

  @override
  Future<String> generarAudioIdUnicoLocal() async {
    final dirPrincipal = await _obtenerSubdir(_audiosDir);

    for (int i = 0; i < _maxUuidAttempts; i++) {
      final candidateId =
          _uuid.v4().replaceAll('-', '').substring(0, 12).toUpperCase();
      final existe = await _idExisteLocalmente(candidateId, dirPrincipal);
      if (!existe) return candidateId;
    }

    return _uuid.v4().replaceAll('-', '').toUpperCase();
  }

  Future<bool> _idExisteLocalmente(String audioId, Directory dir) async {
    try {
      if (!await dir.exists()) return false;
      final archivos = await dir.list().toList();
      return archivos.any((f) => f.path.contains(audioId));
    } catch (_) {
      return false;
    }
  }

  // ── Utilidades ────────────────────────────────────────────────────────────

  String _basenameWithoutExtension(String path) {
    final base = path.replaceAll('\\', '/').split('/').last;
    final dotIndex = base.lastIndexOf('.');
    return dotIndex == -1 ? base : base.substring(0, dotIndex);
  }
}
