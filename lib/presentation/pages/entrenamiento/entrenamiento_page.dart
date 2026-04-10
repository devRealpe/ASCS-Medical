// lib/presentation/pages/entrenamiento/entrenamiento_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';

import '../../../injection_container.dart' as di;
import '../../blocs/config/config_bloc.dart';
import '../../blocs/config/config_event.dart';
import '../../blocs/config/config_state.dart';
import '../../blocs/entrenamiento/entrenamiento_bloc.dart';
import '../../blocs/entrenamiento/entrenamiento_event.dart';
import '../../blocs/entrenamiento/entrenamiento_state.dart';
import '../../theme/medical_colors.dart';

class EntrenamientoPage extends StatelessWidget {
  const EntrenamientoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<EntrenamientoBloc>(),
      child: const _EntrenamientoPageView(),
    );
  }
}

class _EntrenamientoPageView extends StatefulWidget {
  const _EntrenamientoPageView();

  @override
  State<_EntrenamientoPageView> createState() => _EntrenamientoPageViewState();
}

class _EntrenamientoPageViewState extends State<_EntrenamientoPageView> {
  final _formKey = GlobalKey<FormState>();

  // Datos del paciente
  DateTime? _fechaNacimiento;
  String? _genero;
  final _pesoController = TextEditingController();
  final _alturaController = TextEditingController();

  // Datos médicos
  String? _estado;
  String? _focoAuscultacion;

  // Ubicación
  String? _hospitalSeleccionado;
  String? _consultorioSeleccionado;

  // Audio
  String? _audioFilePath;
  String? _audioFileName;

  // Estados diagnósticos posibles
  static const List<String> _estadosDiagnostico = [
    'Normal',
    'Estenosis aórtica',
    'Estenosis mitral',
    'Estenosis pulmonar',
    'Estenosis tricuspídea',
    'Insuficiencia aórtica',
    'Insuficiencia mitral',
    'Insuficiencia pulmonar',
    'Insuficiencia tricuspídea',
  ];

  @override
  void dispose() {
    _pesoController.dispose();
    _alturaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EntrenamientoBloc, EntrenamientoState>(
      listener: _handleStateChanges,
      builder: (context, entrenamientoState) {
        return BlocBuilder<ConfigBloc, ConfigState>(
          builder: (context, configState) {
            return Scaffold(
              appBar: _buildAppBar(),
              body: Stack(
                children: [
                  _buildBody(configState),
                  if (entrenamientoState is EntrenamientoEnviando)
                    _buildLoadingOverlay(entrenamientoState.status),
                ],
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Generar Diagnóstico'),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'Información',
          onPressed: _showInfoDialog,
        ),
      ],
    );
  }

  Widget _buildBody(ConfigState configState) {
    if (configState is ConfigLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (configState is ConfigError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: MedicalColors.errorRed),
            const SizedBox(height: 16),
            Text('Error al cargar configuración',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(configState.message),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  context.read<ConfigBloc>().add(CargarConfiguracionEvent()),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (configState is! ConfigLoaded) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildInfoBanner(),
            const SizedBox(height: 20),
            _buildPatientCard(),
            const SizedBox(height: 20),
            _buildLocationCard(configState),
            const SizedBox(height: 20),
            _buildDiagnosticCard(configState),
            const SizedBox(height: 20),
            _buildAudioCard(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Banner informativo ──────────────────────────────────────────────────

  Widget _buildInfoBanner() {
    final accent = context.accent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withAlpha(25),
            accent.withAlpha(12),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withAlpha(75)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withAlpha(38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.psychology, color: accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entrenamiento del modelo',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Envía un audio cardíaco .wav con datos del paciente para entrenar el modelo de clasificación.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tarjeta de datos del paciente ───────────────────────────────────────

  Widget _buildPatientCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSectionHeader('Datos del paciente', Icons.person),
            const SizedBox(height: 20),
            _buildDatePicker(),
            const SizedBox(height: 20),
            _buildGeneroSelector(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildPesoField()),
                const SizedBox(width: 16),
                Expanded(child: _buildAlturaField()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tarjeta de ubicación ────────────────────────────────────────────────

  Widget _buildLocationCard(ConfigLoaded configState) {
    final hospitales = configState.config.hospitales;
    final consultorios = _hospitalSeleccionado != null
        ? configState.config.getConsultoriosPorHospital(
            configState.config
                    .getHospitalPorNombre(_hospitalSeleccionado!)
                    ?.codigo ??
                '',
          )
        : <dynamic>[];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSectionHeader('Ubicación', Icons.location_on),
            const SizedBox(height: 20),
            _buildDropdown(
              label: 'Hospital / Institución',
              icon: Icons.local_hospital,
              items: hospitales.map((h) => h.nombre).toList(),
              value: _hospitalSeleccionado,
              onChanged: (v) => setState(() {
                _hospitalSeleccionado = v;
                _consultorioSeleccionado = null;
              }),
              validator: (v) => v == null ? 'Selecciona un hospital' : null,
            ),
            const SizedBox(height: 20),
            _buildDropdown(
              label: 'Consultorio',
              icon: Icons.meeting_room,
              items: consultorios.map((c) => c.nombre as String).toList(),
              value: _consultorioSeleccionado,
              onChanged: (v) => setState(() => _consultorioSeleccionado = v),
              validator: (v) => v == null ? 'Selecciona un consultorio' : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Tarjeta de diagnóstico ──────────────────────────────────────────────

  Widget _buildDiagnosticCard(ConfigLoaded configState) {
    final focos = configState.config.focos;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSectionHeader(
                'Información del diagnóstico', Icons.medical_services),
            const SizedBox(height: 20),
            _buildDropdown(
              label: 'Estado del diagnóstico',
              icon: Icons.health_and_safety,
              items: _estadosDiagnostico,
              value: _estado,
              onChanged: (v) => setState(() => _estado = v),
              validator: (v) => v == null ? 'Selecciona un estado' : null,
            ),
            const SizedBox(height: 20),
            _buildDropdown(
              label: 'Foco de auscultación',
              icon: Icons.hearing,
              items: focos.map((f) => f.nombre).toList(),
              value: _focoAuscultacion,
              onChanged: (v) => setState(() => _focoAuscultacion = v),
              validator: (v) => v == null ? 'Selecciona un foco' : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Tarjeta de audio ────────────────────────────────────────────────────

  Widget _buildAudioCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('Audio cardíaco', Icons.audiotrack),
            const SizedBox(height: 20),
            _buildAudioPicker(),
            if (_audioFileName == null) _buildAudioHelpText(),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPicker() {
    final hasFile = _audioFileName != null;

    return MouseRegion(
      child: GestureDetector(
        onTap: _pickAudioFile,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(hasFile ? 16 : 32),
          decoration: BoxDecoration(
            color: hasFile
                ? MedicalColors.successGreen.withAlpha(20)
                : context.primary.withAlpha(10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasFile
                  ? MedicalColors.successGreen.withAlpha(100)
                  : context.primary.withAlpha(50),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: hasFile ? _buildFileSelected() : _buildFilePrompt(),
        ),
      ),
    );
  }

  Widget _buildFilePrompt() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.primary.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.audio_file, color: context.primary, size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          'Seleccionar archivo de audio',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          'Toca aquí para elegir un archivo .wav',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildFileSelected() {
    final fileSize = _getFileSize();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MedicalColors.successGreen.withAlpha((0.15 * 255).toInt()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.audio_file,
              color: MedicalColors.successGreen, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _audioFileName!,
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
              if (fileSize.isNotEmpty)
                Text(
                  fileSize,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        IconButton(
          icon:
              const Icon(Icons.close, color: MedicalColors.errorRed, size: 20),
          onPressed: () => setState(() {
            _audioFilePath = null;
            _audioFileName = null;
          }),
          tooltip: 'Quitar archivo',
        ),
      ],
    );
  }

  Widget _buildAudioHelpText() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: context.hint),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Solo archivos .wav — audio cardíaco del paciente',
              style: TextStyle(fontSize: 12, color: context.hint),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets compartidos ─────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
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
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style:
                Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    final hasDate = _fechaNacimiento != null;

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _fechaNacimiento ?? DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          helpText: 'Fecha de nacimiento del paciente',
        );
        if (picked != null) {
          setState(() => _fechaNacimiento = picked);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de nacimiento',
          prefixIcon: Icon(
            Icons.calendar_today,
            color: hasDate ? context.primary : context.hint,
          ),
          errorText: _fechaNacimiento == null && _formKey.currentState != null
              ? null
              : null,
        ),
        child: Text(
          hasDate
              ? '${_fechaNacimiento!.day.toString().padLeft(2, '0')}/${_fechaNacimiento!.month.toString().padLeft(2, '0')}/${_fechaNacimiento!.year}'
              : 'Seleccionar fecha',
          style: TextStyle(
            color: hasDate ? context.onSurface : context.hint,
          ),
        ),
      ),
    );
  }

  Widget _buildGeneroSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _genero,
      decoration: InputDecoration(
        labelText: 'Género',
        prefixIcon: Icon(Icons.wc, color: context.hint),
      ),
      items: const [
        DropdownMenuItem(value: 'MASCULINO', child: Text('Masculino')),
        DropdownMenuItem(value: 'FEMENINO', child: Text('Femenino')),
      ],
      onChanged: (v) => setState(() => _genero = v),
      validator: (v) => v == null ? 'Selecciona el género' : null,
    );
  }

  Widget _buildPesoField() {
    return TextFormField(
      controller: _pesoController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: 'Peso (kg)',
        hintText: 'Ej: 70.5',
        prefixIcon: Icon(Icons.monitor_weight_outlined, color: context.hint),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requerido';
        final val = double.tryParse(v);
        if (val == null || val <= 0 || val > 300) return 'Peso inválido';
        return null;
      },
    );
  }

  Widget _buildAlturaField() {
    return TextFormField(
      controller: _alturaController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
      ],
      decoration: InputDecoration(
        labelText: 'Altura (cm)',
        hintText: 'Ej: 170',
        prefixIcon: Icon(Icons.height, color: context.hint),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requerido';
        final val = double.tryParse(v);
        if (val == null || val <= 0 || val > 300) return 'Altura inválida';
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: context.hint),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  // ── Botón de envío ──────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'GENERAR DIAGNÓSTICO',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Overlay de carga ────────────────────────────────────────────────────

  Widget _buildLoadingOverlay(String status) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: context.accent),
                const SizedBox(height: 24),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Por favor espera...',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Lógica ──────────────────────────────────────────────────────────────

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _audioFileName = result.files.single.name;
        _audioFilePath = result.files.single.path;
      });
    }
  }

  String _getFileSize() {
    if (_audioFilePath == null) return '';
    final file = File(_audioFilePath!);
    if (!file.existsSync()) return '';
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      _showError('Por favor completa todos los campos obligatorios.');
      return;
    }

    if (_fechaNacimiento == null) {
      _showError('Debes seleccionar la fecha de nacimiento.');
      return;
    }

    if (_audioFilePath == null || !File(_audioFilePath!).existsSync()) {
      _showError('Debes seleccionar un archivo de audio .wav válido.');
      return;
    }

    // Obtener el código del foco seleccionado
    final configState = context.read<ConfigBloc>().state;
    if (configState is! ConfigLoaded) {
      _showError('Configuración no cargada.');
      return;
    }

    final foco = configState.config.getFocoPorNombre(_focoAuscultacion!);
    if (foco == null) {
      _showError('Foco de auscultación no válido.');
      return;
    }

    final hospital =
        configState.config.getHospitalPorNombre(_hospitalSeleccionado!);
    if (hospital == null) {
      _showError('Hospital no válido.');
      return;
    }

    final consultorio =
        configState.config.getConsultorioPorNombre(_consultorioSeleccionado!);
    if (consultorio == null) {
      _showError('Consultorio no válido.');
      return;
    }

    final edad = DateTime.now().difference(_fechaNacimiento!).inDays ~/ 365;

    // Recopilar IDs de categorías de anomalía disponibles
    final catIds = configState.config.categoriasAnomalias
        .where((c) => c.id != null)
        .map((c) => c.id!)
        .toList();

    context.read<EntrenamientoBloc>().add(
          EnviarEntrenamientoEvent(
            audioFile: File(_audioFilePath!),
            fechaNacimiento: _fechaNacimiento!,
            edad: edad,
            genero: _genero!,
            pesoKg: double.parse(_pesoController.text),
            alturaCm: double.parse(_alturaController.text),
            estado: _estado!,
            focoAuscultacion: _focoAuscultacion!,
            codigoFoco: foco.codigo,
            hospital: hospital.nombre,
            codigoHospital: hospital.codigo,
            consultorio: consultorio.nombre,
            codigoConsultorio: consultorio.codigo,
            institucionId: hospital.id,
            focoId: foco.id,
            categoriaAnomaliaIds: catIds,
          ),
        );
  }

  void _handleStateChanges(BuildContext context, EntrenamientoState state) {
    if (state is EntrenamientoExitoso) {
      _showSuccessDialog(state);
    } else if (state is EntrenamientoError) {
      _showError(state.mensaje);
    }
  }

  void _showSuccessDialog(EntrenamientoExitoso state) {
    final r = state.response;
    final ia = r.resultadoIA;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    MedicalColors.successGreen.withAlpha((0.15 * 255).toInt()),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: MedicalColors.successGreen, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child:
                  Text('Diagnóstico generado', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow('Diagnóstico', ia.diagnostico),
            _buildResultRow('Confianza', ia.confianza),
            _buildResultRow('Prob. Anomalía',
                '${(ia.probabilidadAnomalia * 100).toStringAsFixed(1)}%'),
            _buildResultRow('Prob. Normal',
                '${(ia.probabilidadNormal * 100).toStringAsFixed(1)}%'),
            _buildResultRow('Valvulopatía', ia.tieneValvulopatia ? 'Sí' : 'No'),
            _buildResultRow('Foco', r.focoAuscultacion),
            if (r.recomendacion.isNotEmpty)
              _buildResultRow('Recomendación', r.recomendacion),
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  state.guardadoEnServidor ? Icons.cloud_done : Icons.cloud_off,
                  size: 18,
                  color: state.guardadoEnServidor
                      ? MedicalColors.successGreen
                      : MedicalColors.errorRed,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.guardadoEnServidor
                        ? 'Diagnóstico guardado en el servidor'
                        : 'No se pudo guardar en el servidor',
                    style: TextStyle(
                      fontSize: 12,
                      color: state.guardadoEnServidor
                          ? MedicalColors.successGreen
                          : MedicalColors.errorRed,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _resetForm();
            },
            child: const Text('NUEVO DIAGNÓSTICO'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MedicalColors.successGreen,
            ),
            child: const Text('VOLVER AL INICIO'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _pesoController.clear();
    _alturaController.clear();
    setState(() {
      _fechaNacimiento = null;
      _genero = null;
      _estado = null;
      _focoAuscultacion = null;
      _hospitalSeleccionado = null;
      _consultorioSeleccionado = null;
      _audioFilePath = null;
      _audioFileName = null;
    });
    context.read<EntrenamientoBloc>().add(ResetEntrenamientoEvent());
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: MedicalColors.errorRed,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info, color: MedicalColors.accentCyan),
            SizedBox(width: 10),
            Text('Generar Diagnóstico', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Este módulo permite enviar un audio cardíaco (.wav) junto con datos del paciente para que el modelo de inteligencia artificial genere un diagnóstico.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text('Clasificación resultante:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Normal → Sonido cardíaco saludable'),
            Text('• Valvulopatía → Posible anomalía detectada'),
            SizedBox(height: 16),
            Text('Campos requeridos:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Fecha de nacimiento, género, peso, altura'),
            Text('• Estado del diagnóstico y foco de auscultación'),
            Text('• Archivo de audio .wav'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ENTENDIDO'),
          ),
        ],
      ),
    );
  }
}
