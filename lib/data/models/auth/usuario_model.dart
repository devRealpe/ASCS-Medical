// lib/data/models/auth/usuario_model.dart

import 'package:equatable/equatable.dart';

/// Modelo del usuario autenticado / registrado
class UsuarioModel extends Equatable {
  final int? id;
  final String nombreUsuario;
  final String email;

  const UsuarioModel({
    this.id,
    required this.nombreUsuario,
    required this.email,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] as int?,
      nombreUsuario: json['nombreUsuario'] as String? ??
          json['nombre_usuario'] as String? ??
          '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'nombreUsuario': nombreUsuario,
        'email': email,
      };

  @override
  List<Object?> get props => [id, nombreUsuario, email];
}
