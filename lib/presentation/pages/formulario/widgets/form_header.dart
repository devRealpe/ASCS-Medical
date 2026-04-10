// lib/presentation/pages/formulario/widgets/form_header.dart

import 'package:flutter/material.dart';
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
      title: const Text('Etiquetado Cardíaco'),
      actions: [
        const StorageToggleWidget(),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.help_outline, size: 21),
          onPressed: onInfoPressed,
          tooltip: 'Información',
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
