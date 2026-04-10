// lib/data/models/config/foco_auscultacion_model.dart
import '../../../domain/entities/config/foco_auscultacion.dart';

class FocoAuscultacionModel extends FocoAuscultacion {
  const FocoAuscultacionModel({
    super.id,
    required super.nombre,
    required super.codigo,
  });

  factory FocoAuscultacionModel.fromJson(Map<String, dynamic> json) {
    return FocoAuscultacionModel(
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
