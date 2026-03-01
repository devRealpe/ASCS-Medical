// lib/presentation/pages/formulario/formulario_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../injection_container.dart' as di;
import '../../blocs/config/config_bloc.dart';
import '../../blocs/config/config_event.dart';
import '../../blocs/config/config_state.dart';
import '../../blocs/formulario/formulario_bloc.dart';
import '../../blocs/formulario/formulario_event.dart';
import '../../blocs/formulario/formulario_state.dart';
import '../../theme/medical_colors.dart';
import 'widgets/form_header.dart';
import 'widgets/form_fields.dart';
import 'widgets/form_audio_picker.dart';
import 'widgets/upload_overlay.dart';
import '../../../../core/services/storage_preference_service.dart';
import '../../../core/services/permission_service.dart';
import 'package:file_picker/file_picker.dart'; // ← AGREGAR

class FormularioPage extends StatelessWidget {
  const FormularioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => di.sl<FormularioBloc>(),
        ),
      ],
      child: const _FormularioPageView(),
    );
  }
}

class _FormularioPageView extends StatefulWidget {
  const _FormularioPageView();

  @override
  State<_FormularioPageView> createState() => _FormularioPageViewState();
}

class _FormularioPageViewState extends State<_FormularioPageView> {
  final _formKey = GlobalKey<FormState>();
  final _audioPickerKey = GlobalKey<FormAudioPickerState>();
  final _formFieldsKey = GlobalKey<FormFieldsState>();

  // Estado del formulario
  String? _hospital;
  String? _consultorio;
  String? _estado;
  String? _focoAuscultacion;
  DateTime? _selectedDate;
  String? _observaciones;
  String? _audioFilePath;

  // Nuevos campos
  String? _genero;
  double? _pesoCkg;
  double? _alturaCm;
  String? _categoriaAnomalia;

  static const bool _mostrarSelectorHospital = true;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FormularioBloc, FormularioState>(
      listener: _handleFormularioStateChanges,
      builder: (context, formularioState) {
        return BlocBuilder<ConfigBloc, ConfigState>(
          builder: (context, configState) {
            return Scaffold(
              backgroundColor: MedicalColors.backgroundLight,
              appBar: _buildAppBar(context),
              body: Stack(
                children: [
                  _buildFormContent(context, configState),
                  if (formularioState is FormularioEnviando)
                    UploadOverlay(
                      progress: formularioState.progress,
                      status: formularioState.status,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return FormHeader(onInfoPressed: () => _showInfoDialog(context));
  }

  Widget _buildFormContent(BuildContext context, ConfigState configState) {
    if (configState is ConfigLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (configState is ConfigError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: MedicalColors.errorRed),
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

    final config = configState.config;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            FormFields(
              key: _formFieldsKey,
              config: config,
              hospital: _hospital,
              consultorio: _consultorio,
              estado: _estado,
              focoAuscultacion: _focoAuscultacion,
              selectedDate: _selectedDate,
              observaciones: _observaciones,
              mostrarSelectorHospital: _mostrarSelectorHospital,
              onHospitalChanged: _onHospitalChanged,
              onConsultorioChanged: (v) => setState(() => _consultorio = v),
              onEstadoChanged: (v) {
                setState(() {
                  _estado = v;
                  // Limpiar categoría si cambia a Normal
                  if (v == 'Normal') _categoriaAnomalia = null;
                });
              },
              onFocoChanged: (v) => setState(() => _focoAuscultacion = v),
              onDateChanged: (v) => setState(() => _selectedDate = v),
              onObservacionesChanged: (v) => _observaciones = v,
              // Nuevos callbacks
              onGeneroChanged: (v) => setState(() => _genero = v),
              onPesoChanged: (v) => _pesoCkg = v,
              onAlturaChanged: (v) => _alturaCm = v,
              onCategoriaAnomaliaChanged: (v) =>
                  setState(() => _categoriaAnomalia = v),
            ),
            const SizedBox(height: 20),
            FormAudioPicker(
              key: _audioPickerKey,
              onFileSelected: (filePath) =>
                  setState(() => _audioFilePath = filePath),
            ),
            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _onHospitalChanged(String? value) {
    setState(() {
      _hospital = value;
      _consultorio = null;
    });

    if (value != null && mounted) {
      final config = context.read<ConfigBloc>().state;
      if (config is ConfigLoaded) {
        final hospital = config.config.getHospitalPorNombre(value);
        if (hospital != null) {
          context.read<ConfigBloc>().add(
                ObtenerConsultoriosPorHospitalEvent(hospital.codigo),
              );
        }
      }
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: MedicalColors.primaryBlue,
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
                color: Colors.white.withAlpha((0.2 * 255).toInt()),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'ENVIAR DATOS',
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

  Future<void> _submitForm() async {
    // ── Validar que haya carpeta de almacenamiento configurada (modo local) ──
    final storageMode = await StoragePreferenceService.getStorageMode();
    if (storageMode == StorageMode.local) {
      final customPath = await StoragePreferenceService.getLocalStoragePath();
      if (customPath == null || customPath.isEmpty) {
        if (!mounted) return;
        // Mostrar mensaje y abrir selector de carpeta automáticamente
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.folder_off, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Debes configurar una carpeta de almacenamiento antes de guardar.',
                  ),
                ),
              ],
            ),
            backgroundColor: MedicalColors.warningOrange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        // Abrir el bottom sheet de almacenamiento
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _StorageOptionsSheetWrapper(
            onPathConfigured: () {},
          ),
        );
        return; // No continuar con el envío
      }
    }

    // ── Validaciones normales del formulario ──
    if (!_formKey.currentState!.validate()) {
      _showError(AppConstants.errorCamposIncompletos);
      return;
    }

    if (_audioFilePath == null || !File(_audioFilePath!).existsSync()) {
      _showError(AppConstants.errorArchivoNoSeleccionado);
      return;
    }

    if (!mounted) return;

    final configState = context.read<ConfigBloc>().state;
    if (configState is! ConfigLoaded) {
      _showError('Configuración no cargada');
      return;
    }

    final config = configState.config;
    final hospitalEntity = config.getHospitalPorNombre(_hospital!);
    final consultorioEntity = config.getConsultorioPorNombre(_consultorio!);
    final focoEntity = config.getFocoPorNombre(_focoAuscultacion!);

    if (hospitalEntity == null ||
        consultorioEntity == null ||
        focoEntity == null) {
      _showError('Error al obtener configuración');
      return;
    }

    String? codigoCat;
    if (_categoriaAnomalia != null) {
      codigoCat = config.getCategoriaPorNombre(_categoriaAnomalia!)?.codigo;
    }

    if (!mounted) return;

    context.read<FormularioBloc>().add(
          EnviarFormularioEvent(
            fechaNacimiento: _selectedDate!,
            hospital: _hospital!,
            codigoHospital: hospitalEntity.codigo,
            consultorio: _consultorio!,
            codigoConsultorio: consultorioEntity.codigo,
            estado: _estado!,
            focoAuscultacion: _focoAuscultacion!,
            codigoFoco: focoEntity.codigo,
            observaciones: _observaciones,
            audioFile: File(_audioFilePath!),
            genero: _genero!,
            pesoCkg: _pesoCkg!,
            alturaCm: _alturaCm!,
            categoriaAnomalia: _categoriaAnomalia,
            codigoCategoriaAnomalia: codigoCat,
          ),
        );
  }

  void _handleFormularioStateChanges(
    BuildContext context,
    FormularioState state,
  ) {
    if (state is FormularioEnviadoExitosamente) {
      _showSuccess(state.mensaje);
      _resetForm();
      context.read<FormularioBloc>().add(ResetFormularioEvent());
    } else if (state is FormularioError) {
      _showError(state.mensaje);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _audioPickerKey.currentState?.reset();
    _formFieldsKey.currentState?.reset();

    setState(() {
      _hospital = null;
      _consultorio = null;
      _estado = null;
      _focoAuscultacion = null;
      _selectedDate = null;
      _observaciones = null;
      _audioFilePath = null;
      _genero = null;
      _pesoCkg = null;
      _alturaCm = null;
      _categoriaAnomalia = null;
    });
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
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: MedicalColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: MedicalColors.primaryBlue),
            const SizedBox(width: 12),
            const Text('Información'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Complete el formulario para etiquetar el sonido cardíaco del paciente.',
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 16),
              Text('Campos obligatorios:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Hospital'),
              Text('• Consultorio'),
              Text('• Fecha de nacimiento'),
              Text('• Género'),
              Text('• Peso (kg)'),
              Text('• Altura (cm)'),
              Text('• Estado del sonido'),
              Text('• Categoría de anomalía (si es Anormal)'),
              Text('• Foco de auscultación'),
              Text('• Archivo de audio (.wav)'),
              SizedBox(height: 16),
              Text('Campo opcional:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Diagnóstico u observaciones'),
              SizedBox(height: 16),
              Text('⚠️ Importante:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.orange)),
              SizedBox(height: 8),
              Text(
                  '• No se permite guardar la información de los archivos sin configurar carpeta de almacenamiento'),
              //Text('• Se requiere conexión a Internet estable'),
              Text(
                  '• Los archivos pueden tardar en guardarse dependiendo de su tamaño'),
              Text('• No cierres la app durante el proceso de guardado'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

/// Wrapper para abrir el StorageOptionsSheet desde formulario_page
/// sin depender del estado interno de StorageToggleWidget
class _StorageOptionsSheetWrapper extends StatefulWidget {
  final VoidCallback onPathConfigured;

  const _StorageOptionsSheetWrapper({required this.onPathConfigured});

  @override
  State<_StorageOptionsSheetWrapper> createState() =>
      _StorageOptionsSheetWrapperState();
}

class _StorageOptionsSheetWrapperState
    extends State<_StorageOptionsSheetWrapper> {
  @override
  Widget build(BuildContext context) {
    return _FolderRequiredSheet(
      onFolderSelected: () {
        widget.onPathConfigured();
        Navigator.pop(context);
      },
    );
  }
}

/// Sheet que se muestra cuando el usuario intenta enviar sin carpeta configurada
class _FolderRequiredSheet extends StatefulWidget {
  final VoidCallback onFolderSelected;

  const _FolderRequiredSheet({required this.onFolderSelected});

  @override
  State<_FolderRequiredSheet> createState() => _FolderRequiredSheetState();
}

class _FolderRequiredSheetState extends State<_FolderRequiredSheet> {
  String? _currentPath;
  bool _loading = false;

  String _formatPath(String path) {
    final parts = path.replaceAll('\\', '/').split('/');
    if (parts.length <= 3) return path;
    return '.../${parts[parts.length - 2]}/${parts.last}';
  }

  Future<void> _pickFolder() async {
    // Solicitar permisos
    final permResult = await PermissionService.requestStoragePermission();
    if (!permResult.granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(permResult.errorMessage ?? 'Permiso denegado'),
        backgroundColor: MedicalColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _loading = true);

    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Seleccionar carpeta de almacenamiento',
    );

    setState(() => _loading = false);

    if (result != null && mounted) {
      // Verificar escritura
      final testFile = File('$result/.ascs_write_test');
      try {
        await testFile.writeAsString('test');
        await testFile.delete();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚠️ No tienes permiso de escritura en esa carpeta.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      await StoragePreferenceService.setLocalStoragePath(result);
      setState(() => _currentPath = result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('✅ Carpeta configurada. Ahora puedes enviar el formulario.'),
          backgroundColor: MedicalColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ));
        widget.onFolderSelected();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Ícono de advertencia
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MedicalColors.warningOrange
                      .withAlpha((0.1 * 255).toInt()),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_off_rounded,
                  color: MedicalColors.warningOrange,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Carpeta requerida',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: MedicalColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Para guardar los sonidos cardíacos localmente, debes seleccionar '
                'una carpeta en tu dispositivo donde se almacenarán los archivos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Mostrar ruta si ya fue seleccionada
              if (_currentPath != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MedicalColors.successGreen
                        .withAlpha((0.08 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: MedicalColors.successGreen
                          .withAlpha((0.3 * 255).toInt()),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: MedicalColors.successGreen, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatPath(_currentPath!),
                          style: const TextStyle(
                            fontSize: 13,
                            color: MedicalColors.successGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botón principal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _pickFolder,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.folder_open_rounded),
                  label: Text(
                    _currentPath == null
                        ? 'Seleccionar carpeta'
                        : 'Cambiar carpeta',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedicalColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
