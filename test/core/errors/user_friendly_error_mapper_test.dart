import 'package:flutter_test/flutter_test.dart';

import 'package:app_ascs/core/errors/exceptions.dart';
import 'package:app_ascs/core/errors/failures.dart';
import 'package:app_ascs/core/errors/user_friendly_error_mapper.dart';

void main() {
  group('UserFriendlyErrorMapper', () {
    test('convierte errores de red técnicos en mensaje entendible', () {
      final message = UserFriendlyErrorMapper.fromError(
        const NetworkException('SocketException: Connection refused'),
      );

      expect(
        message,
        UserFriendlyErrorMapper.networkConnectionMessage,
      );
    });

    test(
        'convierte errores de servidor con detalle técnico en mensaje amigable',
        () {
      final message = UserFriendlyErrorMapper.fromError(
        const ServerException('Error del servidor (500): stacktrace interno'),
      );

      expect(
        message,
        UserFriendlyErrorMapper.serverUnavailableMessage,
      );
    });

    test('mantiene mensajes de autenticación comprensibles para el usuario',
        () {
      final message = UserFriendlyErrorMapper.fromMessage(
        'Usuario o contraseña incorrectos',
      );

      expect(message, contains('Usuario o contraseña incorrectos'));
      expect(message, contains('Verifica tus datos'));
    });

    test('mapea fallos inesperados a un mensaje genérico amigable', () {
      final message = UserFriendlyErrorMapper.fromFailure(
        const UnexpectedFailure('FormatException: Unexpected token'),
      );

      expect(
        message,
        UserFriendlyErrorMapper.unexpectedErrorMessage,
      );
    });

    test('usa fallback de configuración cuando el fallo no es legible', () {
      final message = UserFriendlyErrorMapper.fromFailure(
        const CacheFailure('Respuesta inválida de /api/config'),
        fallback: UserFriendlyErrorMapper.configLoadMessage,
      );

      expect(message, UserFriendlyErrorMapper.configLoadMessage);
    });
  });
}
