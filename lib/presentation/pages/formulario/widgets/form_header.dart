// lib/presentation/pages/formulario/widgets/form_header.dart

import 'package:flutter/material.dart';
import '../../../theme/medical_colors.dart';
import 'storage_toggle_widget.dart';

class FormHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onInfoPressed;

  const FormHeader({
    super.key,
    required this.onInfoPressed,
  });

  // Altura aumentada para acomodar SafeArea correctamente
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 20);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MedicalColors.primaryBlue,
            MedicalColors.primaryBlue.withAlpha((0.85 * 255).toInt()),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: MedicalColors.primaryBlue.withAlpha((0.3 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: Row(
          children: [
            // Ícono corazón
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.2 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withAlpha((0.3 * 255).toInt()),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.favorite_border,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Etiquetado Cardíaco',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Botón de configuración de almacenamiento
          const StorageToggleWidget(),
          const SizedBox(width: 6),
          // Botón de información
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.15 * 255).toInt()),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.help_outline,
                color: Colors.white,
                size: 22,
              ),
              onPressed: onInfoPressed,
              tooltip: 'Información',
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
