// lib/presentation/blocs/auth/auth_event.dart

import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class RegistrarUsuarioEvent extends AuthEvent {
  final String nombreUsuario;
  final String email;
  final String contrasena;

  const RegistrarUsuarioEvent({
    required this.nombreUsuario,
    required this.email,
    required this.contrasena,
  });

  @override
  List<Object?> get props => [nombreUsuario, email, contrasena];
}

class LoginUsuarioEvent extends AuthEvent {
  final String nombreUsuario;
  final String contrasena;

  const LoginUsuarioEvent({
    required this.nombreUsuario,
    required this.contrasena,
  });

  @override
  List<Object?> get props => [nombreUsuario, contrasena];
}

class ResetAuthEvent extends AuthEvent {}

class LogoutEvent extends AuthEvent {}
