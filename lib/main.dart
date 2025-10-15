import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'amplifyconfiguration.dart';
import 'ui/pages/form/form.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final auth = AmplifyAuthCognito();
  final storage = AmplifyStorageS3();

  await Amplify.addPlugins([auth, storage]);
  await Amplify.configure(amplifyconfig);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASCS - Etiquetado Cardíaco',
      debugShowCheckedModeBanner: false,

      // ========================================================================
      // TEMA CLARO - COLORES MÉDICOS PROFESIONALES
      // ========================================================================
      theme: ThemeData(
        // Color primario: Azul médico profesional
        primaryColor: const Color(0xFF1976D2),
        primarySwatch: Colors.blue,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          secondary: const Color(0xFF00897B), // Teal médico
          brightness: Brightness.light,
          error: const Color(0xFFD32F2F),
          surface: Colors.white,
        ),

        // Fondo principal de la aplicación
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        cardColor: Colors.white,

        // ======================================================================
        // TIPOGRAFÍA MÉDICA PROFESIONAL
        // ======================================================================
        textTheme: const TextTheme(
          // Títulos grandes
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
            letterSpacing: 0.5,
          ),
          // Títulos medianos
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
            letterSpacing: 0.5,
          ),
          // Títulos pequeños
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF263238),
          ),
          // Texto del cuerpo grande
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF455A64),
            height: 1.5,
          ),
          // Texto del cuerpo mediano
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF546E7A),
            height: 1.5,
          ),
          // Texto pequeño
          bodySmall: TextStyle(
            fontSize: 12,
            color: Color(0xFF90A4AE),
          ),
        ),

        // ======================================================================
        // BOTONES ELEVADOS
        // ======================================================================
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),

        // ======================================================================
        // BOTONES DE TEXTO
        // ======================================================================
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1976D2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ======================================================================
        // CAMPOS DE TEXTO / INPUTS
        // ======================================================================
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],

          // Borde normal
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),

          // Borde habilitado
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),

          // Borde enfocado
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF1976D2),
              width: 2.5,
            ),
          ),

          // Borde de error
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),

          // Borde de error enfocado
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red, width: 2.5),
          ),

          // Padding interno
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),

          // Estilo de etiquetas
          labelStyle: const TextStyle(
            color: Color(0xFF546E7A),
            fontWeight: FontWeight.w500,
          ),

          // Estilo de hints
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
        ),

        // ======================================================================
        // TARJETAS - CORREGIDO: Usar CardThemeData directamente
        // ======================================================================
        cardTheme: CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white,
          shadowColor: const Color(0xFF1976D2).withValues(alpha: 0.15),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),

        // ======================================================================
        // APP BAR
        // ======================================================================
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(
            color: Colors.white,
            size: 24,
          ),
        ),

        // ======================================================================
        // DIÁLOGOS - CORREGIDO: Usar DialogThemeData directamente
        // ======================================================================
        dialogTheme: DialogThemeData(
          backgroundColor: Colors
              .white, // backgroundColor aquí en lugar de dialogBackgroundColor
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),

        // ======================================================================
        // DIVIDERS
        // ======================================================================
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade300,
          thickness: 1,
          space: 20,
        ),

        // ======================================================================
        // ICONOS
        // ======================================================================
        iconTheme: const IconThemeData(
          color: Color(0xFF1976D2),
          size: 24,
        ),

        // ======================================================================
        // PROGRESS INDICATORS
        // ======================================================================
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF1976D2),
          circularTrackColor: Color(0xFFE3F2FD),
        ),

        // ======================================================================
        // SNACKBARS
        // ======================================================================
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF263238),
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          behavior: SnackBarBehavior.floating,
        ),

        // Usar Material 3
        useMaterial3: true,
      ),

      // ========================================================================
      // TEMA OSCURO OPCIONAL (para modo nocturno)
      // ========================================================================
      darkTheme: ThemeData(
        primaryColor: const Color(0xFF42A5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF42A5F5),
          brightness: Brightness.dark,
          secondary: const Color(0xFF26A69A),
          error: const Color(0xFFEF5350),
          surface: const Color(0xFF1E1E1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
          bodyMedium: TextStyle(color: Color(0xFFBDBDBD)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),

      // Modo de tema (puedes cambiarlo dinámicamente)
      themeMode: ThemeMode.light, // Opciones: light, dark, system

      // Página principal
      home: const FormularioCompletoPage(),
    );
  }
}

// ==============================================================================
// CLASE AUXILIAR: CONSTANTES DE COLORES MÉDICOS
// ==============================================================================
// Puedes usar esta clase en cualquier parte de tu aplicación
class MedicalColors {
  // Prevenir instanciación
  MedicalColors._();

  // ============================================================================
  // COLORES PRIMARIOS
  // ============================================================================
  static const Color primaryBlue = Color(0xFF1976D2); // Azul médico
  static const Color secondaryTeal = Color(0xFF00897B); // Teal médico
  static const Color accentCyan = Color(0xFF00ACC1); // Cyan acento
  static const Color lightBlue = Color(0xFF42A5F5); // Azul claro

  // ============================================================================
  // COLORES DE ESTADO
  // ============================================================================
  static const Color successGreen = Color(0xFF43A047); // Verde éxito
  static const Color warningOrange = Color(0xFFFF6F00); // Naranja advertencia
  static const Color errorRed = Color(0xFFD32F2F); // Rojo error
  static const Color infoBlue = Color(0xFF1976D2); // Azul información

  // ============================================================================
  // COLORES DE FONDO
  // ============================================================================
  static const Color backgroundLight = Color(0xFFF5F7FA); // Fondo claro
  static const Color cardWhite = Color(0xFFFFFFFF); // Tarjeta blanca
  static const Color surfaceGrey = Color(0xFFFAFAFA); // Superficie gris
  static const Color dividerGrey = Color(0xFFE0E0E0); // Divisor gris

  // ============================================================================
  // COLORES DE TEXTO
  // ============================================================================
  static const Color textPrimary = Color(0xFF263238); // Texto principal
  static const Color textSecondary = Color(0xFF546E7A); // Texto secundario
  static const Color textHint = Color(0xFF90A4AE); // Texto hint
  static const Color textDisabled = Color(0xFFBDBDBD); // Texto deshabilitado

  // ============================================================================
  // GRADIENTES MÉDICOS
  // ============================================================================
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F7FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
