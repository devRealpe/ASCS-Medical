// lib/core/services/storage_preference_service.dart

import 'package:shared_preferences/shared_preferences.dart';

/// Modos de almacenamiento disponibles
enum StorageMode { local, cloud }

/// Servicio para gestionar la preferencia de almacenamiento
class StoragePreferenceService {
  StoragePreferenceService._();

  static const String _storageModeKey = 'storage_mode';
  static const String _localPathKey = 'local_storage_path';
  static const String _correctPassword = '9vT\$Q7!mZ@4rL#8xP2^kW&6aN';

  /// Obtiene el modo de almacenamiento actual (default: local)
  static Future<StorageMode> getStorageMode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageModeKey);
    if (stored == StorageMode.cloud.name) {
      return StorageMode.cloud;
    }
    return StorageMode.local;
  }

  /// Verifica si la contraseña es correcta
  static bool verifyPassword(String password) {
    return password == _correctPassword;
  }

  /// Cambia el modo de almacenamiento (requiere contraseña)
  static Future<bool> setStorageMode(StorageMode mode, String password) async {
    if (!verifyPassword(password)) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageModeKey, mode.name);
    return true;
  }

  /// Obtiene la ruta personalizada para almacenamiento local
  /// Retorna null si no se ha configurado (usará la ruta por defecto)
  static Future<String?> getLocalStoragePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localPathKey);
  }

  /// Guarda la ruta personalizada para almacenamiento local
  /// No requiere contraseña — solo es visible/editable cuando el modo ya es local
  static Future<void> setLocalStoragePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localPathKey, path);
  }

  /// Elimina la ruta personalizada (vuelve a usar la ruta por defecto)
  static Future<void> clearLocalStoragePath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localPathKey);
  }

  /// Obtiene la etiqueta legible del modo
  static String getModeLabel(StorageMode mode) {
    switch (mode) {
      case StorageMode.local:
        return 'Almacenamiento Local';
      case StorageMode.cloud:
        return 'Nube (AWS S3)';
    }
  }
}
