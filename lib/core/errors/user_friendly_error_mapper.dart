import 'exceptions.dart';
import 'failures.dart';

class UserFriendlyErrorMapper {
  UserFriendlyErrorMapper._();

  static const String networkConnectionMessage =
      'Por favor verifica tu conexión a internet e intenta de nuevo.';
  static const String slowConnectionMessage =
      'La conexión está tardando demasiado. Por favor intenta de nuevo.';
  static const String serverUnavailableMessage =
      '¡No eres tú, somos nosotros! 🩺\n\n'
      'Nuestro servidor no está disponible en este momento. '
      'Por favor intenta de nuevo en unos minutos.';
  static const String unexpectedErrorMessage =
      '¡No eres tú, somos nosotros! 🩺\n\n'
      'Algo salió mal. Por favor intenta de nuevo.';
  static const String sessionExpiredMessage =
      'Tu sesión expiró. Inicia sesión nuevamente.';
  static const String fileProcessingMessage =
      'No pudimos procesar el archivo.\n'
      'Verifica que el archivo sea válido e intenta de nuevo.';
  static const String storageOperationMessage =
      'No pudimos completar el envío de archivos. Por favor intenta de nuevo.';
  static const String permissionMessage =
      'No tienes permisos para completar esta acción.';
  static const String validationMessage =
      'Los datos ingresados no son válidos.\n'
      'Revisa los campos e intenta de nuevo.';
  static const String configLoadMessage =
      'No pudimos cargar la configuración.\n'
      'Por favor verifica tu conexión e intenta de nuevo.';

  static String fromFailure(Failure failure, {String? fallback}) {
    if (failure is NetworkFailure) {
      return fromMessage(
        failure.message,
        fallback: networkConnectionMessage,
      );
    }
    if (failure is ServerFailure) {
      return fromMessage(
        failure.message,
        fallback: fallback ?? serverUnavailableMessage,
      );
    }
    if (failure is StorageFailure) {
      return fromMessage(
        failure.message,
        fallback: storageOperationMessage,
      );
    }
    if (failure is FileFailure) {
      return fromMessage(
        failure.message,
        fallback: fileProcessingMessage,
      );
    }
    if (failure is ValidationFailure) {
      return fromMessage(
        failure.message,
        fallback: validationMessage,
      );
    }
    if (failure is PermissionFailure) {
      return fromMessage(
        failure.message,
        fallback: permissionMessage,
      );
    }
    if (failure is CacheFailure) {
      return fromMessage(
        failure.message,
        fallback: fallback ?? configLoadMessage,
      );
    }
    if (failure is UnexpectedFailure) {
      return fallback ?? unexpectedErrorMessage;
    }
    return fromMessage(
      failure.message,
      fallback: fallback ?? unexpectedErrorMessage,
    );
  }

  static String fromError(Object error, {String? fallback}) {
    if (error is NetworkException) {
      return fromMessage(
        error.message,
        fallback: networkConnectionMessage,
      );
    }
    if (error is ServerException) {
      return fromMessage(
        error.message,
        fallback: fallback ?? serverUnavailableMessage,
      );
    }
    if (error is StorageException) {
      return fromMessage(
        error.message,
        fallback: storageOperationMessage,
      );
    }
    if (error is FileException) {
      return fromMessage(
        error.message,
        fallback: fileProcessingMessage,
      );
    }
    if (error is ValidationException) {
      return fromMessage(
        error.message,
        fallback: validationMessage,
      );
    }
    if (error is CacheException) {
      return fromMessage(
        error.message,
        fallback: fallback ?? configLoadMessage,
      );
    }
    return fallback ?? unexpectedErrorMessage;
  }

  static String fromMessage(String raw, {String? fallback}) {
    final message = raw.trim();
    final normalized = message.toLowerCase();

    if (message.isEmpty) return fallback ?? unexpectedErrorMessage;

    if (normalized.contains('usuario o contraseña incorrectos')) {
      return 'Usuario o contraseña incorrectos.\n'
          'Verifica tus datos e intenta de nuevo.';
    }
    if (normalized.contains('usuario no encontrado')) {
      return 'No encontramos una cuenta con ese nombre de usuario.';
    }
    if (normalized.contains('ya está registrado') ||
        normalized.contains('correo o usuario') ||
        normalized.contains('already exists')) {
      return 'Ese correo o usuario ya está registrado.\n'
          'Intenta con otro o inicia sesión.';
    }
    if (normalized.contains('sesión expirada') ||
        normalized.contains('sesion expirada') ||
        normalized.contains('inicia sesión nuevamente')) {
      return sessionExpiredMessage;
    }
    if (normalized.contains('datos inválidos') ||
        normalized.contains('dato inválido') ||
        normalized.contains('validation')) {
      return validationMessage;
    }
    if (_isAlreadyFriendly(message)) return message;
    if (_looksLikeTimeout(normalized)) {
      return slowConnectionMessage;
    }
    if (_looksLikeNetwork(normalized)) {
      return networkConnectionMessage;
    }
    if (_looksLikePermission(normalized)) {
      return permissionMessage;
    }
    if (_looksLikeFile(normalized)) {
      return fileProcessingMessage;
    }
    if (_looksLikeStorage(normalized)) {
      return storageOperationMessage;
    }
    if (_looksLikeServer(normalized)) {
      return fallback ?? serverUnavailableMessage;
    }

    return fallback ?? unexpectedErrorMessage;
  }

  static bool _isAlreadyFriendly(String message) {
    final normalized = message.toLowerCase();
    return normalized.startsWith('¡no eres tú') ||
        normalized.startsWith('por favor verifica') ||
        normalized.startsWith('no pudimos') ||
        normalized.startsWith('tu sesión expiró') ||
        normalized.startsWith('usuario o contraseña incorrectos') ||
        normalized.startsWith('no encontramos una cuenta') ||
        normalized.startsWith('ese correo o usuario') ||
        normalized.startsWith('los datos ingresados') ||
        normalized.startsWith('sin permisos') ||
        normalized.startsWith('no hay espacio');
  }

  static bool _looksLikeNetwork(String normalized) {
    return normalized.contains('sin conexión') ||
        normalized.contains('sin conexion') ||
        normalized.contains('no se pudo conectar') ||
        normalized.contains('connection') ||
        normalized.contains('network') ||
        normalized.contains('internet') ||
        normalized.contains('socket') ||
        normalized.contains('host lookup') ||
        normalized.contains('unreachable');
  }

  static bool _looksLikeTimeout(String normalized) {
    return normalized.contains('timeout') ||
        normalized.contains('timed out') ||
        normalized.contains('tiempo agotado') ||
        normalized.contains('tomó demasiado tiempo') ||
        normalized.contains('tardo demasiado') ||
        normalized.contains('conexión muy lenta') ||
        normalized.contains('conexion muy lenta');
  }

  static bool _looksLikePermission(String normalized) {
    return normalized.contains('permiso') ||
        normalized.contains('permission') ||
        normalized.contains('unauthorized') ||
        normalized.contains('forbidden') ||
        normalized.contains('credential') ||
        normalized.contains('auth');
  }

  static bool _looksLikeFile(String normalized) {
    return normalized.contains('archivo') ||
        normalized.contains('zip') ||
        normalized.contains('.wav') ||
        normalized.contains('formato') ||
        normalized.contains('read') ||
        normalized.contains('write') ||
        normalized.contains('espacio');
  }

  static bool _looksLikeStorage(String normalized) {
    return normalized.contains('almacenamiento') ||
        normalized.contains('storage') ||
        normalized.contains('s3') ||
        normalized.contains('subir') ||
        normalized.contains('ingesta');
  }

  static bool _looksLikeServer(String normalized) {
    return normalized.contains('servidor') ||
        normalized.contains('status') ||
        normalized.contains('response') ||
        normalized.contains('body:') ||
        normalized.contains('detalles:') ||
        normalized.contains('http ') ||
        normalized.contains('parsear') ||
        normalized.contains('interpretar') ||
        normalized.contains('error al obtener') ||
        normalized.contains('error al crear') ||
        normalized.contains('error al confirmar');
  }
}
