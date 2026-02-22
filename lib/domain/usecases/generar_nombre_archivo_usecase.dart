// lib/domain/usecases/generar_nombre_archivo_usecase.dart

import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../repositories/formulario_repository.dart';

/// Caso de uso para generar el nombre de archivo siguiendo la nomenclatura
class GenerarNombreArchivoUseCase {
  final FormularioRepository repository;

  GenerarNombreArchivoUseCase({required this.repository});

  /// Formato: SC_YYYYMMDD_HHCC_FF_EST_AAAA.wav
  /// SC   : prefijo estándar Sound Cardiac
  /// YYYYMMDD: fecha de grabación
  /// HH   : código hospital
  /// CC   : código consultorio
  /// FF   : código foco
  /// EST  : estado (N=Normal / A=Anormal)
  /// AAAA : UUID v4 parcial único
  Future<Either<Failure, String>> call({
    required DateTime fechaNacimiento,
    required String codigoConsultorio,
    required String codigoHospital,
    required String codigoFoco,
    required String estado,
    String? observaciones,
  }) async {
    return await repository.generarNombreArchivo(
      fechaNacimiento: fechaNacimiento,
      codigoConsultorio: codigoConsultorio,
      codigoHospital: codigoHospital,
      codigoFoco: codigoFoco,
      estado: estado,
      observaciones: observaciones,
    );
  }
}
