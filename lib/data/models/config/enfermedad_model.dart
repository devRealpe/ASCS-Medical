// lib/data/models/config/enfermedad_model.dart
import '../../../domain/entities/config/enfermedad.dart';

class EnfermedadModel extends Enfermedad {
  const EnfermedadModel({
    super.id,
    required super.nombre,
    required super.codigo,
  });

  factory EnfermedadModel.fromJson(Map<String, dynamic> json) {
    return EnfermedadModel(
      id: json['id'] as int?,
      nombre: json['nombre'] as String? ?? '',
      codigo: (json['id'] ?? json['codigo'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'codigo': codigo,
    };
  }
}
