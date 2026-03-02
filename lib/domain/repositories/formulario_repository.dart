// lib/domain/repositories/formulario_repository.dart
import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/formulario_completo.dart';

abstract class FormularioRepository {
  /// Envía un formulario completo con su ZIP de audios.
  ///
  /// [zipFile] debe contener exactamente 4 archivos WAV con sufijos:
  ///   sin sufijo, _ECG, _ECG_1, _ECG_2
  Future<Either<Failure, void>> enviarFormulario({
    required FormularioCompleto formulario,
    required File zipFile,
    void Function(double progress, String status)? onProgress,
  });

  /// Genera el nombre base de archivo siguiendo la nomenclatura establecida.
  /// Formato: SC_YYYYMMDD_HHCC_FF_EST_AAAA.wav
  Future<Either<Failure, String>> generarNombreArchivo({
    required DateTime fechaNacimiento,
    required String codigoConsultorio,
    required String codigoHospital,
    required String codigoFoco,
    required String estado,
    String? observaciones,
  });
}
