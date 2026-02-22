// lib/presentation/pages/formulario/widgets/form_fields.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/entities/config/medical_config.dart';
import '../../../theme/medical_colors.dart';

class FormFields extends StatefulWidget {
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

  // Nuevos callbacks
  final Function(String?) onGeneroChanged;
  final Function(double?) onPesoChanged;
  final Function(double?) onAlturaChanged;
  final Function(String?) onCategoriaAnomaliaChanged;

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
    required this.onGeneroChanged,
    required this.onPesoChanged,
    required this.onAlturaChanged,
    required this.onCategoriaAnomaliaChanged,
  });

  @override
  State<FormFields> createState() => FormFieldsState();
}

class FormFieldsState extends State<FormFields> {
  late TextEditingController _observacionesController;
  late TextEditingController _pesoController;
  late TextEditingController _alturaController;

  String? _generoSeleccionado;
  String? _categoriaAnomaliaSeleccionada;

  @override
  void initState() {
    super.initState();
    _observacionesController =
        TextEditingController(text: widget.observaciones);
    _pesoController = TextEditingController();
    _alturaController = TextEditingController();

    _observacionesController.addListener(() {
      widget.onObservacionesChanged(_observacionesController.text);
    });
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _pesoController.dispose();
    _alturaController.dispose();
    super.dispose();
  }

  void reset() {
    _observacionesController.clear();
    _pesoController.clear();
    _alturaController.clear();
    setState(() {
      _generoSeleccionado = null;
      _categoriaAnomaliaSeleccionada = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tarjeta de ubicación
        _buildCard(
          title: 'Ubicación del paciente',
          icon: Icons.location_on,
          children: [
            if (widget.mostrarSelectorHospital) ...[
              _buildDropdown(
                label: 'Hospital',
                icon: Icons.local_hospital,
                items: widget.config.hospitales.map((h) => h.nombre).toList(),
                value: widget.hospital,
                onChanged: widget.onHospitalChanged,
              ),
              const SizedBox(height: 20),
            ],
            _buildDropdown(
              label: 'Consultorio',
              icon: Icons.meeting_room,
              items: _getConsultoriosDisponibles(),
              value: widget.consultorio,
              onChanged: widget.onConsultorioChanged,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Tarjeta de datos del paciente
        _buildCard(
          title: 'Datos del paciente',
          icon: Icons.person,
          children: [
            // Fecha de nacimiento
            _buildDatePicker(context),
            const SizedBox(height: 20),

            // Género
            _buildGeneroSelector(),
            const SizedBox(height: 20),

            // Peso y Altura en fila
            Row(
              children: [
                Expanded(
                  child: _buildNumericField(
                    controller: _pesoController,
                    label: 'Peso (kg)',
                    icon: Icons.monitor_weight_outlined,
                    hint: 'Ej: 70.5',
                    onChanged: (v) {
                      widget.onPesoChanged(double.tryParse(v ?? ''));
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0 || val > 300) {
                        return 'Peso inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumericField(
                    controller: _alturaController,
                    label: 'Altura (cm)',
                    icon: Icons.height,
                    hint: 'Ej: 170',
                    onChanged: (v) {
                      widget.onAlturaChanged(double.tryParse(v ?? ''));
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0 || val > 300) {
                        return 'Altura inválida';
                      }
                      return null;
                    },
                  ),
                ),
              ],
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
              value: widget.estado,
              onChanged: widget.onEstadoChanged,
            ),
            const SizedBox(height: 20),

            // Categoría de anomalía (solo visible si estado es Anormal)
            if (widget.estado == 'Anormal') ...[
              _buildDropdownCategoriaAnomalia(),
              const SizedBox(height: 20),
            ],

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Foco de auscultación',
                    icon: Icons.hearing,
                    items: widget.config.focos.map((f) => f.nombre).toList(),
                    value: widget.focoAuscultacion,
                    onChanged: widget.onFocoChanged,
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
                    icon: const Icon(Icons.info_outline,
                        color: MedicalColors.primaryBlue),
                    tooltip: 'Ver focos de auscultación',
                    onPressed: () => _showFocosDialog(context),
                  ),
                ),
              ],
            ),
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

  // ─────────────────────────────── WIDGETS HELPERS ────────────────────────────

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
    bool required = true,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
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
      validator:
          required ? (v) => v == null ? 'Selecciona una opción' : null : null,
      icon: const Icon(Icons.keyboard_arrow_down,
          color: MedicalColors.primaryBlue),
      borderRadius: BorderRadius.circular(14),
    );
  }

  /// Dropdown específico para categoría de anomalía
  Widget _buildDropdownCategoriaAnomalia() {
    return DropdownButtonFormField<String>(
      value: _categoriaAnomaliaSeleccionada,
      decoration: InputDecoration(
        labelText: 'Categoría de anomalía',
        labelStyle: const TextStyle(
          color: MedicalColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MedicalColors.warningOrange.withAlpha((0.1 * 255).toInt()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.warning_amber_rounded,
              color: MedicalColors.warningOrange, size: 20),
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
              const BorderSide(color: MedicalColors.warningOrange, width: 2.5),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: widget.config.categoriasAnomalias
          .map((cat) => DropdownMenuItem(
                value: cat.nombre,
                child: Text(
                  cat.nombre,
                  style: const TextStyle(
                    color: MedicalColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ))
          .toList(),
      onChanged: (value) {
        setState(() => _categoriaAnomaliaSeleccionada = value);
        widget.onCategoriaAnomaliaChanged(value);
      },
      validator: (v) => v == null ? 'Selecciona una categoría' : null,
      icon: const Icon(Icons.keyboard_arrow_down,
          color: MedicalColors.warningOrange),
      borderRadius: BorderRadius.circular(14),
    );
  }

  /// Selector de género con botones M / F
  Widget _buildGeneroSelector() {
    return FormField<String>(
      initialValue: _generoSeleccionado,
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Selecciona el género' : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MedicalColors.primaryBlue
                        .withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.wc,
                      color: MedicalColors.primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Género',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: MedicalColors.textSecondary,
                  ),
                ),
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildGeneroButton(
                  label: 'Masculino',
                  value: 'M',
                  icon: Icons.male,
                  color: const Color(0xFF1565C0),
                  selected: _generoSeleccionado == 'M',
                  onTap: () {
                    setState(() => _generoSeleccionado = 'M');
                    field.didChange('M');
                    widget.onGeneroChanged('M');
                  },
                ),
                const SizedBox(width: 12),
                _buildGeneroButton(
                  label: 'Femenino',
                  value: 'F',
                  icon: Icons.female,
                  color: const Color(0xFFC2185B),
                  selected: _generoSeleccionado == 'F',
                  onTap: () {
                    setState(() => _generoSeleccionado = 'F');
                    field.didChange('F');
                    widget.onGeneroChanged('F');
                  },
                ),
              ],
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGeneroButton({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? color.withAlpha((0.12 * 255).toInt())
                : Colors.grey[50],
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: selected ? 2.5 : 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? color : Colors.grey.shade500, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? color : Colors.grey.shade600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumericField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: MedicalColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        hintText: hint,
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
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(
        color: MedicalColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
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
          child: const Icon(Icons.calendar_today,
              color: MedicalColors.primaryBlue, size: 20),
        ),
        suffixIcon: widget.selectedDate != null
            ? Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      MedicalColors.primaryBlue.withAlpha((0.1 * 255).toInt()),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check,
                    color: MedicalColors.primaryBlue, size: 16),
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
        text: widget.selectedDate != null
            ? '${widget.selectedDate!.day.toString().padLeft(2, '0')}/'
                '${widget.selectedDate!.month.toString().padLeft(2, '0')}/'
                '${widget.selectedDate!.year}'
            : '',
      ),
      validator: (v) =>
          widget.selectedDate == null ? 'Selecciona una fecha' : null,
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
      initialDate: widget.selectedDate ?? DateTime.now(),
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
      widget.onDateChanged(pickedDate);
    }
  }

  Widget _buildObservacionesField() {
    return TextFormField(
      controller: _observacionesController,
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
          child: const Icon(Icons.notes,
              color: MedicalColors.primaryBlue, size: 20),
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
      maxLines: 4,
      minLines: 3,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  List<String> _getConsultoriosDisponibles() {
    if (widget.hospital == null) return [];
    final hospitalEntity = widget.config.getHospitalPorNombre(widget.hospital!);
    if (hospitalEntity == null) return [];
    return widget.config
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
                    child: const Icon(Icons.hearing,
                        color: MedicalColors.primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Focos de auscultación',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
