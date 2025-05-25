class FormularioData {
  final DateTime fechaNacimiento;
  final int edad;
  final DateTime fechaGrabacion;

  final String hospital;
  final String codigoHospital;
  final String consultorio;
  final String codigoConsultorio;

  final String estado;
  final String focoAuscultacion;
  final String codigoFoco;
  final String observaciones;

  final String filePath;
  final String fileName;

  FormularioData({
    required this.fechaNacimiento,
    required this.edad,
    required this.fechaGrabacion,
    required this.hospital,
    required this.codigoHospital,
    required this.consultorio,
    required this.codigoConsultorio,
    required this.estado,
    required this.focoAuscultacion,
    required this.codigoFoco,
    required this.observaciones,
    required this.filePath,
    required this.fileName,
  });

  Map<String, dynamic> toJson() {
    return {
      "metadata": {
        'fechaNacimiento': fechaNacimiento.toIso8601String(),
        'edad': edad,
        'fechaGrabacion': fechaGrabacion.toIso8601String(),
      },
      "ubicacion": {
        'hospital': hospital,
        'codigoHospital': codigoHospital,
        'consultorio': consultorio,
        'codigoConsultorio': codigoConsultorio,
      },
      "diagnostico": {
        'estado': estado,
        'focoAuscultacion': focoAuscultacion,
        'codigoFoco': codigoFoco,
        'observaciones': observaciones,
      }
    };
  }
}
