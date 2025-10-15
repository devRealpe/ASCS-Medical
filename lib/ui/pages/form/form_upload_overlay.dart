import 'package:flutter/material.dart';
import 'dart:math' as math;

class FormUploadOverlay extends StatefulWidget {
  final double uploadProgress;
  final String uploadStatus;
  final Color primaryColor;
  final Color successColor;
  final Color textColor;
  final Color cardColor;

  const FormUploadOverlay({
    super.key,
    required this.uploadProgress,
    required this.uploadStatus,
    required this.primaryColor,
    required this.successColor,
    required this.textColor,
    required this.cardColor,
  });

  @override
  State<FormUploadOverlay> createState() => _FormUploadOverlayState();
}

class _FormUploadOverlayState extends State<FormUploadOverlay>
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
    final isComplete = widget.uploadProgress >= 1.0;

    return Container(
      color: Colors.black.withAlpha((0.75 * 255).toInt()),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.cardColor,
                      widget.cardColor.withAlpha((0.95 * 255).toInt()),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.2 * 255).toInt()),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicador circular animado
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Círculo de fondo con rotación
                          if (!isComplete)
                            AnimatedBuilder(
                              animation: _rotationController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle:
                                      _rotationController.value * 2 * math.pi,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: SweepGradient(
                                        colors: [
                                          widget.primaryColor
                                              .withAlpha((0.1 * 255).toInt()),
                                          widget.primaryColor
                                              .withAlpha((0.3 * 255).toInt()),
                                          widget.primaryColor
                                              .withAlpha((0.1 * 255).toInt()),
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                          // Progreso circular
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: TweenAnimationBuilder<double>(
                              tween:
                                  Tween(begin: 0.0, end: widget.uploadProgress),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              builder: (context, progress, child) {
                                return CustomPaint(
                                  painter: _CircularProgressPainter(
                                    progress: progress,
                                    color: isComplete
                                        ? widget.successColor
                                        : widget.primaryColor,
                                    backgroundColor: Colors.grey.shade200,
                                  ),
                                );
                              },
                            ),
                          ),

                          // Ícono central con animación
                          TweenAnimationBuilder<double>(
                            tween:
                                Tween(begin: 0.0, end: isComplete ? 1.0 : 0.0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 0.5 + (value * 0.5),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: (isComplete
                                            ? widget.successColor
                                            : widget.primaryColor)
                                        .withAlpha((0.15 * 255).toInt()),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isComplete
                                        ? Icons.check_circle
                                        : Icons.cloud_upload,
                                    size: 40,
                                    color: isComplete
                                        ? widget.successColor
                                        : widget.primaryColor,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Estado de carga
                    Text(
                      widget.uploadStatus,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Barra de progreso lineal mejorada
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: widget.uploadProgress),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          builder: (context, progress, child) {
                            return LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isComplete
                                    ? widget.successColor
                                    : widget.primaryColor,
                              ),
                              minHeight: 8,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Porcentaje con animación
                    TweenAnimationBuilder<double>(
                      tween:
                          Tween(begin: 0.0, end: widget.uploadProgress * 100),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      builder: (context, percentage, child) {
                        return Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isComplete
                                ? widget.successColor
                                : widget.primaryColor,
                            letterSpacing: 1.2,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Mensaje adicional
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: (isComplete
                                ? widget.successColor
                                : widget.primaryColor)
                            .withAlpha((0.08 * 255).toInt()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isComplete ? Icons.check : Icons.info_outline,
                            size: 16,
                            color: isComplete
                                ? widget.successColor
                                : widget.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              isComplete
                                  ? 'Datos enviados correctamente'
                                  : 'Por favor, no cierres esta ventana',
                              style: TextStyle(
                                fontSize: 13,
                                color: isComplete
                                    ? widget.successColor
                                    : widget.primaryColor,
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
            );
          },
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 8.0;

    // Círculo de fondo
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Círculo de progreso
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withAlpha((0.5 * 255).toInt()),
          color,
          color,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
