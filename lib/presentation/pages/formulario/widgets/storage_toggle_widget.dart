// lib/presentation/pages/formulario/widgets/storage_toggle_widget.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_preference_service.dart';
import '../../../theme/medical_colors.dart';
import '../../../../core/services/permission_service.dart';

/// Widget compacto en el AppBar para abrir la configuración de almacenamiento
class StorageToggleWidget extends StatefulWidget {
  const StorageToggleWidget({super.key});

  @override
  State<StorageToggleWidget> createState() => _StorageToggleWidgetState();
}

class _StorageToggleWidgetState extends State<StorageToggleWidget> {
  StorageMode _currentMode = StorageMode.local;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    final mode = await StoragePreferenceService.getStorageMode();
    if (mounted) {
      setState(() {
        _currentMode = mode;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ),
      );
    }

    final isLocal = _currentMode == StorageMode.local;

    return Tooltip(
      message: isLocal ? 'Almacenamiento: Local' : 'Almacenamiento: Nube',
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.15 * 255).toInt()),
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: () => _showStorageOptions(context),
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                isLocal ? Icons.storage_rounded : Icons.cloud_done_rounded,
                color: Colors.white,
                size: 20,
              ),
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isLocal
                        ? const Color(0xFF66BB6A)
                        : const Color(0xFF42A5F5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStorageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StorageOptionsSheet(
        currentMode: _currentMode,
        onModeChanged: (newMode) => setState(() => _currentMode = newMode),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _StorageOptionsSheet extends StatefulWidget {
  final StorageMode currentMode;
  final Function(StorageMode) onModeChanged;

  const _StorageOptionsSheet({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  State<_StorageOptionsSheet> createState() => _StorageOptionsSheetState();
}

class _StorageOptionsSheetState extends State<_StorageOptionsSheet> {
  late StorageMode _selectedMode;
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isChanging = false;
  String? _errorText;

  String? _currentCustomPath;
  bool _loadingPath = true;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.currentMode;
    _loadCustomPath();
  }

  Future<void> _loadCustomPath() async {
    final path = await StoragePreferenceService.getLocalStoragePath();
    if (mounted) {
      setState(() {
        _currentCustomPath = path;
        _loadingPath = false;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String _formatPath(String path) {
    final parts = path.replaceAll('\\', '/').split('/');
    if (parts.length <= 3) return path;
    return '.../${parts[parts.length - 2]}/${parts.last}';
  }

// Reemplaza el método _pickFolder existente en _StorageOptionsSheetState

  Future<void> _pickFolder() async {
    // 1. Solicitar permisos de almacenamiento antes de mostrar el picker
    final permResult = await PermissionService.requestStoragePermission();

    if (!permResult.granted) {
      if (!mounted) return;

      // Mostrar diálogo explicativo con opción de ir a Configuración
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.orange),
              SizedBox(width: 8),
              Text('Permiso requerido'),
            ],
          ),
          content: Text(
            permResult.errorMessage ??
                'Se necesita permiso de almacenamiento para '
                    'seleccionar una carpeta externa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings(); // Abre ajustes de la app
              },
              child: const Text('Ir a Configuración'),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Mostrar el selector de carpeta
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Seleccionar carpeta de almacenamiento',
    );

    if (result != null && mounted) {
      // 3. Verificar que realmente podemos escribir en esa ruta
      final testFile = File('$result/.ascs_write_test');
      try {
        await testFile.writeAsString('test');
        await testFile.delete();
      } catch (_) {
        if (!mounted) return;
        _showSnack(
          '⚠️ No tienes permiso de escritura en esa carpeta. '
          'Elige otra ubicación.',
          Colors.orange.shade700,
        );
        return;
      }

      await StoragePreferenceService.setLocalStoragePath(result);
      setState(() => _currentCustomPath = result);
      _showSnack(
          '📁 Carpeta seleccionada correctamente', const Color(0xFF43A047));
    }
  }

  Future<void> _clearFolder() async {
    await StoragePreferenceService.clearLocalStoragePath();
    if (mounted) {
      setState(() => _currentCustomPath = null);
      _showSnack('Carpeta restablecida a la ubicación por defecto',
          MedicalColors.primaryBlue);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // La sección de carpeta solo aparece cuando el modo ACTIVO (currentMode) es local
    // y el usuario tiene seleccionada la opción local en el sheet
    final showFolderSection = widget.currentMode == StorageMode.local &&
        _selectedMode == StorageMode.local;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),

              // Título
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: MedicalColors.primaryBlue
                          .withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings_rounded,
                        color: MedicalColors.primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Almacenamiento',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: MedicalColors.textPrimary)),
                        Text('Requiere contraseña para cambiar',
                            style: TextStyle(
                                fontSize: 12,
                                color: MedicalColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Opciones de modo
              _buildStorageOption(
                mode: StorageMode.local,
                icon: Icons.storage_rounded,
                title: 'Almacenamiento Local',
                subtitle: 'Guarda en el dispositivo\n(Sin Internet requerido)',
                color: const Color(0xFF43A047),
              ),
              const SizedBox(height: 10),
              _buildStorageOption(
                mode: StorageMode.cloud,
                icon: Icons.cloud_upload_rounded,
                title: 'Nube (AWS S3)',
                subtitle: 'Envía al repositorio remoto\n(Requiere Internet)',
                color: MedicalColors.primaryBlue,
              ),

              // ── Selector de carpeta ──────────────────────────────────────
              if (showFolderSection) ...[
                const SizedBox(height: 14),
                _buildFolderSection(),
              ],

              // ── Sección contraseña (cambio de modo) ─────────────────────
              if (_selectedMode != widget.currentMode) ...[
                const SizedBox(height: 16),
                _buildPasswordSection(),
              ],

              const SizedBox(height: 8),

              if (_selectedMode == widget.currentMode)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sección carpeta ───────────────────────────────────────────────────────

  Widget _buildFolderSection() {
    final hasCustomPath =
        _currentCustomPath != null && _currentCustomPath!.isNotEmpty;
    const green = Color(0xFF43A047);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: green.withAlpha((0.06 * 255).toInt()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: green.withAlpha((0.3 * 255).toInt())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de la sección
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: green.withAlpha((0.12 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder_open_rounded,
                    color: green, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Carpeta de almacenamiento',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: MedicalColors.textPrimary)),
                    Text('Elige dónde se guardarán audios y JSON',
                        style: TextStyle(
                            fontSize: 11, color: MedicalColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Ruta actual
          if (_loadingPath)
            const Center(
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    hasCustomPath
                        ? Icons.folder_rounded
                        : Icons.folder_special_rounded,
                    size: 17,
                    color: hasCustomPath ? green : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasCustomPath
                          ? _formatPath(_currentCustomPath!)
                          : 'Por defecto (almacenamiento interno de la app)',
                      style: TextStyle(
                        fontSize: 12,
                        color: hasCustomPath
                            ? MedicalColors.textPrimary
                            : Colors.grey.shade600,
                        fontStyle:
                            hasCustomPath ? FontStyle.normal : FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFolder,
                  icon: const Icon(Icons.folder_open_rounded, size: 15),
                  label: Text(hasCustomPath ? 'Cambiar' : 'Seleccionar',
                      style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: green,
                    side: const BorderSide(color: green),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              if (hasCustomPath) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearFolder,
                    icon: const Icon(Icons.restore_rounded, size: 15),
                    label: const Text('Restablecer',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Nota informativa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 13, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Se crearán "repositorio/audios" y "repositorio/audios-json" '
                    'dentro de la carpeta elegida.',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Opción de modo ────────────────────────────────────────────────────────

  Widget _buildStorageOption({
    required StorageMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedMode == mode;
    final isCurrent = widget.currentMode == mode;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedMode = mode;
        _errorText = null;
        _passwordController.clear();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withAlpha((0.08 * 255).toInt())
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withAlpha((0.15 * 255).toInt())
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isSelected ? color : Colors.grey.shade500, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? color
                                  : MedicalColors.textPrimary,
                              fontSize: 14)),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withAlpha((0.15 * 255).toInt()),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Activo',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade400,
                  width: isSelected ? 2 : 1.5,
                ),
                color: isSelected
                    ? color.withAlpha((0.12 * 255).toInt())
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration:
                            BoxDecoration(shape: BoxShape.circle, color: color),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Sección contraseña ────────────────────────────────────────────────────

  Widget _buildPasswordSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 15, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Ingresa la contraseña para confirmar',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              hintText: 'Contraseña de configuración',
              prefixIcon: const Icon(Icons.password,
                  color: MedicalColors.primaryBlue, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                    size: 20),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              errorText: _errorText,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isChanging ? null : _confirmarCambio,
              style: ElevatedButton.styleFrom(
                backgroundColor: MedicalColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isChanging
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      'Cambiar a ${StoragePreferenceService.getModeLabel(_selectedMode)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarCambio() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _errorText = 'Ingresa la contraseña');
      return;
    }
    setState(() => _isChanging = true);
    final exito =
        await StoragePreferenceService.setStorageMode(_selectedMode, password);
    if (!mounted) return;
    setState(() => _isChanging = false);

    if (exito) {
      widget.onModeChanged(_selectedMode);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    'Modo cambiado a: ${StoragePreferenceService.getModeLabel(_selectedMode)}')),
          ],
        ),
        backgroundColor: const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else {
      setState(() => _errorText = 'Contraseña incorrecta');
    }
  }
}
