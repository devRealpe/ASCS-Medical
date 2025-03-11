import 'package:flutter/material.dart';
import 'package:app_ascs/ui/pages/form/form.dart';
import 'package:app_ascs/ui/pages/navbar/navbar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PersistentBottomBarScaffold(
        items: [
          PersistentTabItem(
            tab: const FormularioCompletoPage(), // Tu página de formulario
            title: 'Formulario',
            icon: Icons.assignment,
            navigatorkey: GlobalKey<NavigatorState>(),
          ),
          PersistentTabItem(
            tab: const Placeholder(), // Otra página ejemplo
            title: 'Configuración',
            icon: Icons.settings,
            navigatorkey: GlobalKey<NavigatorState>(),
          ),
        ],
      ),
    );
  }
}
