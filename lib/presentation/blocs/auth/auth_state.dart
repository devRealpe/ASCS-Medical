// lib/presentation/blocs/auth/auth_state.dart

import 'package:equatable/equatable.dart';
import '../../../data/models/auth/usuario_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthRegistradoExitosamente extends AuthState {
  final UsuarioModel usuario;
  const AuthRegistradoExitosamente(this.usuario);

  @override
  List<Object?> get props => [usuario];
}

class AuthError extends AuthState {
  final String mensaje;
  const AuthError(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}
