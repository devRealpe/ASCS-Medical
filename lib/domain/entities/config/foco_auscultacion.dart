// lib/domain/entities/config/foco_auscultacion.dart
import 'package:equatable/equatable.dart';

class FocoAuscultacion extends Equatable {
  final int? id;
  final String nombre;
  final String codigo;

  const FocoAuscultacion({
    this.id,
    required this.nombre,
    required this.codigo,
  });

  @override
  List<Object?> get props => [id, nombre, codigo];
}
