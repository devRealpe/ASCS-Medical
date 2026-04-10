// lib/presentation/pages/formulario/widgets/form_audio_picker.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../theme/medical_colors.dart';

class FormAudioPicker extends StatefulWidget {
  final Function(String) onFileSelected;

  const FormAudioPicker({
    super.key,
    required this.onFileSelected,
  });

  @override
  State<FormAudioPicker> createState() => FormAudioPickerState();
}

class FormAudioPickerState extends State<FormAudioPicker> {
  String? _selectedFileName;
  String? _selectedFilePath;
  bool _isHovering = false;

  void reset() {
    setState(() {
      _selectedFileName = null;
      _selectedFilePath = null;
      _isHovering = false;
    });
  }

  Future<void> _pickZipFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFileName = result.files.single.name;
        _selectedFilePath = result.files.single.path;
      });
      widget.onFileSelected(_selectedFilePath!);
    }
  }

  String _getFileSize() {
    if (_selectedFilePath == null) return '';
    final file = File(_selectedFilePath!);
    if (!file.existsSync()) return '';
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: 24),
            _buildPickerArea(),
            if (_selectedFileName == null) _buildHelpText(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    final primary = context.primary;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withAlpha(20),
            primary.withAlpha(8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: primary, width: 4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withAlpha(38),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.folder_zip_outlined, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Archivos de Audio',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  'ZIP con 4 sonidos cardíacos',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerArea() {
    return GestureDetector(
      onTap: _pickZipFile,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: _selectedFileName != null
                ? LinearGradient(
                    colors: [
                      MedicalColors.successGreen.withAlpha(25),
                      MedicalColors.successGreen.withAlpha(12),
                    ],
                  )
                : null,
            border: Border.all(
              color: _selectedFileName != null
                  ? MedicalColors.successGreen
                  : (_isHovering ? context.primary : context.divider),
              width: _isHovering || _selectedFileName != null ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            children: [
              Icon(
                _selectedFileName != null
                    ? Icons.check_circle
                    : Icons.folder_zip_outlined,
                size: 48,
                color: _selectedFileName != null
                    ? MedicalColors.successGreen
                    : context.primary,
              ),
              const SizedBox(height: 20),
              Text(
                _selectedFileName != null
                    ? 'Archivo ZIP cargado'
                    : 'Seleccionar archivo ZIP',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _selectedFileName != null
                      ? MedicalColors.successGreen
                      : context.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedFileName != null
                    ? 'Toca para cambiar el archivo'
                    : 'Toca aquí para elegir un archivo .zip',
                style: TextStyle(fontSize: 14, color: context.hint),
              ),
              if (_selectedFileName != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: MedicalColors.successGreen.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.folder_zip,
                          color: MedicalColors.successGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFileName!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getFileSize(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Indicador de los 4 sonidos que se esperan
                _buildSoundTypesIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Muestra los 4 tipos de sonido que debe contener el ZIP
  Widget _buildSoundTypesIndicator() {
    final types = [
      (Icons.graphic_eq, 'Audios', 'Principal'),
      (Icons.monitor_heart, 'ECG', 'ECG'),
      (Icons.monitor_heart, 'ECG_1', 'ECG Canal 1'),
      (Icons.monitor_heart, 'ECG_2', 'ECG Canal 2'),
    ];

    final primary = context.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: primary.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Carpetas de destino:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: types.map((t) {
              return Column(
                children: [
                  Icon(t.$1, size: 16, color: primary),
                  const SizedBox(height: 3),
                  Text(
                    t.$2,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpText() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: context.hint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'El ZIP debe contener exactamente 4 archivos WAV',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.hint,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              'Sin sufijo → Audios/  •  _ECG → ECG/  •  _ECG_1 → ECG_1/  •  _ECG_2 → ECG_2/',
              style: TextStyle(
                fontSize: 11,
                color: context.hint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
