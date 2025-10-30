// lib/presentation/pages/formulario/widgets/form_fields.dart
import 'package:flutter/material.dart';
import '../../../../domain/entities/config/medical_config.dart';
import '../../../theme/medical_colors.dart';

class FormFields extends StatelessWidget {
  final MedicalConfig config;
  final String? hospital;
  final String? consultorio;
  final String? estado;
  final String? focoAuscultacion;
  final DateTime? selectedDate;
  final String? observaciones;
  final bool mostrarSelectorHospital;
  final Function(String?) onHospitalChanged;
  final Function(String?) onConsultorioChanged;
  final Function(String?) onEstadoChanged;
  final Function(String?) onFocoChanged;
  final Function(DateTime?) onDateChanged;
  final Function(String?) onObservacionesChanged;

  const FormFields({
    super.key,
    required this.config,
    required this.hospital,
    required this.consultorio,
    required this.estado,
    required this.focoAuscultacion,
    required this.selectedDate,
    required this.observaciones,
    required this.mostrarSelectorHospital,
    required this.onHospitalChanged,
    required this.onConsultorioChanged,
    required this.onEstadoChanged,
    required this.onFocoChanged,
    required this.onDateChanged,
    required this.onObservacionesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tarjeta de ubicación
        _buildCard(
          title: 'Ubicación del paciente',
          icon: Icons.location_on,
          children: [
            if (mostrarSelectorHospital) ...[
              _buildDropdown(
                label: 'Hospital',
                icon: Icons.local_hospital,
                items: config.hospitales.map((h) => h.nombre).toList(),
                value: hospital,
                onChanged: onHospitalChanged,
              ),
              const SizedBox(height: 20),
            ],
            _buildDropdown(
              label: 'Consultorio',
              icon: Icons.meeting_room,
              items: _getConsultoriosDisponibles(),
              value: consultorio,
              onChanged: onConsultorioChanged,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Tarjeta de información médica
        _buildCard(
          title: 'Información médica',
          icon: Icons.medical_services,
          children: [
            _buildDropdown(
              label: 'Estado del sonido',
              icon: Icons.health_and_safety,
              items: const ['Normal', 'Anormal'],
              value: estado,
              onChanged: onEstadoChanged,
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Foco de auscultación',
                    icon: Icons.hearing,
                    items: config.focos.map((f) => f.nombre).toList(),
                    value: focoAuscultacion,
                    onChanged: onFocoChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: MedicalColors.primaryBlue
                        .withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.info_outline,
                      color: MedicalColors.primaryBlue,
                    ),
                    tooltip: 'Ver focos de auscultación',
                    onPressed: () => _showFocosDialog(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDatePicker(context),
          ],
        ),
        const SizedBox(height: 20),

        // Tarjeta de información adicional
        _buildCard(
          title: 'Información adicional',
          icon: Icons.note_add,
          children: [
            _buildObservacionesField(),
          ],
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: MedicalColors.cardWhite,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSectionHeader(title, icon),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MedicalColors.primaryBlue.withAlpha((0.08 * 255).toInt()),
            MedicalColors.primaryBlue.withAlpha((0.03 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: MedicalColors.primaryBlue, width: 4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MedicalColors.primaryBlue.withAlpha((0.15 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: MedicalColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MedicalColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: MedicalColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MedicalColors.primaryBlue.withAlpha((0.1 * 255).toInt()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: MedicalColors.primaryBlue, size: 20),
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
          borderSide:
              const BorderSide(color: MedicalColors.primaryBlue, width: 2.5),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    color: MedicalColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Selecciona una opción' : null,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: MedicalColors.primaryBlue,
      ),
      borderRadius: BorderRadius.circular(14),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Fecha de nacimiento',
        labelStyle: const TextStyle(
          color: MedicalColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MedicalColors.primaryBlue.withAlpha((0.1 * 255).toInt()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.calendar_today,
            color: MedicalColors.primaryBlue,
            size: 20,
          ),
        ),
        suffixIcon: selectedDate != null
            ? Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      MedicalColors.primaryBlue.withAlpha((0.1 * 255).toInt()),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: MedicalColors.primaryBlue,
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
          borderSide:
              const BorderSide(color: MedicalColors.primaryBlue, width: 2.5),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      readOnly: true,
      onTap: () => _selectDate(context),
      controller: TextEditingController(
        text: selectedDate != null
            ? '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}'
            : '',
      ),
      validator: (v) => selectedDate == null ? 'Selecciona una fecha' : null,
      style: const TextStyle(
        color: MedicalColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MedicalColors.primaryBlue,
              onPrimary: Colors.white,
              surface: MedicalColors.cardWhite,
              onSurface: MedicalColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      onDateChanged(pickedDate);
    }
  }

  Widget _buildObservacionesField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Diagnóstico (Opcional)',
        labelStyle: const TextStyle(
          color: MedicalColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MedicalColors.primaryBlue.withAlpha((0.1 * 255).toInt()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.notes,
            color: MedicalColors.primaryBlue,
            size: 20,
          ),
        ),
        hintText: 'Escribe observaciones o diagnóstico aquí...',
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
          borderSide:
              const BorderSide(color: MedicalColors.primaryBlue, width: 2.5),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        alignLabelWithHint: true,
      ),
      onChanged: onObservacionesChanged,
      maxLines: 4,
      minLines: 3,
      initialValue: observaciones,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  List<String> _getConsultoriosDisponibles() {
    if (hospital == null) return [];

    final hospitalEntity = config.getHospitalPorNombre(hospital!);
    if (hospitalEntity == null) return [];

    return config
        .getConsultoriosPorHospital(hospitalEntity.codigo)
        .map((c) => c.nombre)
        .toList();
  }

  void _showFocosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      color: MedicalColors.primaryBlue
                          .withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.hearing,
                      color: MedicalColors.primaryBlue,
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
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/imagenes/foco_auscultacion.jpg',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedicalColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
