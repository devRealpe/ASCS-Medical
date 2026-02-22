// lib/core/services/permission_service.dart

import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Resultado de la solicitud de permisos
class PermissionResult {
  final bool granted;
  final String? errorMessage;

  const PermissionResult({required this.granted, this.errorMessage});
}

/// Servicio para gestionar permisos de almacenamiento
class PermissionService {
  PermissionService._();

  /// Solicita los permisos necesarios para escribir en almacenamiento externo.
  /// Retorna [PermissionResult] indicando si se concedió o no.
  static Future<PermissionResult> requestStoragePermission() async {
    // Solo aplica en Android
    if (!Platform.isAndroid) {
      return const PermissionResult(granted: true);
    }

    // Android 11+ (API 30+): necesitamos MANAGE_EXTERNAL_STORAGE
    // Android 10  (API 29):  alcanza con WRITE_EXTERNAL_STORAGE
    // Android 9-  (API 28-): WRITE_EXTERNAL_STORAGE es suficiente

    final sdkVersion = await _getAndroidSdkVersion();

    if (sdkVersion >= 30) {
      return await _requestManageExternalStorage();
    } else {
      return await _requestWriteExternalStorage();
    }
  }

  /// Verifica si ya se tienen los permisos necesarios (sin solicitarlos).
  static Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final sdkVersion = await _getAndroidSdkVersion();

    if (sdkVersion >= 30) {
      return await Permission.manageExternalStorage.isGranted;
    } else {
      return await Permission.storage.isGranted;
    }
  }

  /// Abre la configuración de la app para que el usuario conceda permisos
  /// manualmente (útil cuando los permisos fueron denegados permanentemente).
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  // ─── Privados ─────────────────────────────────────────────────────────────

  static Future<PermissionResult> _requestManageExternalStorage() async {
    var status = await Permission.manageExternalStorage.status;

    if (status.isGranted) {
      return const PermissionResult(granted: true);
    }

    if (status.isPermanentlyDenied) {
      return const PermissionResult(
        granted: false,
        errorMessage: 'Permiso de almacenamiento denegado permanentemente. '
            'Ve a Configuración > Aplicaciones > ASCS > Permisos '
            'y habilita "Archivos y medios".',
      );
    }

    status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      return const PermissionResult(granted: true);
    }

    return PermissionResult(
      granted: false,
      errorMessage: status.isPermanentlyDenied
          ? 'Permiso denegado permanentemente. Habilítalo manualmente en '
              'Configuración > Aplicaciones > ASCS > Permisos.'
          : 'Permiso de almacenamiento externo no concedido. '
              'Es necesario para guardar archivos en la carpeta seleccionada.',
    );
  }

  static Future<PermissionResult> _requestWriteExternalStorage() async {
    var status = await Permission.storage.status;

    if (status.isGranted) {
      return const PermissionResult(granted: true);
    }

    if (status.isPermanentlyDenied) {
      return const PermissionResult(
        granted: false,
        errorMessage: 'Permiso de almacenamiento denegado permanentemente. '
            'Ve a Configuración > Aplicaciones > ASCS > Permisos '
            'y habilita "Almacenamiento".',
      );
    }

    status = await Permission.storage.request();

    return status.isGranted
        ? const PermissionResult(granted: true)
        : PermissionResult(
            granted: false,
            errorMessage: status.isPermanentlyDenied
                ? 'Permiso denegado permanentemente. Habilítalo manualmente.'
                : 'Permiso de almacenamiento no concedido.',
          );
  }

  /// Obtiene la versión del SDK de Android
  static Future<int> _getAndroidSdkVersion() async {
    try {
      // En Android, podemos leer la propiedad del sistema
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(result.stdout.toString().trim()) ?? 30;
    } catch (_) {
      return 30; // Asumir Android 11+ si no podemos detectar
    }
  }
}
