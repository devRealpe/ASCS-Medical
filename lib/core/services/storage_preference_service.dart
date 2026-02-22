import 'package:shared_preferences/shared_preferences.dart';

/// Modos de almacenamiento disponibles
enum StorageMode { local, cloud }

/// Servicio para gestionar la preferencia de almacenamiento
/// El modo predeterminado es LOCAL
/// Para cambiar el modo se requiere contraseña
class StoragePreferenceService {
  StoragePreferenceService._();

  static const String _storageModeKey = 'storage_mode';
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
  /// Retorna true si el cambio fue exitoso, false si la contraseña es incorrecta
  static Future<bool> setStorageMode(StorageMode mode, String password) async {
    if (!verifyPassword(password)) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageModeKey, mode.name);
    return true;
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
