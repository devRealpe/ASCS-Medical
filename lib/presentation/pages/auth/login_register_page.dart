// lib/presentation/pages/auth/login_register_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/theme/theme_cubit.dart';
import '../../theme/medical_colors.dart';

class LoginRegisterPage extends StatelessWidget {
  const LoginRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistradoExitosamente) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '¡Cuenta creada exitosamente! Ya puedes iniciar sesión.'),
              backgroundColor: MedicalColors.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state is AuthLogueadoExitosamente) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Bienvenido, ${state.usuario.nombreUsuario}!'),
              backgroundColor: MedicalColors.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pushReplacementNamed('/home');
        }
      },
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      const _Header(),
                      const SizedBox(height: 40),
                      const _AuthCard(),
                    ],
                  ),
                ),
                // Botón de tema en esquina superior derecha
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: context.primary,
                    ),
                    tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
                    onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: context.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: context.primary.withAlpha(90),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        Text(
          'ASCS',
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Etiquetado Cardíaco',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

// ─── Tarjeta con tabs ────────────────────────────────────────────────────────

class _AuthCard extends StatefulWidget {
  const _AuthCard();

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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Tabs
            Container(
              decoration: BoxDecoration(
                color: context.inputFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: context.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: context.onSurfaceSecondary,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
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

class _LoginTab extends StatefulWidget {
  const _LoginTab({super.key});

  @override
  State<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<_LoginTab> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(LoginUsuarioEvent(
          nombreUsuario: _nombreCtrl.text.trim(),
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
              if (state is AuthError) ...[
                _ErrorBanner(message: state.mensaje),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nombreCtrl,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: 'Nombre de usuario',
                  prefixIcon:
                      Icon(Icons.person_outline, color: context.primary),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'El nombre de usuario es obligatorio';
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: !_showPass,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outline, color: context.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPass ? Icons.visibility_off : Icons.visibility,
                      color: context.hint,
                    ),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'La contraseña es obligatoria';
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Iniciar sesión'),
                ),
              ),
            ],
          ),
        );
      },
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
              if (state is AuthError) ...[
                _ErrorBanner(message: state.mensaje),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nombreCtrl,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: 'Nombre de usuario',
                  prefixIcon:
                      Icon(Icons.person_outline, color: context.primary),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'El nombre de usuario es obligatorio';
                  if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon:
                      Icon(Icons.email_outlined, color: context.primary),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'El correo es obligatorio';
                  final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
                  if (!emailRegex.hasMatch(v.trim()))
                    return 'Ingresa un correo válido';
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: !_showPass,
                enabled: !isLoading,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outline, color: context.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPass ? Icons.visibility_off : Icons.visibility,
                      color: context.hint,
                    ),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'La contraseña es obligatoria';
                  if (v.length < 8) return 'Mínimo 8 caracteres';
                  if (!RegExp(r'[A-Z]').hasMatch(v))
                    return 'Debe tener al menos una mayúscula';
                  if (!RegExp(r'[0-9]').hasMatch(v))
                    return 'Debe tener al menos un número';
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPassCtrl,
                obscureText: !_showConfirmPass,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: Icon(Icons.lock_outline, color: context.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPass
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: context.hint,
                    ),
                    onPressed: () =>
                        setState(() => _showConfirmPass = !_showConfirmPass),
                  ),
                ),
                validator: (v) {
                  if (v != _passCtrl.text)
                    return 'Las contraseñas no coinciden';
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 28),
              _PasswordHints(password: _passCtrl.text),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Crear cuenta'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Error banner ────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MedicalColors.errorRed.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MedicalColors.errorRed.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: MedicalColors.errorRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style:
                  const TextStyle(color: MedicalColors.errorRed, fontSize: 13),
            ),
          ),
        ],
      ),
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
        color: context.inputFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.divider),
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
                        color: c.$1 ? MedicalColors.successGreen : context.hint,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.$2,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              c.$1 ? MedicalColors.successGreen : context.hint,
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
