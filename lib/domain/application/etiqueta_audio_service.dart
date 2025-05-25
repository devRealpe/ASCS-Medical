class EtiquetaAudioService {
  final Map<String, String> consultorioMap = {
    '101 A': '01',
    '102 B': '02',
    '103 C': '03'
  };
  final Map<String, String> hospitalMap = {'Departamental': '01'};
  final Map<String, String> focoMap = {
    'Aórtico': '01',
    'Pulmonar': '02',
    'Tricuspídeo': '03',
    'Mitral': '04'
  };

  Map<String, dynamic> buildJsonData({
    required DateTime fechaNacimiento,
    required String? hospital,
    required String? consultorio,
    required String? estado,
    required String? focoAuscultacion,
    String? observaciones,
  }) {
    final edad = DateTime.now().difference(fechaNacimiento).inDays ~/ 365;

    return {
      "metadata": {
        "fecha_nacimiento": fechaNacimiento.toIso8601String(),
        "edad": edad,
        "fecha_grabacion": DateTime.now().toIso8601String()
      },
      "ubicacion": {
        "hospital": hospital,
        "codigo_hospital": hospitalMap[hospital] ?? '00',
        "consultorio": consultorio,
        "codigo_consultorio": consultorioMap[consultorio] ?? '00'
      },
      "diagnostico": {
        "estado": estado,
        "foco_auscultacion": focoAuscultacion,
        "codigo_foco": focoMap[focoAuscultacion] ?? '00',
        "observaciones": observaciones ?? "No aplica"
      }
    };
  }

  String generateFileName({
    required DateTime fechaNacimiento,
    required String? consultorio,
    required String? hospital,
    required String? focoAuscultacion,
    String? observaciones,
  }) {
    final edad = DateTime.now().year - fechaNacimiento.year;
    final ahora = DateTime.now(); // Fecha actual

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    return '${[
      twoDigits(ahora.day) + // Día actual
          twoDigits(ahora.month) + // Mes actual
          twoDigits(ahora.year % 100), // Año actual (2 cifras)
      (consultorioMap[consultorio] ?? '00') + (hospitalMap[hospital] ?? '00'),
      focoMap[focoAuscultacion] ?? '00',
      twoDigits(edad),
      (observaciones?.isNotEmpty ?? false) ? '01' : '00'
    ].join('-')}.wav';
  }
}
