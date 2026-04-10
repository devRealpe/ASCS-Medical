import 'package:equatable/equatable.dart';

class Enfermedad extends Equatable {
  final int? id;
  final String nombre;
  final String codigo;

  const Enfermedad({
    this.id,
    required this.nombre,
    required this.codigo,
  });

  @override
  List<Object?> get props => [id, nombre, codigo];
}
