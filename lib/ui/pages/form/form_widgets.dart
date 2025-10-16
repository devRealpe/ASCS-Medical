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
  required bool mostrarSelectorHospital, // Nuevo parámetro
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
            // Tarjeta de ubicación
            Card(
              elevation: 3,
              shadowColor: primaryColor.withAlpha((0.15 * 255).toInt()),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    buildSectionHeader(
                      icon: Icons.location_on,
                      title: 'Ubicación del paciente',
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 24),
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

            // Tarjeta de información médica
            Card(
              elevation: 3,
              shadowColor: primaryColor.withAlpha((0.15 * 255).toInt()),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    buildSectionHeader(
                      icon: Icons.medical_services,
                      title: 'Información médica',
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 24),
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
                    // Foco de auscultación con botón de ayuda
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
                        const SizedBox(width: 8),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: primaryColor.withAlpha((0.1 * 255).toInt()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.info_outline, color: primaryColor),
                            tooltip: 'Ver focos de auscultación',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: primaryColor.withAlpha(
                                                    (0.1 * 255).toInt()),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                Icons.hearing,
                                                color: primaryColor,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Expanded(
                                              child: Text(
                                                'Focos de auscultación',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.asset(
                                            'assets/imagenes/foco_auscultacion.jpg',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryColor,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              'Cerrar',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
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

            // Tarjeta de información adicional
            Card(
              elevation: 3,
              shadowColor: primaryColor.withAlpha((0.15 * 255).toInt()),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    buildSectionHeader(
                      icon: Icons.note_add,
                      title: 'Información adicional',
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 24),
                    buildOptionalTextField(
                      textoOpcional: textoOpcional,
                      onChanged: onTextoOpcionalChanged,
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 24),
                    AudioFilePicker(
                      key: filePickerKey,
                      onFileSelected: onFileSelected,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Botón de envío mejorado
            SizedBox(
              width: double.infinity,
              child: buildSubmitButton(
                onSubmit: onSubmit,
                primaryColor: primaryColor,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

// Widgets auxiliares
Widget buildSectionHeader({
  required IconData icon,
  required String title,
  required Color primaryColor,
  required Color textColor,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          primaryColor.withAlpha((0.08 * 255).toInt()),
          primaryColor.withAlpha((0.03 * 255).toInt()),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border(
        left: BorderSide(
          color: primaryColor,
          width: 4,
        ),
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withAlpha((0.15 * 255).toInt()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
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
      labelStyle: TextStyle(
        color: textColor.withAlpha((0.7 * 255).toInt()),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withAlpha((0.1 * 255).toInt()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: primaryColor,
          size: 20,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryColor, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 2.5),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    items: items
        .map((opcion) => DropdownMenuItem(
              value: opcion,
              child: Text(
                opcion,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ))
        .toList(),
    onChanged: onChanged,
    validator: (v) => v == null ? 'Selecciona una opción' : null,
    style: TextStyle(color: textColor, fontSize: 15),
    dropdownColor: cardColor,
    icon: Icon(Icons.keyboard_arrow_down, color: primaryColor, size: 24),
    borderRadius: BorderRadius.circular(14),
    elevation: 4,
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
      labelStyle: TextStyle(
        color: textColor.withAlpha((0.7 * 255).toInt()),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withAlpha((0.1 * 255).toInt()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.calendar_today,
          color: primaryColor,
          size: 20,
        ),
      ),
      suffixIcon: selectedDate != null
          ? Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha((0.1 * 255).toInt()),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: primaryColor,
                size: 16,
              ),
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryColor, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 2.5),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    readOnly: true,
    onTap: () async {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedDate ?? DateTime.now(),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
      text: selectedDate != null
          ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
          : '',
    ),
    validator: (v) => selectedDate == null ? 'Selecciona una fecha' : null,
    style: TextStyle(
      color: textColor,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
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
      labelStyle: TextStyle(
        color: textColor.withAlpha((0.7 * 255).toInt()),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withAlpha((0.1 * 255).toInt()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.notes,
          color: primaryColor,
          size: 20,
        ),
      ),
      hintText: 'Escribe observaciones o diagnóstico aquí...',
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryColor, width: 2.5),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      alignLabelWithHint: true,
    ),
    onChanged: onChanged,
    maxLines: 4,
    minLines: 3,
    style: TextStyle(
      color: textColor,
      fontSize: 15,
      height: 1.5,
    ),
    initialValue: textoOpcional,
    textCapitalization: TextCapitalization.sentences,
  );
}

Widget buildSubmitButton({
  required Function() onSubmit,
  required Color primaryColor,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withAlpha((0.3 * 255).toInt()),
          blurRadius: 15,
          offset: const Offset(0, 6),
          spreadRadius: 0,
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: onSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).toInt()),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send, size: 18),
          ),
          const SizedBox(width: 12),
          const Text(
            'ENVIAR DATOS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}
