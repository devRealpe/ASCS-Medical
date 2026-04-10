// lib/domain/entities/config/hospital.dart
import 'package:equatable/equatable.dart';

class Hospital extends Equatable {
  final int? id;
  final String nombre;
  final String codigo;

  const Hospital({
    this.id,
    required this.nombre,
    required this.codigo,
  });

  @override
  List<Object?> get props => [id, nombre, codigo];
}




//