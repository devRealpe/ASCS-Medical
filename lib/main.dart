// Importaciones de paquetes y archivos locales
import 'package:flutter/material.dart';
import 'package:app_ascs/ui/pages/form/form.dart'; // Página del formulario principal
import 'package:app_ascs/ui/pages/navbar/navbar.dart'; // Componente de barra de navegación persistente

// Punto de entrada principal de la aplicación
void main() {
  // Inicia la aplicación con el widget MyApp
  runApp(const MyApp());
}

// Widget raíz de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Método principal de construcción de la interfaz
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASCS Medical', // Nombre de la aplicación
      theme: ThemeData(
        primarySwatch: Colors.blue, // Color principal de la aplicación
        // Puedes añadir más personalizaciones del tema aquí:
        // - appBarTheme
        // - textTheme
        // - inputDecorationTheme
      ),
      // Configuración de la pantalla principal con navegación persistente
      home: PersistentBottomBarScaffold(
        items: [
          // Primer tab - Formulario principal
          PersistentTabItem(
            tab: const FormularioCompletoPage(), // Widget del formulario
            title: 'Formulario', // Título en la barra de navegación
            icon: Icons.assignment, // Icono del tab
            navigatorkey: GlobalKey<
                NavigatorState>(), // Key para navegación independiente
          ),
          // Segundo tab - Configuración (actualmente Placeholder)
          PersistentTabItem(
            tab:
                const Placeholder(), // Widget temporal - reemplazar con SettingsPage
            title: 'Configuración',
            icon: Icons.settings,
            navigatorkey: GlobalKey<NavigatorState>(),
          ),
        ],
      ),
      // Configuraciones adicionales recomendadas:
      // debugShowCheckedModeBanner: false, // Eliminar banner DEBUG
      // routes: {} // Para manejar rutas con nombre
    );
  }
}
