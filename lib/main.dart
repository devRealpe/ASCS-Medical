// lib/main.dart
//
// CAMBIOS respecto al original:
//   1. Se agrega AuthBloc como provider global
//   2. Se define la ruta inicial '/' → LoginRegisterPage
//   3. Se define la ruta '/formulario' → FormularioPage

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

import 'amplifyconfiguration.dart';
import 'injection_container.dart' as di;
import 'presentation/theme/app_theme.dart';
import 'presentation/pages/auth/login_register_page.dart';
import 'presentation/pages/formulario/formulario_page.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/config/config_bloc.dart';
import 'presentation/blocs/config/config_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeAmplify();
  await di.init();
  runApp(const MyApp());
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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // BLoC de autenticación (global, persiste durante toda la sesión)
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>(),
        ),
        // BLoC de configuración (carga hospitales/focos desde la API)
        BlocProvider<ConfigBloc>(
          create: (_) =>
              di.sl<ConfigBloc>()..add(CargarConfiguracionEvent()),
        ),
      ],
      child: MaterialApp(
        title: 'ASCS - Etiquetado Cardíaco',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,

        // Ruta inicial → pantalla de login/registro
        initialRoute: '/',
        routes: {
          '/': (_) => const LoginRegisterPage(),
          '/formulario': (_) => const FormularioPage(),
        },
      ),
    );
  }
}
