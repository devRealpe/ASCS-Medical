import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

class ResultadoPage extends StatelessWidget {
  final String nuevoNombreArchivo;
  final String audioFilePath;
  final String jsonString;

  const ResultadoPage({
    super.key,
    required this.nuevoNombreArchivo,
    required this.audioFilePath,
    required this.jsonString,
  });

  Future<void> _renameFile(BuildContext context) async {
    final originalFile = File(audioFilePath);
    final newFilePath = '${originalFile.parent.path}/$nuevoNombreArchivo';

    try {
      if (await originalFile.exists()) {
        await originalFile.rename(newFilePath);
        debugPrint('Archivo renombrado: $newFilePath');
      } else {
        throw Exception('Archivo original no encontrado');
      }
    } catch (e) {
      debugPrint('Error: $e');
      _showErrorDialog(context, e.toString());
    }
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text('Error procesando archivo: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _parseJsonData() {
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    // Convertir string a DateTime
    jsonData['metadata']['fecha_nacimiento'] =
        DateTime.parse(jsonData['metadata']['fecha_nacimiento'] as String);

    return jsonData;
  }

  @override
  Widget build(BuildContext context) {
    final jsonData = _parseJsonData();

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado')),
      body: FutureBuilder(
        future: _renameFile(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ),
            );
          }

          return _buildContent(jsonData);
        },
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> jsonData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoCard(
            title: 'Archivo: $nuevoNombreArchivo',
            content: 'Ruta: ${jsonData['archivo']['ruta_original']}',
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            title: 'Metadata',
            content: '''
Fecha Nacimiento: ${jsonData['metadata']['fecha_nacimiento']}
Edad: ${jsonData['metadata']['edad']} años
Fecha Grabación: ${jsonData['metadata']['fecha_grabacion']}
            ''',
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            title: 'Diagnóstico',
            content: '''
Estado: ${jsonData['diagnostico']['estado']}
Foco: ${jsonData['diagnostico']['foco_auscultacion']}
Observaciones: ${jsonData['diagnostico']['observaciones']}
            ''',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content}) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
