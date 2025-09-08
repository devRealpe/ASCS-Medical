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
      title: 'Aplicación ASCS',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FormularioCompletoPage(),
    );
  }
}
