// lib/core/services/session_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/auth/usuario_model.dart';

/// Servicio singleton que almacena el token JWT y los datos del usuario
/// en memoria y en SharedPreferences para persistir la sesión.
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const _keyToken = 'session_token';
  static const _keyUserId = 'session_user_id';
  static const _keyUserName = 'session_user_name';
  static const _keyUserEmail = 'session_user_email';
  static const _keyUserRol = 'session_user_rol';

  String? _token;
  UsuarioModel? _usuario;

  /// Token JWT actual (null si no hay sesión).
  String? get token => _token;

  /// Usuario autenticado actual.
  UsuarioModel? get usuario => _usuario;

  /// ¿Hay una sesión activa?
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  /// Guarda la sesión después de un login exitoso.
  Future<void> save(UsuarioModel usuario) async {
    _token = usuario.token;
    _usuario = usuario;

    final prefs = await SharedPreferences.getInstance();
    if (usuario.token != null) {
      await prefs.setString(_keyToken, usuario.token!);
    }
    if (usuario.id != null) {
      await prefs.setInt(_keyUserId, usuario.id!);
    }
    await prefs.setString(_keyUserName, usuario.nombreUsuario);
    await prefs.setString(_keyUserEmail, usuario.email);
    if (usuario.rol != null) {
      await prefs.setString(_keyUserRol, usuario.rol!);
    }
  }

  /// Restaura la sesión desde SharedPreferences (llamar al iniciar la app).
  Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null || token.isEmpty) return false;

    _token = token;
    _usuario = UsuarioModel(
      id: prefs.getInt(_keyUserId),
      nombreUsuario: prefs.getString(_keyUserName) ?? '',
      email: prefs.getString(_keyUserEmail) ?? '',
      rol: prefs.getString(_keyUserRol),
      token: token,
    );
    return true;
  }

  /// Cierra la sesión y borra los datos.
  Future<void> clear() async {
    _token = null;
    _usuario = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserRol);
  }
}
