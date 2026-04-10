// lib/data/models/config/categoria_anomalia_model.dart
import '../../../domain/entities/config/categoria_anomalia.dart';

class CategoriaAnomaliaModel extends CategoriaAnomalia {
  const CategoriaAnomaliaModel({
    super.id,
    required super.nombre,
    required super.codigo,
  });

  factory CategoriaAnomaliaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaAnomaliaModel(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'codigo': codigo,
    };
  }
}
