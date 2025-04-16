import 'dart:io';
import 'package:flutter/material.dart';
import '/domain/services/aws_s3/aws_s3.dart';
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

  @override
  void dispose() {
    super.dispose();
  }

  void _onFileSelected(String filePath) {
    setState(() => _audioFileName = filePath);
  }

  Map<String, dynamic> _buildJsonData() {
    final fechaNacimiento = _selectedDate ?? DateTime.now();
    final edad = DateTime.now().difference(fechaNacimiento).inDays ~/ 365;

    return {
      "metadata": {
        "fecha_nacimiento": fechaNacimiento.toIso8601String(),
        "edad": edad,
        "fecha_grabacion": DateTime.now().toIso8601String()
      },
      "ubicacion": {
        "hospital": _hospital,
        "codigo_hospital": _hospitalMap[_hospital] ?? '00',
        "consultorio": _consultorio,
        "codigo_consultorio": _consultorioMap[_consultorio] ?? '00'
      },
      "diagnostico": {
        "estado": _estado,
        "foco_auscultacion": _focoAuscultacion,
        "codigo_foco": _focoMap[_focoAuscultacion] ?? '00',
        "observaciones": _textoOpcional ?? "No aplica"
      },
      "archivo": {
        "nombre_original": _audioFileName?.split('/').last ?? '',
        "ruta_original": _audioFileName ?? '',
      }
    };
  }

  String _generateFileName() {
    if (_selectedDate == null) return '00-00-00-00-00-00-00.wav';

    final fecha = _selectedDate!;
    final edad = DateTime.now().year - fecha.year;

    return '${[
      _twoDigits(fecha.day),
      _twoDigits(fecha.month),
      _twoDigits(fecha.year % 100),
      _consultorioMap[_consultorio] ?? '00',
      _hospitalMap[_hospital] ?? '00',
      _focoMap[_focoAuscultacion] ?? '00',
      _twoDigits(edad),
      (_textoOpcional?.isNotEmpty ?? false) ? '01' : '00'
    ].join('-')}.wav';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audioFileName == null || !File(_audioFileName!).existsSync()) {
      _showError('Selecciona un archivo de audio válido (.wav)');
      return;
    }

    // Construir los datos del formulario
    final jsonData = _buildJsonData();
    final fileName = _generateFileName();

    // Actualizar estado para mostrar progreso del envío
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Iniciando envío...';
    });

    try {
      // Instanciar y llamar al servicio de Amplify Storage para S3
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
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Etiquetar sonido'),
        centerTitle: true,
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
              _buildDropdown(
                label: 'Hospital',
                items: _hospitalMap.keys.toList(),
                value: _hospital,
                onChanged: (v) => setState(() => _hospital = v),
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                label: 'Consultorio',
                items: _consultorioMap.keys.toList(),
                value: _consultorio,
                onChanged: (v) => setState(() => _consultorio = v),
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                label: 'Estado del sonido',
                items: ['Normal', 'Anormal'],
                value: _estado,
                onChanged: (v) => setState(() => _estado = v),
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                label: 'Foco de auscultación',
                items: _focoMap.keys.toList(),
                value: _focoAuscultacion,
                onChanged: (v) => setState(() => _focoAuscultacion = v),
              ),
              const SizedBox(height: 20),
              _buildDatePicker(),
              const SizedBox(height: 20),
              _buildOptionalTextField(),
              const SizedBox(height: 20),
              AudioFilePicker(onFileSelected: _onFileSelected),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Enviar'),
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadOverlay() {
    return Container(
      color: Colors.black.withAlpha((0.7 * 255).toInt()),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                _uploadStatus,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
                minHeight: 10,
              ),
              const SizedBox(height: 15),
              Text(
                '${(_uploadProgress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
      ),
      items: items
          .map((opcion) => DropdownMenuItem(
                value: opcion,
                child: Text(opcion),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Selecciona una opción' : null,
    );
  }

  Widget _buildDatePicker() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Fecha de nacimiento',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
        filled: true,
      ),
      readOnly: true,
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          setState(() => _selectedDate = pickedDate);
        }
      },
      controller: TextEditingController(
        text: _selectedDate?.toLocal().toString().split(' ')[0] ?? '',
      ),
      validator: (v) => _selectedDate == null ? 'Selecciona una fecha' : null,
    );
  }

  Widget _buildOptionalTextField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Diagnóstico (Opcional)',
        border: OutlineInputBorder(),
        filled: true,
      ),
      onChanged: (v) => setState(() => _textoOpcional = v),
      maxLines: 3,
    );
  }
}
