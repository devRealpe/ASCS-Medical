import 'dart:io';

abstract class FormularioRepository {
  /// Envía el formulario y el archivo de audio a un servicio de almacenamiento
  ///
  /// [jsonData] contiene los metadatos del formulario.
  /// [audioFile] es el archivo de audio a subir.
  /// [fileName] es el nombre que tendra el archivo en el almacenamiento.
  /// [onProgress] (opcional) permite notifica el progeso de la subida.
  Future<void> sendFormDataToS3({
    required File audioFile,
    required Map<String, dynamic> jsonData,
    required String fileName,
    void Function(double progress, String status)? onProgress,
  });
}
