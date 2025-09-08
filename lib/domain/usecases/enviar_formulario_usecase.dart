import 'dart:io';
import '../repositories/formulario_repository.dart';

class EnviarFormularioUseCase {
  final FormularioRepository repository;

  EnviarFormularioUseCase({required this.repository});

  /// Ejecuta el caso de uso para enviar el formulario
  Future<void> call({
    required Map<String, dynamic> jsonData,
    required File audioFile,
    required String fileName,
    void Function(double progress, String status)? onProgress,
  }) {
    return repository.sendFormDataToS3(
      audioFile: audioFile,
      jsonData: jsonData,
      fileName: fileName,
      onProgress: onProgress,
    );
  }
}
