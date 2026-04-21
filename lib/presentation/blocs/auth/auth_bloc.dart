// lib/presentation/blocs/auth/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/user_friendly_error_mapper.dart';
import '../../../core/services/session_service.dart';
import '../../../data/datasources/remote/auth_remote_datasource.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRemoteDataSource authDataSource;

  AuthBloc({required this.authDataSource}) : super(AuthInitial()) {
    on<RegistrarUsuarioEvent>(_onRegistrar);
    on<LoginUsuarioEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<ResetAuthEvent>(_onReset);
  }

  Future<void> _onRegistrar(
    RegistrarUsuarioEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final usuario = await authDataSource.registrar(
        nombreUsuario: event.nombreUsuario,
        email: event.email,
        contrasena: event.contrasena,
      );
      emit(AuthRegistradoExitosamente(usuario));
    } on NetworkException catch (e) {
      emit(AuthError(UserFriendlyErrorMapper.fromError(e)));
    } on ServerException catch (e) {
      emit(AuthError(UserFriendlyErrorMapper.fromError(e)));
    } catch (_) {
      emit(const AuthError(UserFriendlyErrorMapper.unexpectedErrorMessage));
    }
  }

  Future<void> _onLogin(
    LoginUsuarioEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final usuario = await authDataSource.login(
        nombreUsuario: event.nombreUsuario,
        contrasena: event.contrasena,
      );
      await SessionService.instance.save(usuario);
      emit(AuthLogueadoExitosamente(usuario));
    } on NetworkException catch (e) {
      emit(AuthError(UserFriendlyErrorMapper.fromError(e)));
    } on ServerException catch (e) {
      emit(AuthError(UserFriendlyErrorMapper.fromError(e)));
    } catch (_) {
      emit(const AuthError(UserFriendlyErrorMapper.unexpectedErrorMessage));
    }
  }

  void _onReset(ResetAuthEvent event, Emitter<AuthState> emit) {
    emit(AuthInitial());
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    await SessionService.instance.clear();
    emit(AuthInitial());
  }
}
