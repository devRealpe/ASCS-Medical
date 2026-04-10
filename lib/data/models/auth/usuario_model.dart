// lib/data/models/auth/usuario_model.dart

import 'package:equatable/equatable.dart';

/// Modelo del usuario autenticado / registrado
class UsuarioModel extends Equatable {
  final int? id;
  final String nombreUsuario;
  final String email;
  final String? rol;
  final String? token;

  const UsuarioModel({
    this.id,
    required this.nombreUsuario,
    required this.email,
    this.rol,
    this.token,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] as int?,
      nombreUsuario: json['nombreUsuario'] as String? ??
          json['nombre_usuario'] as String? ??
          '',
      email: json['email'] as String? ?? '',
      rol: json['rol'] as String?,
    );
  }

  /// Crea un UsuarioModel desde la respuesta de login (incluye token)
  factory UsuarioModel.fromLoginJson(Map<String, dynamic> json) {
    final usuarioJson = json['usuario'] as Map<String, dynamic>;
    return UsuarioModel(
      id: usuarioJson['id'] as int?,
      nombreUsuario: usuarioJson['nombreUsuario'] as String? ?? '',
      email: usuarioJson['email'] as String? ?? '',
      rol: usuarioJson['rol'] as String?,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'nombreUsuario': nombreUsuario,
        'email': email,
        if (rol != null) 'rol': rol,
      };

  @override
  List<Object?> get props => [id, nombreUsuario, email, rol, token];
}
