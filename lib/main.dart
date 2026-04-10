import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

import 'amplifyconfiguration.dart';
import 'injection_container.dart' as di;
import 'core/services/session_service.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/pages/auth/login_register_page.dart';
import 'presentation/pages/formulario/formulario_page.dart';
import 'presentation/pages/diagnosticos/diagnosticos_page.dart';
import 'presentation/pages/entrenamiento/entrenamiento_page.dart';
import 'presentation/pages/home/home_page.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/config/config_bloc.dart';
import 'presentation/blocs/config/config_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeAmplify();
  await di.init();

  // Intentar restaurar la sesión previa
  final hasSession = await SessionService.instance.restore();
  runApp(MyApp(isLoggedIn: hasSession));
}

Future<void> _initializeAmplify() async {
  try {
    final auth = AmplifyAuthCognito();
    final storage = AmplifyStorageS3();
    await Amplify.addPlugins([auth, storage]);
    await Amplify.configure(amplifyconfig);
    safePrint('Amplify configurado exitosamente');
  } catch (e) {
    safePrint('Error al configurar Amplify: $e');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>(),
        ),
        BlocProvider<ConfigBloc>(
          create: (_) => di.sl<ConfigBloc>()..add(CargarConfiguracionEvent()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'ASCS - Etiquetado Cardíaco',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            initialRoute: isLoggedIn ? '/home' : '/',
            routes: {
              '/': (_) => const LoginRegisterPage(),
              '/home': (_) => const _AuthGuard(child: HomePage()),
              '/formulario': (_) => const _AuthGuard(child: FormularioPage()),
              '/diagnosticos': (_) =>
                  const _AuthGuard(child: DiagnosticosPage()),
              '/entrenamiento': (_) =>
                  const _AuthGuard(child: EntrenamientoPage()),
            },
          );
        },
      ),
    );
  }
}

/// Protege rutas: si no hay sesión, redirige al login.
class _AuthGuard extends StatelessWidget {
  final Widget child;
  const _AuthGuard({required this.child});

  @override
  Widget build(BuildContext context) {
    if (!SessionService.instance.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/');
      });
      return const SizedBox.shrink();
    }
    return child;
  }
}
