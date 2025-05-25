import 'dart:io';
import 'package:flutter/material.dart';
import '/domain/services/aws_s3/aws_s3.dart';
import '/domain/application/etiqueta_audio_service.dart';

import '../form/widget.dart';

class FormularioCompletoPage extends StatefulWidget {
  const FormularioCompletoPage({super.key});

  @override
  FormularioCompletoPageState createState() => FormularioCompletoPageState();
}

class FormularioCompletoPageState extends State<FormularioCompletoPage> {
  final _formKey = GlobalKey<FormState>();

  // Mapeos de opciones
  final Map<String, String> _consultorioMap = {
    '101 A': '01',
    '102 B': '02',
    '103 C': '03'
  };
  final Map<String, String> _hospitalMap = {'Departamental': '01'};
  final Map<String, String> _focoMap = {
    'Aórtico': '01',
    'Pulmonar': '02',
    'Tricuspídeo': '03',
    'Mitral': '04'
  };

  // Controladores de estado
  String? _hospital;
  String? _consultorio;
  String? _estado;
  String? _focoAuscultacion;
  DateTime? _selectedDate;
  String? _textoOpcional;
  String? _audioFileName;

  // Variables para el seguimiento de envío
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  // Paleta de colores
  final Color _primaryColor =
      const Color(0xFF4361EE); // Ensure this is defined and not null
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF212529);
  final Color _errorColor = const Color(0xFFE63946);
  final Color _successColor = const Color(0xFF2A9D8F);

  @override
  void dispose() {
    super.dispose();
  }

  void _onFileSelected(String filePath) {
    setState(() => _audioFileName = filePath);
  }

  final EtiquetaAudioService _etiquetaService = EtiquetaAudioService();

  Map<String, dynamic> _buildJsonData() {
    if (_selectedDate == null) {
      throw Exception('Fecha de nacimiento no seleccionada');
    }
    return _etiquetaService.buildJsonData(
      fechaNacimiento: _selectedDate!,
      hospital: _hospital,
      consultorio: _consultorio,
      estado: _estado,
      focoAuscultacion: _focoAuscultacion,
      observaciones: _textoOpcional,
    );
  }

  String _generateFileName() {
    if (_selectedDate == null) {
      throw Exception('Fecha de nacimiento no seleccionada');
    }
    return _etiquetaService.generateFileName(
      fechaNacimiento: _selectedDate!,
      hospital: _hospital,
      consultorio: _consultorio,
      focoAuscultacion: _focoAuscultacion,
      observaciones: _textoOpcional,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audioFileName == null || !File(_audioFileName!).existsSync()) {
      _showError('Selecciona un archivo de audio válido (.wav)');
      return;
    }

    final jsonData = _buildJsonData();
    final fileName = _generateFileName();

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Iniciando envío...';
    });

    try {
      final s3Service = AwsAmplifyS3Service();
      await s3Service.sendFormDataToS3(
        audioFile: File(_audioFileName!),
        jsonData: jsonData,
        fileName: fileName,
        onProgress: (progress, status) {
          setState(() {
            _uploadProgress = progress;
            _uploadStatus = status;
          });
        },
      );

      _showSuccess("Datos enviados exitosamente.");
      _resetForm();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _hospital = null;
      _consultorio = null;
      _estado = null;
      _focoAuscultacion = null;
      _selectedDate = null;
      _textoOpcional = null;
      _audioFileName = null;
      _uploadProgress = 0.0;
      _uploadStatus = '';
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Etiquetar sonido cardíaco'),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Información'),
                  content: const Text(
                      'Complete el formulario para etiquetar el sonido cardíaco. Todos los campos son obligatorios excepto el diagnóstico.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Entendido'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildFormContent(),
          if (_isUploading) _buildUploadOverlay(),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: _cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildSectionHeader(
                          icon: Icons.location_on,
                          title: 'Ubicación del paciente'),
                      const SizedBox(height: 20),
                      _buildDropdown(
                        label: 'Hospital',
                        icon: Icons.local_hospital,
                        items: _hospitalMap.keys.toList(),
                        value: _hospital,
                        onChanged: (v) => setState(() => _hospital = v),
                      ),
                      const SizedBox(height: 20),
                      _buildDropdown(
                        label: 'Consultorio',
                        icon: Icons.meeting_room,
                        items: _consultorioMap.keys.toList(),
                        value: _consultorio,
                        onChanged: (v) => setState(() => _consultorio = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: _cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildSectionHeader(
                          icon: Icons.medical_services,
                          title: 'Información médica'),
                      const SizedBox(height: 20),
                      _buildDropdown(
                        label: 'Estado del sonido',
                        icon: Icons.health_and_safety,
                        items: ['Normal', 'Anormal'],
                        value: _estado,
                        onChanged: (v) => setState(() => _estado = v),
                      ),
                      const SizedBox(height: 20),
                      _buildDropdown(
                        label: 'Foco de auscultación',
                        icon: Icons.hearing,
                        items: _focoMap.keys.toList(),
                        value: _focoAuscultacion,
                        onChanged: (v) => setState(() => _focoAuscultacion = v),
                      ),
                      const SizedBox(height: 20),
                      _buildDatePicker(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: _cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildSectionHeader(
                          icon: Icons.note_add, title: 'Información adicional'),
                      const SizedBox(height: 20),
                      _buildOptionalTextField(),
                      const SizedBox(height: 20),
                      AudioFilePicker(
                        onFileSelected: _onFileSelected,
                        // Removed unsupported parameters
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: _primaryColor.withAlpha((0.3 * 255).toInt()),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'ENVIAR DATOS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: _primaryColor),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadOverlay() {
    return Container(
      color: Colors.black.withAlpha((0.7 * 255).toInt()),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.1 * 255).toInt()),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          width: MediaQuery.of(context).size.width * 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _uploadProgress,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    ),
                    Icon(
                      _uploadProgress < 1.0
                          ? Icons.cloud_upload
                          : Icons.check_circle,
                      size: 30,
                      color:
                          _uploadProgress < 1.0 ? _primaryColor : _successColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _uploadStatus,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 15),
              Text(
                '${(_uploadProgress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _textColor.withAlpha((0.7 * 255).toInt())),
        prefixIcon: Icon(icon, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items
          .map((opcion) => DropdownMenuItem(
                value: opcion,
                child: Text(opcion),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Selecciona una opción' : null,
      style: TextStyle(color: _textColor),
      dropdownColor: _cardColor,
      icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildDatePicker() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Fecha de nacimiento',
        labelStyle: TextStyle(color: _textColor.withAlpha((0.7 * 255).toInt())),
        prefixIcon: Icon(Icons.calendar_today, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      readOnly: true,
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: _primaryColor,
                  onPrimary: Colors.white,
                  surface: _cardColor,
                  onSurface: _textColor,
                ),
                dialogBackgroundColor: _cardColor,
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          setState(() => _selectedDate = pickedDate);
        }
      },
      controller: TextEditingController(
        text: _selectedDate?.toLocal().toString().split(' ')[0] ?? '',
      ),
      validator: (v) => _selectedDate == null ? 'Selecciona una fecha' : null,
      style: TextStyle(color: _textColor),
    );
  }

  Widget _buildOptionalTextField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Diagnóstico (Opcional)',
        labelStyle: TextStyle(color: _textColor.withAlpha((0.7 * 255).toInt())),
        prefixIcon: Icon(Icons.notes, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: (v) => setState(() => _textoOpcional = v),
      maxLines: 3,
      style: TextStyle(color: _textColor),
    );
  }
}
