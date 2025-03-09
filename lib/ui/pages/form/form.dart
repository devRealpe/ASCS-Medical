import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../../pages/form/widget.dart';
import '../../pages/result_page/result_page.dart';

class FormularioCompletoPage extends StatefulWidget {
  const FormularioCompletoPage({super.key});

  @override
  FormularioCompletoPageState createState() => FormularioCompletoPageState();
}

class FormularioCompletoPageState extends State<FormularioCompletoPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> consultorioMap = {
    '101 A': '01',
    '102 B': '02',
    '103 C': '03'
  };
  final Map<String, String> hospitalMap = {'Departamental': '01'};
  final Map<String, String> focoMap = {
    'Aórtico': '01',
    'Pulmonar': '02',
    'Tricuspídeo': '03',
    'Mitral': '04'
  };

  String? hospital;
  String? consultorio;
  String? estado;
  String? focoAuscultacion;
  DateTime? selectedDate;
  String? textoOpcional;
  String? audioFileName;
  final String idAudio = '1234';

  void onFileSelected(String filePath) {
    setState(() => audioFileName = filePath);
  }

  Map<String, dynamic> _buildJsonData() {
    final fechaNacimiento = selectedDate ?? DateTime.now();
    final edad = DateTime.now().difference(fechaNacimiento).inDays ~/ 365;

    return {
      "metadata": {
        "fecha_nacimiento": fechaNacimiento.toIso8601String(),
        "edad": edad,
        "fecha_grabacion": DateTime.now().toIso8601String()
      },
      "ubicacion": {
        "hospital": hospital,
        "codigo_hospital": hospitalMap[hospital] ?? '00',
        "consultorio": consultorio,
        "codigo_consultorio": consultorioMap[consultorio] ?? '00'
      },
      "diagnostico": {
        "estado": estado,
        "foco_auscultacion": focoAuscultacion,
        "codigo_foco": focoMap[focoAuscultacion] ?? '00',
        "observaciones": textoOpcional ?? "No aplica"
      },
      "archivo": {
        "id_audio": idAudio,
        "nombre_original": audioFileName?.split('/').last ?? '',
        "ruta_original": audioFileName ?? '',
      }
    };
  }

  String _generateFileName() {
    if (selectedDate == null) return '00-00-00-00-00-00-00.wav';

    final fecha = selectedDate!;
    final edad = DateTime.now().year - fecha.year;

    return '${[
      _twoDigits(fecha.day),
      _twoDigits(fecha.month),
      _twoDigits(fecha.year % 100),
      consultorioMap[consultorio] ?? '00',
      hospitalMap[hospital] ?? '00',
      focoMap[focoAuscultacion] ?? '00',
      idAudio,
      _twoDigits(edad),
      (textoOpcional?.isNotEmpty ?? false) ? '01' : '00'
    ].join('-')}.wav';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (audioFileName == null || !File(audioFileName!).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona un archivo de audio válido'),
      ));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultadoPage(
          nuevoNombreArchivo: _generateFileName(),
          audioFilePath: audioFileName!,
          jsonString: jsonEncode(_buildJsonData()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Etiquetar sonido')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildDropdown(
                  label: 'Hospital',
                  items: hospitalMap.keys.toList(),
                  onChanged: (v) => setState(() => hospital = v),
                ),
                _buildDropdown(
                  label: 'Consultorio',
                  items: consultorioMap.keys.toList(),
                  onChanged: (v) => setState(() => consultorio = v),
                ),
                _buildDropdown(
                  label: 'Estado del sonido',
                  items: ['Normal', 'Anormal'],
                  onChanged: (v) => setState(() => estado = v),
                ),
                _buildDropdown(
                  label: 'Foco de auscultación',
                  items: focoMap.keys.toList(),
                  onChanged: (v) => setState(() => focoAuscultacion = v),
                ),
                _buildDatePicker(),
                _buildOptionalTextField(),
                AudioFilePicker(onFileSelected: onFileSelected),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Enviar'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      items: items
          .map((opcion) => DropdownMenuItem(
                value: opcion,
                child: Text(opcion),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Selecciona una opción' : null,
    );
  }

  Widget _buildDatePicker() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Fecha de nacimiento'),
      readOnly: true,
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) setState(() => selectedDate = pickedDate);
      },
      controller: TextEditingController(
        text: selectedDate?.toIso8601String().split('T').first ?? '',
      ),
      validator: (v) => selectedDate == null ? 'Selecciona una fecha' : null,
    );
  }

  Widget _buildOptionalTextField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: 'Diagnóstico (Opcional)'),
      onChanged: (v) => setState(() => textoOpcional = v),
      maxLines: 3,
    );
  }
}
