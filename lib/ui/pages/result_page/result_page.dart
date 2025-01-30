import 'package:flutter/material.dart';
import 'dart:io';

class ResultadoPage extends StatelessWidget {
  final String nuevoNombreArchivo;
  final String audioFilePath;
  final String jsonString;

  const ResultadoPage(
      {super.key,
      required this.nuevoNombreArchivo,
      required this.audioFilePath,
      required this.jsonString});

  @override
  Widget build(BuildContext context) {
    // Renombrar el archivo
    File originalFile = File(audioFilePath);
    String newFilePath = originalFile.parent.path + '/' + nuevoNombreArchivo;
    originalFile.renameSync(newFilePath);

    return Scaffold(
      appBar: AppBar(
        title: Text('Resultado'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Nuevo Nombre del Archivo: $nuevoNombreArchivo',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'JSON Data:\n$jsonString',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
