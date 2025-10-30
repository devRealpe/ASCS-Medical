// lib/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

// Data Sources
import 'data/datasources/local/config_local_datasource.dart';
import 'data/datasources/remote/aws_s3_remote_datasource.dart';

// Repositories
import 'data/repositories/config_repository_impl.dart';
import 'data/repositories/formulario_repository_impl.dart';
import 'domain/repositories/config_repository.dart';
import 'domain/repositories/formulario_repository.dart';

// Use Cases
import 'domain/usecases/config/obtener_hospitales_usecase.dart';
import 'domain/usecases/config/obtener_consultorios_por_hospital_usecase.dart';
import 'domain/usecases/config/obtener_focos_usecase.dart';
import 'domain/usecases/enviar_formulario_usecase.dart';
import 'domain/usecases/generar_nombre_archivo_usecase.dart';

// BLoCs
import 'presentation/blocs/config/config_bloc.dart';
import 'presentation/blocs/formulario/formulario_bloc.dart';
import 'presentation/blocs/upload/upload_bloc.dart';

final sl = GetIt.instance;

/// Inicializa todas las dependencias de la aplicación
Future<void> init() async {
  //! Features - Config

  // BLoC
  sl.registerFactory(
    () => ConfigBloc(
      configRepository: sl(),
      obtenerConsultoriosUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => ObtenerHospitalesUseCase(repository: sl()));
  sl.registerLazySingleton(
    () => ObtenerConsultoriosPorHospitalUseCase(repository: sl()),
  );
  sl.registerLazySingleton(() => ObtenerFocosUseCase(repository: sl()));

  // Repository
  sl.registerLazySingleton<ConfigRepository>(
    () => ConfigRepositoryImpl(localDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<ConfigLocalDataSource>(
    () => ConfigLocalDataSourceImpl(),
  );

  //! Features - Formulario

  // BLoC
  sl.registerFactory(
    () => FormularioBloc(
      enviarFormularioUseCase: sl(),
      generarNombreArchivoUseCase: sl(),
    ),
  );

  sl.registerFactory(() => UploadBloc());

  // Use Cases
  sl.registerLazySingleton(() => EnviarFormularioUseCase(repository: sl()));
  sl.registerLazySingleton(() => GenerarNombreArchivoUseCase(repository: sl()));

  // Repository
  sl.registerLazySingleton<FormularioRepository>(
    () => FormularioRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<AwsS3RemoteDataSource>(
    () => AwsS3RemoteDataSourceImpl(),
  );

  //! Core
  // (Actualmente no hay dependencias core para registrar)

  //! External
  sl.registerLazySingleton(() => http.Client());
}
