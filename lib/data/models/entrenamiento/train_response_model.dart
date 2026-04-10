// lib/data/models/entrenamiento/train_response_model.dart

class TrainResponseModel {
  final String status;
  final String message;
  final int samplesTotal;
  final String label;
  final double valAcc;
  final String lastTrained;

  const TrainResponseModel({
    required this.status,
    required this.message,
    required this.samplesTotal,
    required this.label,
    required this.valAcc,
    required this.lastTrained,
  });

  factory TrainResponseModel.fromJson(Map<String, dynamic> json) {
    return TrainResponseModel(
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
      samplesTotal: json['samples_total'] as int? ?? 0,
      label: json['label'] as String? ?? '',
      valAcc: (json['val_acc'] as num?)?.toDouble() ?? 0.0,
      lastTrained: json['last_trained'] as String? ?? '',
    );
  }
}
