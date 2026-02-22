import 'package:flutter/material.dart';
import '../../../../core/services/storage_preference_service.dart';
import '../../../theme/medical_colors.dart';

/// Widget compacto para cambiar el modo de almacenamiento
/// Se muestra como un pequeño ícono en el AppBar
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
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    final isLocal = _currentMode == StorageMode.local;

    return Tooltip(
      message: isLocal ? 'Almacenamiento: Local' : 'Almacenamiento: Nube',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.15 * 255).toInt()),
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: () => _showStorageOptions(context),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  isLocal ? Icons.storage_rounded : Icons.cloud_done_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                // Indicador de punto en la esquina
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isLocal
                          ? const Color(0xFF66BB6A) // verde = local
                          : const Color(0xFF42A5F5), // azul = nube
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
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

  void _showStorageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StorageOptionsSheet(
        currentMode: _currentMode,
        onModeChanged: (newMode) {
          setState(() => _currentMode = newMode);
        },
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.currentMode;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
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
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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
                    child: const Icon(
                      Icons.settings_rounded,
                      color: MedicalColors.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Almacenamiento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MedicalColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Requiere contraseña para cambiar',
                        style: TextStyle(
                          fontSize: 12,
                          color: MedicalColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Opciones de almacenamiento
              _buildStorageOption(
                mode: StorageMode.local,
                icon: Icons.storage_rounded,
                title: 'Almacenamiento Local',
                subtitle: 'Guarda en el dispositivo\n(Sin Internet requerido)',
                color: const Color(0xFF43A047),
              ),
              const SizedBox(height: 12),
              _buildStorageOption(
                mode: StorageMode.cloud,
                icon: Icons.cloud_upload_rounded,
                title: 'Nube (AWS S3)',
                subtitle:
                    'Envía al repositorio remoto\n(Requiere conexión a Internet)',
                color: MedicalColors.primaryBlue,
              ),

              // Sección de contraseña (solo si el modo seleccionado es diferente al actual)
              if (_selectedMode != widget.currentMode) ...[
                const SizedBox(height: 20),
                Container(
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
                          Icon(Icons.lock_outline,
                              size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Ingresa la contraseña para confirmar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
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
                              color: MedicalColors.primaryBlue),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorText: _errorText,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (_) {
                          if (_errorText != null) {
                            setState(() => _errorText = null);
                          }
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isChanging
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Cambiar a ${StoragePreferenceService.getModeLabel(_selectedMode)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Botón cancelar (solo si no cambió nada)
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
      onTap: () {
        setState(() {
          _selectedMode = mode;
          _errorText = null;
          _passwordController.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
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
                  color: isSelected ? color : Colors.grey.shade500, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : MedicalColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withAlpha((0.12 * 255).toInt()),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Activo',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Radio<StorageMode>(
              value: mode,
              groupValue: _selectedMode,
              activeColor: color,
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _selectedMode = v;
                    _errorText = null;
                    _passwordController.clear();
                  });
                }
              },
            ),
          ],
        ),
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

    final exito = await StoragePreferenceService.setStorageMode(
      _selectedMode,
      password,
    );

    if (!mounted) return;

    setState(() => _isChanging = false);

    if (exito) {
      widget.onModeChanged(_selectedMode);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                  'Modo cambiado a: ${StoragePreferenceService.getModeLabel(_selectedMode)}'),
            ],
          ),
          backgroundColor: const Color(0xFF43A047),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      setState(() => _errorText = 'Contraseña incorrecta');
    }
  }
}
