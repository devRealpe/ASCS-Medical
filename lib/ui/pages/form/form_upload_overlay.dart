import 'package:flutter/material.dart';

class FormUploadOverlay extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha((0.7 * 255).toInt()),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.1 * 255).toInt()),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          width: MediaQuery.of(context).size.width * 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: uploadProgress,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                    Icon(
                      uploadProgress < 1.0
                          ? Icons.cloud_upload
                          : Icons.check_circle,
                      size: 30,
                      color: uploadProgress < 1.0 ? primaryColor : successColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                uploadStatus,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              LinearProgressIndicator(
                value: uploadProgress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 15),
              Text(
                '${(uploadProgress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
