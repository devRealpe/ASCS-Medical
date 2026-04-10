// lib/presentation/pages/formulario/widgets/upload_overlay.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../theme/medical_colors.dart';

class UploadOverlay extends StatefulWidget {
  final double progress;
  final String status;

  const UploadOverlay({
    super.key,
    required this.progress,
    required this.status,
  });

  @override
  State<UploadOverlay> createState() => _UploadOverlayState();
}

class _UploadOverlayState extends State<UploadOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = widget.progress >= 1.0;
    final primary = context.primary;
    final accentColor = isComplete ? MedicalColors.successGreen : primary;
    final theme = Theme.of(context);

    return Container(
      color: Colors.black.withAlpha(190),
      child: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicador circular
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!isComplete)
                        AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationController.value * 2 * math.pi,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors: [
                                      primary.withAlpha(25),
                                      primary.withAlpha(75),
                                      primary.withAlpha(25),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: widget.progress,
                          strokeWidth: 8,
                          backgroundColor: context.divider,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                      ),
                      Icon(
                        isComplete ? Icons.check_circle : Icons.cloud_upload,
                        size: 40,
                        color: accentColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  widget.status,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.divider,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: widget.progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${(widget.progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isComplete ? Icons.check : Icons.info_outline,
                        size: 16,
                        color: accentColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isComplete
                              ? 'Datos enviados correctamente'
                              : 'Por favor, no cierres esta ventana',
                          style: TextStyle(
                            fontSize: 13,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
