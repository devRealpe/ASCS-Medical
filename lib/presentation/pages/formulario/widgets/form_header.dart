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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: MedicalColors.primaryBlue,
      elevation: 4,
      shadowColor: MedicalColors.primaryBlue.withAlpha((0.4 * 255).toInt()),
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MedicalColors.primaryBlue,
              MedicalColors.primaryBlue.withAlpha((0.85 * 255).toInt()),
            ],
          ),
        ),
      ),
      titleSpacing: 12,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withAlpha((0.3 * 255).toInt()),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.favorite_border,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Etiquetado Cardíaco',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        const StorageToggleWidget(),
        const SizedBox(width: 4),
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.15 * 255).toInt()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white, size: 21),
            onPressed: onInfoPressed,
            tooltip: 'Información',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ),
      ],
    );
  }
}
