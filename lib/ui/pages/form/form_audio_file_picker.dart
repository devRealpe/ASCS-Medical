import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class AudioFilePicker extends StatefulWidget {
  final Function(String) onFileSelected;

  const AudioFilePicker({super.key, required this.onFileSelected});

  @override
  AudioFilePickerState createState() => AudioFilePickerState();
}

class AudioFilePickerState extends State<AudioFilePicker>
    with SingleTickerProviderStateMixin {
  String? _selectedFileName;
  String? _selectedFilePath;
  bool _isHovering = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    _animationController.forward().then((_) => _animationController.reverse());

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

  String _getFileSize() {
    if (_selectedFilePath == null) return '';
    final file = File(_selectedFilePath!);
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1976D2);
    final successColor = const Color(0xFF2A9D8F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Área de selección de archivo
        ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: _pickAudioFile,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovering = true),
              onExit: (_) => setState(() => _isHovering = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: _selectedFileName != null
                      ? LinearGradient(
                          colors: [
                            successColor.withAlpha((0.1 * 255).toInt()),
                            successColor.withAlpha((0.05 * 255).toInt()),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            primaryColor.withAlpha((0.05 * 255).toInt()),
                            primaryColor.withAlpha((0.02 * 255).toInt()),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  border: Border.all(
                    color: _selectedFileName != null
                        ? successColor
                        : (_isHovering ? primaryColor : Colors.grey.shade300),
                    width: _isHovering || _selectedFileName != null ? 2 : 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isHovering
                      ? [
                          BoxShadow(
                            color: primaryColor.withAlpha((0.2 * 255).toInt()),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ícono animado
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                          begin: 0.0,
                          end: _selectedFileName != null ? 1.0 : 0.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (value * 0.2),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _selectedFileName != null
                                  ? successColor.withAlpha((0.15 * 255).toInt())
                                  : primaryColor.withAlpha((0.1 * 255).toInt()),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_selectedFileName != null
                                          ? successColor
                                          : primaryColor)
                                      .withAlpha((0.3 * 255).toInt()),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              _selectedFileName != null
                                  ? Icons.check_circle
                                  : Icons.audiotrack,
                              size: 48,
                              color: _selectedFileName != null
                                  ? successColor
                                  : primaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Texto principal
                    Text(
                      _selectedFileName != null
                          ? 'Archivo cargado exitosamente'
                          : 'Seleccionar archivo de audio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _selectedFileName != null
                            ? successColor
                            : primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Texto secundario
                    Text(
                      _selectedFileName != null
                          ? 'Toca para cambiar el archivo'
                          : 'Toca aquí para elegir un archivo .wav',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Información del archivo si está seleccionado
                    if (_selectedFileName != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    successColor.withAlpha((0.1 * 255).toInt()),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.audio_file,
                                color: successColor,
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // Mensaje de ayuda
        if (_selectedFileName == null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Solo se permiten archivos en formato WAV',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
