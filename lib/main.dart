// Importaciones de paquetes y archivos locales
import 'package:flutter/material.dart';
import 'package:app_ascs/ui/pages/form/form.dart'; // Página del formulario principal

// Punto de entrada principal de la aplicación
void main() {
  // Inicia la aplicación con el widget MyApp
  runApp(const MyApp());
}

// Widget raíz de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplicación ASCS',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FormularioCompletoPage(),
    );
  }
}
