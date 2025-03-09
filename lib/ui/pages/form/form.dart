import 'package:flutter/material.dart';
import '../../pages/form/widget.dart';
import '../../pages/result_page/result_page.dart';
import 'dart:convert';

class FormularioCompletoPage extends StatefulWidget {
  const FormularioCompletoPage({super.key});

  @override
  FormularioCompletoPageState createState() => FormularioCompletoPageState();
}

class FormularioCompletoPageState extends State<FormularioCompletoPage> {
  final _formKey = GlobalKey<FormState>();
  String? hospital;
  String? consultorio;
  String? estado;
  String? focoAuscultacion;
  DateTime? selectedDate;
  String? textoOpcional;
  String? audioFileName;
  String idAudio = '1234';

  void onFileSelected(String filePath) {
    setState(() {
      audioFileName = filePath;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Etiquetar sonido'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Dropdown 1
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Hospital'),
                  items: ['Departamental']
                      .map((opcion) => DropdownMenuItem(
                            value: opcion,
                            child: Text(opcion),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      hospital = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Por favor selecciona una opción' : null,
                ),
                // Dropdown 2
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Consultorio'),
                  items: ['101 A', '102 B', '103 C']
                      .map((opcion) => DropdownMenuItem(
                            value: opcion,
                            child: Text(opcion),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      consultorio = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Por favor selecciona una opción' : null,
                ),
                // Dropdown 3
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Estado del sonido'),
                  items: ['Normal', 'Anormal']
                      .map((opcion) => DropdownMenuItem(
                            value: opcion,
                            child: Text(opcion),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      estado = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Por favor selecciona una opción' : null,
                ),
                // Dropdown 4
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Foco de auscultación'),
                  items: ['Aórtico', 'Pulmonar', 'Tricuspídeo', 'Mitral']
                      .map((opcion) => DropdownMenuItem(
                            value: opcion,
                            child: Text(opcion),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      focoAuscultacion = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Por favor selecciona una opción' : null,
                ),
                // Date Picker
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: 'Fecha de nacimiento'),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                  controller: TextEditingController(
                    text: selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : '',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Selecciona una fecha'
                      : null,
                ),
                // Campo de texto opcional
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Diagnostico (Opcional)'),
                  onChanged: (value) {
                    setState(() {
                      textoOpcional = value;
                    });
                  },
                ),
                // Campo para subir archivo de audio
                AudioFilePicker(onFileSelected: (filePath) {
                  setState(() {
                    audioFileName = filePath;
                  });
                }),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() &&
                        audioFileName != null) {
                      // Generar el nuevo nombre del archivo según las opciones seleccionadas
                      String dia = selectedDate != null
                          ? selectedDate!.day.toString().padLeft(2, '0')
                          : '00';
                      String mes = selectedDate != null
                          ? selectedDate!.month.toString().padLeft(2, '0')
                          : '00';
                      String anio = selectedDate != null
                          ? selectedDate!.year.toString().substring(2, 4)
                          : '00';

                      String consultorioName = '00';
                      switch (consultorio) {
                        case '101 A':
                          consultorioName = '01';
                          break;
                        case '102 B':
                          consultorioName = '02';
                          break;
                        case '103 C':
                          consultorioName = '03';
                          break;
                      }

                      String hospitalName = '00';
                      if (hospital == 'Departamental') {
                        hospitalName = '01';
                      }

                      String focoAuscultacionName = '00';
                      switch (focoAuscultacion) {
                        case 'Aórtico':
                          focoAuscultacionName = '01';
                          break;
                        case 'Pulmonar':
                          focoAuscultacionName = '02';
                          break;
                        case 'Tricuspídeo':
                          focoAuscultacionName = '03';
                          break;
                        case 'Mitral':
                          focoAuscultacionName = '04';
                          break;
                      }

                      int edad = selectedDate != null
                          ? DateTime.now().year - selectedDate!.year
                          : 0;
                      String diagnostico =
                          textoOpcional != null && textoOpcional!.isNotEmpty
                              ? '01'
                              : '00';

                      String nuevoNombreArchivo =
                          '${dia}${mes}${anio}-${consultorioName}${hospitalName}-${focoAuscultacionName}-${idAudio}-${edad.toString().padLeft(2, '0')}${diagnostico}.wav';

                      if (textoOpcional == null) {
                        textoOpcional = "No aplica";
                      }

                      // Crear el JSON con los datos especificados
                      Map<String, dynamic> jsonData = {
                        "DD": dia,
                        "MM": mes,
                        "AA": anio,
                        "IDID": idAudio,
                        "CS": consultorio,
                        "HS": hospital,
                        "FA": focoAuscultacion,
                        "ES": textoOpcional,
                        "URL": "url"
                      };

                      String jsonString = jsonEncode(jsonData);

                      // Navegar a la página de resultado y pasar el nuevo nombre del archivo, el path del archivo original y el JSON
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultadoPage(
                            nuevoNombreArchivo: nuevoNombreArchivo,
                            audioFilePath: audioFileName!,
                            jsonString: jsonString,
                          ),
                        ),
                      );

                      // Procesar datos aquí
                      print('Opción 1: $hospital');
                      print('Opción 2: $consultorio');
                      print('Opción 3: $estado');
                      print('Opción 4: $focoAuscultacion');
                      print('Fecha: ${selectedDate?.toString()}');
                      print('Texto Opcional: $textoOpcional');
                      print('Audio File: $audioFileName');
                    } else if (audioFileName == null) {
                      // Mostrar mensaje de error si no se seleccionó archivo de audio
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Por favor selecciona un archivo de audio (.wav)'),
                        ),
                      );
                    }
                  },
                  child: const Text('Enviar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
