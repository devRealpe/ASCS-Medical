// lib/domain/entities/formulario_completo.dart

import 'package:equatable/equatable.dart';
import 'audio_metadata.dart';

/// Entidad que representa un formulario completo con sus 4 audios.
///
/// [fileName] es el nombre base del archivo (con extensión .wav nominal)
/// usado para derivar los 4 nombres finales al guardar/subir.
/// Ejemplo: SC_20240101_0101_01_N_ABCD12345678.wav
class FormularioCompleto extends Equatable {
  final AudioMetadata metadata;

  /// Nombre base del archivo (SC_YYYYMMDD_HHCC_FF_EST_ID.wav).
  /// Se usa para construir los 4 nombres finales:
  ///   base.wav        → Audios/
  ///   base_ECG.wav    → ECG/
  ///   base_ECG_1.wav  → ECG_1/
  ///   base_ECG_2.wav  → ECG_2/
  final String fileName;

  const FormularioCompleto({
    required this.metadata,
    required this.fileName,
  });

  @override
  List<Object?> get props => [metadata, fileName];
}
