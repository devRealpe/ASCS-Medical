import 'dart:io';
import 'package:app_ascs/ui/pages/form/form.dart';
import 'package:flutter/material.dart';
import '/domain/services/aws_s3/aws_s3.dart';
import '/domain/application/etiqueta_audio_service.dart';
import 'form_widgets.dart';
import 'form_upload_overlay.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class FormularioCompletoPageState extends State<FormularioCompletoPage> {
  final _formKey = GlobalKey<FormState>();

// Mapeo de hospitales a consultorios
  final Map<String, List<String>> _hospitalConsultorios = {
    'Departamental': ['101 A', '102 B'],
    'Infantil': ['103 C', '104 D'],
  };

  // Mapa de hospitales para el parámetro hospitalMap (clave y valor iguales)
  final Map<String, String> _hospitalMap = {
    'Departamental': 'Departamental',
    'Infantil': 'Infantil',
  };

  List<String> get _consultoriosDisponibles {
    if (_hospital == null) return [];
    return _hospitalConsultorios[_hospital] ?? [];
  }

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

  // Clave para forzar la reconstrucción del widget de selección de archivos
  Key _filePickerKey = UniqueKey();

  // Paleta de colores
  final Color _primaryColor = const Color(0xFF1976D2);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF212529);
  final Color _errorColor = const Color(0xFFE63946);
  final Color _successColor = const Color(0xFF2A9D8F);

  final EtiquetaAudioService _etiquetaService = EtiquetaAudioService(
    awsS3Service: AwsAmplifyS3Service(),
  );

  @override
  void dispose() {
    super.dispose();
  }

  void _onFileSelected(String filePath) {
    setState(() => _audioFileName = filePath);
  }

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
      audioUrl: _audioFileName ?? '',
    );
  }

  Future<String> _generateFileName() async {
    if (_selectedDate == null) {
      throw Exception('Fecha de nacimiento no seleccionada');
    }
    return await _etiquetaService.generateFileName(
      fechaNacimiento: _selectedDate!,
      hospital: _hospital,
      consultorio: _consultorio,
      focoAuscultacion: _focoAuscultacion,
      observaciones: _textoOpcional,
    );
  }

  Future<void> _submitForm() async {
    // Verifica conexión antes de validar el formulario
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      _showError(
          'No hay conexión a internet. Por favor, verifica tu conexión e inténtalo de nuevo.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_audioFileName == null || !File(_audioFileName!).existsSync()) {
      _showError('Selecciona un archivo de audio válido (.wav)');
      return;
    }

    _buildJsonData();
    final fileName = await _generateFileName();

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Iniciando envío...';
    });

    try {
      final s3Service = AwsAmplifyS3Service();
      await s3Service.sendFormDataToS3(
        audioFile: File(_audioFileName!),
        fileName: fileName,
        fechaNacimiento: _selectedDate!,
        hospital: _hospital,
        consultorio: _consultorio,
        estado: _estado,
        focoAuscultacion: _focoAuscultacion,
        observaciones: _textoOpcional,
        audioUrl: _audioFileName ?? '',
        etiquetaAudioService: _etiquetaService,
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
      _filePickerKey = UniqueKey();
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
        title: const Text(
          'Etiquetar sonido cardíaco',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(0),
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
          buildFormContent(
            context: context,
            formKey: _formKey,
            hospitalMap: _hospitalMap,
            consultorioList: _consultoriosDisponibles,
            focoMap: _focoMap,
            hospital: _hospital,
            consultorio: _consultorio,
            estado: _estado,
            focoAuscultacion: _focoAuscultacion,
            selectedDate: _selectedDate,
            textoOpcional: _textoOpcional,
            audioFileName: _audioFileName,
            filePickerKey: _filePickerKey,
            primaryColor: _primaryColor,
            backgroundColor: _backgroundColor,
            cardColor: _cardColor,
            textColor: _textColor,
            onHospitalChanged: (v) {
              setState(() {
                _hospital = v;
                _consultorio = null; // Limpiar consultorio al cambiar hospital
              });
            },
            onConsultorioChanged: (v) => setState(() => _consultorio = v),
            onEstadoChanged: (v) => setState(() => _estado = v),
            onFocoChanged: (v) => setState(() => _focoAuscultacion = v),
            onDateChanged: (v) => setState(() => _selectedDate = v),
            onTextoOpcionalChanged: (v) => setState(() => _textoOpcional = v),
            onFileSelected: _onFileSelected,
            onSubmit: _submitForm,
          ),
          if (_isUploading)
            FormUploadOverlay(
              uploadProgress: _uploadProgress,
              uploadStatus: _uploadStatus,
              primaryColor: _primaryColor,
              successColor: _successColor,
              textColor: _textColor,
              cardColor: _cardColor,
            ),
        ],
      ),
    );
  }
}
