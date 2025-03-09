import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AudioFilePicker extends StatefulWidget {
  final Function(String) onFileSelected;

  const AudioFilePicker({super.key, required this.onFileSelected});

  @override
  AudioFilePickerState createState() => AudioFilePickerState();
}

class AudioFilePickerState extends State<AudioFilePicker> {
  String? _selectedFileName;
  String? _selectedFilePath;

  void _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFileName = result.files.single.name;
        _selectedFilePath = result.files.single.path;
      });
      widget.onFileSelected(_selectedFilePath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: _pickAudioFile,
          child: Text('Seleccionar archivo de audio (.wav)'),
        ),
        if (_selectedFileName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Archivo seleccionado: $_selectedFileName'),
          ),
        if (_selectedFileName == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Por favor selecciona un archivo de audio (.wav)',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}
