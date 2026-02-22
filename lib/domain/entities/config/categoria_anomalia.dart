import 'package:equatable/equatable.dart';

class CategoriaAnomalia extends Equatable {
  final String nombre;
  final String codigo;

  const CategoriaAnomalia({
    required this.nombre,
    required this.codigo,
  });

  @override
  List<Object?> get props => [nombre, codigo];
}
