import 'dart:io';
import '/domain/repositories/formulario_repository.dart';
import '/domain/services/aws_s3/aws_s3.dart';

class AwsFormularioRepository implements FormularioRepository {
  final AwsAmplifyS3Service awsS3Service;

  AwsFormularioRepository({required this.awsS3Service});

  @override
  Future<void> sendFormDataToS3({
    required Map<String, dynamic> jsonData,
    required File audioFile,
    required String fileName,
    void Function(double progress, String status)? onProgress,
  }) async {
    await awsS3Service.sendFormDataToS3(
      audioFile: audioFile,
      fileName: fileName,
      fechaNacimiento: jsonData['fechaNacimiento'],
      hospital: jsonData['hospital'],
      consultorio: jsonData['consultorio'],
      estado: jsonData['estado'],
      focoAuscultacion: jsonData['focoAuscultacion'],
      observaciones: jsonData['observaciones'],
      etiquetaAudioService: jsonData['etiquetaAudioService'],
      audioUrl: jsonData['audioUrl'],
      onProgress: onProgress ?? (progress, status) {},
    );
  }
}
