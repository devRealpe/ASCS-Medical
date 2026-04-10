// lib/injection_container.dart
//
// CAMBIOS respecto al original:
//   1. Se añade AuthBloc + AuthRemoteDataSource
//   2. ConfigLocalDataSource es reemplazado por ConfigRemoteDataSource
//      (los datos de hospitales/focos/categorías ahora vienen de la API)

import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

// Core
import 'core/network/network_info.dart';

// Data Sources
import 'data/datasources/remote/auth_remote_datasource.dart';
import 'data/datasources/remote/config_remote_datasource.dart'; // ← NUEVO
import 'data/datasources/local/local_storage_datasource.dart';
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
import 'presentation/blocs/auth/auth_bloc.dart'; // ← NUEVO
import 'presentation/blocs/config/config_bloc.dart';
import 'presentation/blocs/diagnostico/diagnostico_bloc.dart'; // ← NUEVO
import 'presentation/blocs/entrenamiento/entrenamiento_bloc.dart'; // ← NUEVO
import 'presentation/blocs/formulario/formulario_bloc.dart';
import 'presentation/blocs/upload/upload_bloc.dart';

// Data Sources – Diagnósticos
import 'data/datasources/remote/diagnostico_remote_datasource.dart'; // ← NUEVO
import 'data/datasources/remote/sample_train_remote_datasource.dart'; // ← Servicio 2
import 'data/datasources/remote/diagnose_remote_datasource.dart'; // ← Servicio 3

final sl = GetIt.instance;

Future<void> init() async {
  //! Core

  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => Connectivity());

  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivity: sl(), httpClient: sl()),
  );

  //! Auth  ──────────────────────────────────────────────────────────────────

  sl.registerFactory(
    () => AuthBloc(authDataSource: sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(httpClient: sl()),
  );

  //! Diagnósticos ───────────────────────────────────────────────────────────

  sl.registerFactory(
    () => DiagnosticoBloc(dataSource: sl()),
  );

  sl.registerLazySingleton<DiagnosticoRemoteDataSource>(
    () => DiagnosticoRemoteDataSourceImpl(httpClient: sl()),
  );

  //! Entrenamiento (Generar Diagnóstico) ────────────────────────────────────

  sl.registerFactory(
    () => EntrenamientoBloc(
      diagnoseDataSource: sl<DiagnoseRemoteDataSource>(),
      diagnosticoDataSource: sl<DiagnosticoRemoteDataSource>(),
    ),
  );

  //! Config ─────────────────────────────────────────────────────────────────

  sl.registerFactory(
    () => ConfigBloc(
      configRepository: sl(),
      obtenerConsultoriosUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => ObtenerHospitalesUseCase(repository: sl()));
  sl.registerLazySingleton(
      () => ObtenerConsultoriosPorHospitalUseCase(repository: sl()));
  sl.registerLazySingleton(() => ObtenerFocosUseCase(repository: sl()));

  sl.registerLazySingleton<ConfigRepository>(
    () => ConfigRepositoryImpl(
      remoteDataSource: sl(), // ← antes: localDataSource
    ),
  );

  // ConfigRemoteDataSource reemplaza a ConfigLocalDataSourceImpl
  sl.registerLazySingleton<ConfigRemoteDataSource>(
    () => ConfigRemoteDataSourceImpl(httpClient: sl()),
  );

  //! Formulario ─────────────────────────────────────────────────────────────

  sl.registerFactory(
    () => FormularioBloc(
      enviarFormularioUseCase: sl(),
      generarNombreArchivoUseCase: sl(),
      networkInfo: sl(),
      localStorageDataSource: sl(),
      sampleTrainRemoteDataSource: sl(),
      diagnoseRemoteDataSource: sl(),
      diagnosticoRemoteDataSource: sl(),
    ),
  );

  sl.registerFactory(() => UploadBloc());

  sl.registerLazySingleton(() => EnviarFormularioUseCase(repository: sl()));
  sl.registerLazySingleton(() => GenerarNombreArchivoUseCase(repository: sl()));

  sl.registerLazySingleton<FormularioRepository>(
    () => FormularioRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<AwsS3RemoteDataSource>(
    () => AwsS3RemoteDataSourceImpl(),
  );

  sl.registerLazySingleton<LocalStorageDataSource>(
    () => LocalStorageDataSourceImpl(),
  );

  //! Servicio 2 – Muestras de entrenamiento ────────────────────────────────

  sl.registerLazySingleton<SampleTrainRemoteDataSource>(
    () => SampleTrainRemoteDataSourceImpl(httpClient: sl()),
  );

  //! Servicio 3 – Diagnóstico IA ───────────────────────────────────────────

  sl.registerLazySingleton<DiagnoseRemoteDataSource>(
    () => DiagnoseRemoteDataSourceImpl(httpClient: sl()),
  );
}
