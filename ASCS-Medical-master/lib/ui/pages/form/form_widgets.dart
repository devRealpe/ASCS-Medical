import 'package:flutter/material.dart';
import 'form_audio_file_picker.dart';

Widget buildFormContent({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required List<String> consultorioList,
  required String? consultorio,
  required Map<String, String> focoMap,
  required String? estado,
  required String? focoAuscultacion,
  required DateTime? selectedDate,
  required String? textoOpcional,
  required String? audioFileName,
  required Key filePickerKey,
  required Color primaryColor,
  required Color backgroundColor,
  required Color cardColor,
  required Color textColor,
  required Map<String, String> hospitalMap,
  required String? hospital,
  required Function(String?) onHospitalChanged,
  required Function(String?) onConsultorioChanged,
  required Function(String?) onEstadoChanged,
  required Function(String?) onFocoChanged,
  required Function(DateTime?) onDateChanged,
  required Function(String?) onTextoOpcionalChanged,
  required Function(String) onFileSelected,
  required Function() onSubmit,
}) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    buildSectionHeader(
                        icon: Icons.location_on,
                        title: 'Ubicación del paciente',
                        primaryColor: primaryColor,
                        textColor: textColor),
                    const SizedBox(height: 20),
                    buildDropdown(
                      label: 'Hospital',
                      icon: Icons.local_hospital,
                      items: hospitalMap.keys.toList(),
                      value: hospital,
                      onChanged: onHospitalChanged,
                      primaryColor: primaryColor,
                      textColor: textColor,
                      cardColor: cardColor,
                    ),
                    const SizedBox(height: 20),
                    buildDropdown(
                      label: 'Consultorio',
                      icon: Icons.meeting_room,
                      items: consultorioList,
                      value: consultorio,
                      onChanged: onConsultorioChanged,
                      primaryColor: primaryColor,
                      textColor: textColor,
                      cardColor: cardColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    buildSectionHeader(
                      icon: Icons.medical_services,
                      title: 'Información médica',
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 20),
                    buildDropdown(
                      label: 'Estado del sonido',
                      icon: Icons.health_and_safety,
                      items: ['Normal', 'Anormal'],
                      value: estado,
                      onChanged: onEstadoChanged,
                      primaryColor: primaryColor,
                      textColor: textColor,
                      cardColor: cardColor,
                    ),
                    const SizedBox(height: 20),
// Aquí integramos el Row con el dropdown y el ícono de ayuda
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: buildDropdown(
                            label: 'Foco de auscultación',
                            icon: Icons.hearing,
                            items: focoMap.keys.toList(),
                            value: focoAuscultacion,
                            onChanged: onFocoChanged,
                            primaryColor: primaryColor,
                            textColor: textColor,
                            cardColor: cardColor,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.info_outline, color: primaryColor),
                          tooltip: 'Ver focos de auscultación',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Focos de auscultación'),
                                content: Image.asset(
                                  'assets/imagenes/foco_auscultacion.jpg', // Cambia la ruta si tu imagen está en otra carpeta
                                  fit: BoxFit.contain,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cerrar'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    buildDatePicker(
                      context: context,
                      selectedDate: selectedDate,
                      onDateChanged: onDateChanged,
                      primaryColor: primaryColor,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    buildSectionHeader(
                        icon: Icons.note_add,
                        title: 'Información adicional',
                        primaryColor: primaryColor,
                        textColor: textColor),
                    const SizedBox(height: 20),
                    buildOptionalTextField(
                      textoOpcional: textoOpcional,
                      onChanged: onTextoOpcionalChanged,
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 20),
                    AudioFilePicker(
                      key: filePickerKey,
                      onFileSelected: onFileSelected,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: primaryColor.withAlpha((0.3 * 255).toInt()),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'ENVIAR DATOS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildSectionHeader({
  required IconData icon,
  required String title,
  required Color primaryColor,
  required Color textColor,
}) {
  return Row(
    children: [
      Icon(icon, color: primaryColor),
      const SizedBox(width: 10),
      Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    ],
  );
}

Widget buildDropdown({
  required String label,
  required IconData icon,
  required List<String> items,
  required String? value,
  required Function(String?) onChanged,
  required Color primaryColor,
  required Color textColor,
  required Color cardColor,
}) {
  return DropdownButtonFormField<String>(
    value: value,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: textColor.withAlpha((0.7 * 255).toInt())),
      prefixIcon: Icon(icon, color: primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    ),
    items: items
        .map((opcion) => DropdownMenuItem(
              value: opcion,
              child: Text(opcion),
            ))
        .toList(),
    onChanged: onChanged,
    validator: (v) => v == null ? 'Selecciona una opción' : null,
    style: TextStyle(color: textColor),
    dropdownColor: cardColor,
    icon: Icon(Icons.arrow_drop_down, color: primaryColor),
    borderRadius: BorderRadius.circular(12),
  );
}

Widget buildDatePicker({
  required BuildContext context,
  required DateTime? selectedDate,
  required Function(DateTime?) onDateChanged,
  required Color primaryColor,
  required Color cardColor,
  required Color textColor,
}) {
  return TextFormField(
    decoration: InputDecoration(
      labelText: 'Fecha de nacimiento',
      labelStyle: TextStyle(color: textColor.withAlpha((0.7 * 255).toInt())),
      prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    ),
    readOnly: true,
    onTap: () async {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: primaryColor,
                onPrimary: Colors.white,
                surface: cardColor,
                onSurface: textColor,
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: cardColor,
              ),
            ),
            child: child!,
          );
        },
      );
      if (pickedDate != null) {
        onDateChanged(pickedDate);
      }
    },
    controller: TextEditingController(
      text: selectedDate?.toLocal().toString().split(' ')[0] ?? '',
    ),
    validator: (v) => selectedDate == null ? 'Selecciona una fecha' : null,
    style: TextStyle(color: textColor),
  );
}

Widget buildOptionalTextField({
  required String? textoOpcional,
  required Function(String?) onChanged,
  required Color primaryColor,
  required Color textColor,
}) {
  return TextFormField(
    decoration: InputDecoration(
      labelText: 'Diagnóstico (Opcional)',
      labelStyle: TextStyle(color: textColor.withAlpha((0.7 * 255).toInt())),
      prefixIcon: Icon(Icons.notes, color: primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    ),
    onChanged: onChanged,
    maxLines: 3,
    style: TextStyle(color: textColor),
    initialValue: textoOpcional,
  );
}
