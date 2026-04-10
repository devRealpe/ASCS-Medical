// lib/data/models/diagnostico/diagnostico_model.dart

import 'package:equatable/equatable.dart';

/// Un diagnóstico individual
class DiagnosticoModel extends Equatable {
  final int id;
  final String? creadoEn;
  final String? institucion;
  final bool esNormal;
  final bool verificado;
  final bool valvulopatia;
  final int? edad;
  final String? genero;
  final int? focoId;
  final String? focoNombre;
  final int? categoriaAnomaliaId;
  final String? categoriaAnomaliaNombre;

  const DiagnosticoModel({
    required this.id,
    this.creadoEn,
    this.institucion,
    this.esNormal = false,
    this.verificado = false,
    this.valvulopatia = false,
    this.edad,
    this.genero,
    this.focoId,
    this.focoNombre,
    this.categoriaAnomaliaId,
    this.categoriaAnomaliaNombre,
  });

  factory DiagnosticoModel.fromJson(Map<String, dynamic> json) {
    return DiagnosticoModel(
      id: json['id'] as int,
      creadoEn: json['creadoEn'] as String?,
      institucion: json['institucion'] as String?,
      esNormal: json['esNormal'] as bool? ?? false,
      verificado: json['verificado'] as bool? ?? false,
      valvulopatia: json['valvulopatia'] as bool? ?? false,
      edad: json['edad'] as int?,
      genero: json['genero'] as String?,
      focoId: json['focoId'] as int?,
      focoNombre: json['focoNombre'] as String?,
      categoriaAnomaliaId: json['categoriaAnomaliaId'] as int?,
      categoriaAnomaliaNombre: json['categoriaAnomaliaNombre'] as String?,
    );
  }

  DiagnosticoModel copyWith({
    bool? verificado,
    bool? valvulopatia,
  }) {
    return DiagnosticoModel(
      id: id,
      creadoEn: creadoEn,
      institucion: institucion,
      esNormal: esNormal,
      verificado: verificado ?? this.verificado,
      valvulopatia: valvulopatia ?? this.valvulopatia,
      edad: edad,
      genero: genero,
      focoId: focoId,
      focoNombre: focoNombre,
      categoriaAnomaliaId: categoriaAnomaliaId,
      categoriaAnomaliaNombre: categoriaAnomaliaNombre,
    );
  }

  @override
  List<Object?> get props => [id, verificado, valvulopatia];
}

/// Grupo de diagnósticos de un creador
class DiagnosticoGrupoModel extends Equatable {
  final int? usuarioCreadorId;
  final String nombreUsuario;
  final int totalDiagnosticos;
  final List<DiagnosticoModel> diagnosticos;

  const DiagnosticoGrupoModel({
    this.usuarioCreadorId,
    required this.nombreUsuario,
    required this.totalDiagnosticos,
    required this.diagnosticos,
  });

  factory DiagnosticoGrupoModel.fromJson(Map<String, dynamic> json) {
    final lista = (json['diagnosticos'] as List? ?? [])
        .map((d) => DiagnosticoModel.fromJson(d as Map<String, dynamic>))
        .toList();

    return DiagnosticoGrupoModel(
      usuarioCreadorId: json['usuarioCreadorId'] as int?,
      nombreUsuario: json['nombreUsuario'] as String? ?? 'SIN_USUARIO',
      totalDiagnosticos: json['totalDiagnosticos'] as int? ?? lista.length,
      diagnosticos: lista,
    );
  }

  @override
  List<Object?> get props =>
      [usuarioCreadorId, nombreUsuario, totalDiagnosticos];
}
