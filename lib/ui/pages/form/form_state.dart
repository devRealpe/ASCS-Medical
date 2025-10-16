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

  //
  // CONFIGURACIÓN DE HOSPITALES
  //
  // NOTA: Por el momento solo trabajamos con el Hospital Departamental.
  // Para habilitar múltiples hospitales:
  // 1. Descomenta las líneas de 'Infantil' (o agrega nuevos hospitales)
  // 2. Cambia _mostrarSelectorHospital a true
  // 3. Cambia _hospitalPorDefecto a null si quieres que el usuario seleccione
  //

  final bool _mostrarSelectorHospital =
      false; // Cambiar a true para mostrar selector
  final String _hospitalPorDefecto = 'Departamental';

  // Mapeo de hospitales a consultorios
  final Map<String, List<String>> _hospitalConsultorios = {
    'Departamental': ['101 A', '102 B'],
    // 'Infantil': ['103 C', '104 D'], // Descomentar para habilitar
    // 'San José': ['201 A', '202 B'], // Ejemplo de nuevo hospital
  };

  // Mapa de hospitales para el parámetro hospitalMap (clave y valor iguales)
  final Map<String, String> _hospitalMap = {
    'Departamental': 'Departamental',
    // 'Infantil': 'Infantil', // Descomentar para habilitar
    // 'San José': 'San José', // Ejemplo de nuevo hospital
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
  void initState() {
    super.initState();
    // Inicializa el hospital por defecto si no se muestra el selector
    if (!_mostrarSelectorHospital) {
      _hospital = _hospitalPorDefecto;
    }
  }

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
      // Mantener el hospital por defecto después del reset
      _hospital = _hospitalPorDefecto;
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

  // Modal para mostrar información del formulario
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 10,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                _primaryColor.withAlpha((0.02 * 255).toInt()),
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Encabezado del modal
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryColor,
                        _primaryColor.withAlpha((0.85 * 255).toInt()),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.2 * 255).toInt()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Guía de uso del formulario',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido del modal
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Descripción principal
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _primaryColor.withAlpha((0.08 * 255).toInt()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _primaryColor.withAlpha((0.2 * 255).toInt()),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              color: _primaryColor,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Complete el formulario para etiquetar el sonido cardíaco del paciente.',
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Color(0xFF263238),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Lista de campos obligatorios
                      _buildInfoSection(
                        icon: Icons.check_circle_outline,
                        title: 'Campos obligatorios',
                        items: [
                          _mostrarSelectorHospital
                              ? 'Hospital y Consultorio'
                              : 'Consultorio',
                          'Estado del sonido (Normal/Anormal)',
                          'Foco de auscultación',
                          'Fecha de nacimiento',
                          'Archivo de audio (.wav)',
                        ],
                        iconColor: _successColor,
                      ),

                      const SizedBox(height: 16),

                      // Campo opcional
                      _buildInfoSection(
                        icon: Icons.edit_note,
                        title: 'Campo opcional',
                        items: [
                          'Diagnóstico u observaciones médicas',
                        ],
                        iconColor: Colors.orange,
                      ),

                      const SizedBox(height: 20),

                      // Nota importante
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.amber.withAlpha((0.3 * 255).toInt()),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Asegúrese de tener conexión a internet antes de enviar el formulario.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF263238),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Boton de 'entendido' del modal
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor:
                            _primaryColor.withAlpha((0.4 * 255).toInt()),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Entendido',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para las secciones de información
  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required List<String> items,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 26, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha((0.6 * 255).toInt()),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF546E7A),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,

      // AppBar personalizado
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _primaryColor,
                _primaryColor.withAlpha((0.85 * 255).toInt()),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withAlpha((0.3 * 255).toInt()),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      // Icono decorativo
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.2 * 255).toInt()),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withAlpha((0.3 * 255).toInt()),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Título y subtítulo
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Etiquetado Cardíaco',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Botón de información
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.15 * 255).toInt()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.help_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: _showInfoDialog,
                          tooltip: 'Información',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
            mostrarSelectorHospital: _mostrarSelectorHospital,
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
