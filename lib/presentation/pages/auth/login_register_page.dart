// lib/presentation/pages/auth/login_register_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../theme/medical_colors.dart';

/// Página inicial: permite registrar un nuevo usuario o iniciar sesión.
///
/// En la versión actual la API solo provee /register, por lo que el tab
/// "Iniciar sesión" muestra un aviso informativo. Cuando el backend
/// implemente /login simplemente se agrega la llamada aquí.
class LoginRegisterPage extends StatelessWidget {
  const LoginRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistradoExitosamente) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Cuenta creada exitosamente! Ya puedes usar la app.'),
              backgroundColor: MedicalColors.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Navegar al formulario después de un registro exitoso
          Navigator.of(context).pushReplacementNamed('/formulario');
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: MedicalColors.backgroundLight,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  _Header(),
                  const SizedBox(height: 40),
                  _AuthCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: MedicalColors.primaryBlue,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: MedicalColors.primaryBlue.withAlpha((0.35 * 255).toInt()),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        const Text(
          'ASCS',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: MedicalColors.primaryBlue,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Etiquetado Cardíaco',
          style: TextStyle(
            fontSize: 16,
            color: MedicalColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Tarjeta con tabs ────────────────────────────────────────────────────────

class _AuthCard extends StatefulWidget {
  @override
  State<_AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<_AuthCard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Tabs
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: MedicalColors.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: MedicalColors.textSecondary,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'Iniciar sesión'),
                  Tab(text: 'Registrarse'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Contenido
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _tabController.index == 0
                  ? const _LoginTab(key: ValueKey('login'))
                  : const _RegisterTab(key: ValueKey('register')),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab: Iniciar sesión ─────────────────────────────────────────────────────

class _LoginTab extends StatelessWidget {
  const _LoginTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MedicalColors.primaryBlue.withAlpha((0.06 * 255).toInt()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MedicalColors.primaryBlue.withAlpha((0.2 * 255).toInt()),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_clock_outlined,
            size: 48,
            color: MedicalColors.primaryBlue.withAlpha((0.6 * 255).toInt()),
          ),
          const SizedBox(height: 16),
          const Text(
            'Próximamente',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: MedicalColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'El inicio de sesión estará disponible cuando el servidor '
            'implemente el endpoint /api/auth/login.\n\n'
            'Por ahora, regístrate para crear tu cuenta y acceder a la aplicación.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: MedicalColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          // Botón de acceso directo (sin autenticación) para desarrollo
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/formulario'),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continuar sin cuenta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: MedicalColors.primaryBlue,
                side: const BorderSide(color: MedicalColors.primaryBlue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab: Registrarse ────────────────────────────────────────────────────────

class _RegisterTab extends StatefulWidget {
  const _RegisterTab({super.key});

  @override
  State<_RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends State<_RegisterTab> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _showPass = false;
  bool _showConfirmPass = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(RegistrarUsuarioEvent(
          nombreUsuario: _nombreCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          contrasena: _passCtrl.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error de servidor
              if (state is AuthError) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MedicalColors.errorRed.withAlpha((0.08 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: MedicalColors.errorRed.withAlpha((0.3 * 255).toInt()),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: MedicalColors.errorRed, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.mensaje,
                          style: const TextStyle(
                            color: MedicalColors.errorRed,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _buildTextField(
                controller: _nombreCtrl,
                label: 'Nombre de usuario',
                icon: Icons.person_outline,
                enabled: !isLoading,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El nombre de usuario es obligatorio';
                  }
                  if (v.trim().length < 3) {
                    return 'Mínimo 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailCtrl,
                label: 'Correo electrónico',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El correo es obligatorio';
                  }
                  final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
                  if (!emailRegex.hasMatch(v.trim())) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildPasswordField(
                controller: _passCtrl,
                label: 'Contraseña',
                show: _showPass,
                onToggle: () => setState(() => _showPass = !_showPass),
                enabled: !isLoading,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'La contraseña es obligatoria';
                  if (v.length < 8) return 'Mínimo 8 caracteres';
                  if (!RegExp(r'[A-Z]').hasMatch(v)) {
                    return 'Debe tener al menos una mayúscula';
                  }
                  if (!RegExp(r'[0-9]').hasMatch(v)) {
                    return 'Debe tener al menos un número';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildPasswordField(
                controller: _confirmPassCtrl,
                label: 'Confirmar contraseña',
                show: _showConfirmPass,
                onToggle: () =>
                    setState(() => _showConfirmPass = !_showConfirmPass),
                enabled: !isLoading,
                validator: (v) {
                  if (v != _passCtrl.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Requisitos de contraseña
              _PasswordHints(password: _passCtrl.text),
              const SizedBox(height: 20),

              // Botón registrar
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedicalColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Crear cuenta',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required bool enabled,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: _inputDeco(label, icon),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback onToggle,
    required bool enabled,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      enabled: enabled,
      onChanged: (_) => setState(() {}), // Para actualizar hints en tiempo real
      decoration: _inputDeco(label, Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: MedicalColors.primaryBlue),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: MedicalColors.primaryBlue, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}

// ─── Indicador de requisitos de contraseña ───────────────────────────────────

class _PasswordHints extends StatelessWidget {
  final String password;

  const _PasswordHints({required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final checks = [
      (password.length >= 8, 'Mínimo 8 caracteres'),
      (RegExp(r'[A-Z]').hasMatch(password), 'Al menos una mayúscula'),
      (RegExp(r'[0-9]').hasMatch(password), 'Al menos un número'),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: checks
            .map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        c.$1
                            ? Icons.check_circle_outline
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: c.$1
                            ? MedicalColors.successGreen
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.$2,
                        style: TextStyle(
                          fontSize: 12,
                          color: c.$1
                              ? MedicalColors.successGreen
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
