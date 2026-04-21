// lib/data/repositories/config_repository_impl.dart
//
// CAMBIO: el constructor ahora recibe [remoteDataSource] en lugar de
// [localDataSource].  El resto de la lógica es idéntica.

import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/config/medical_config.dart';
import '../../domain/entities/config/consultorio.dart';
import '../../domain/repositories/config_repository.dart';
import '../datasources/remote/config_remote_datasource.dart';

class ConfigRepositoryImpl implements ConfigRepository {
  final ConfigRemoteDataSource remoteDataSource;

  MedicalConfig? _cachedConfig;

  ConfigRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, MedicalConfig>> obtenerConfiguracion() async {
    if (_cachedConfig != null) return Right(_cachedConfig!);

    try {
      final config = await remoteDataSource.obtenerConfiguracion();
      _cachedConfig = config;
      return Right(config);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Consultorio>>> obtenerConsultoriosPorHospital(
    String codigoHospital,
  ) async {
    try {
      final configResult = await obtenerConfiguracion();
      return configResult.fold(
        (failure) => Left(failure),
        (config) {
          final consultorios = config.consultorios
              .where((c) => c.codigoHospital == codigoHospital)
              .toList();
          return Right(consultorios);
        },
      );
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
