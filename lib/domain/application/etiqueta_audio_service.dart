import '../services/aws_s3/aws_s3.dart';

class EtiquetaAudioService {
  final AwsAmplifyS3Service awsS3Service;

  EtiquetaAudioService({required this.awsS3Service});

  // Mapa actualizado con todos los consultorios
  final Map<String, String> consultorioMap = {
    // Departamental
    '101 A': '01',
    '102 B': '02',

    // Infantil
    '103 C': '01',
    '104 D': '02',
  };

  // Mapa actualizado con todos los hospitales
  final Map<String, String> hospitalMap = {
    'Departamental': '01',
    'Infantil': '02',
  };

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
    required String audioUrl,
  }) {
    final edad = DateTime.now().difference(fechaNacimiento).inDays ~/ 365;

    return {
      "metadata": {
        "fecha_nacimiento": fechaNacimiento.toIso8601String(),
        "edad": edad,
        "fecha_grabacion": DateTime.now().toIso8601String(),
        "url_audio": audioUrl
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

  Future<String> generateFileName({
    required DateTime fechaNacimiento,
    required String? consultorio,
    required String? hospital,
    required String? focoAuscultacion,
    String? observaciones,
  }) async {
    final ahora = DateTime.now(); // Fecha actual
    final edad = ahora.difference(fechaNacimiento).inDays ~/ 365;

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final dia = twoDigits(ahora.day);
    final mes = twoDigits(ahora.month);
    final anio = twoDigits(ahora.year % 100); // Últimos dos dígitos del año

    final codConsultorio = consultorioMap[consultorio] ?? '00';
    final codHospital = hospitalMap[hospital] ?? '00';
    final codFoco = focoMap[focoAuscultacion] ?? '00';

    final audioId = await awsS3Service.getNextAudioId(); // 4 dígitos (ej. 0001)
    final edadStr = twoDigits(edad);
    final obsStr = (observaciones?.isNotEmpty ?? false) ? '01' : '00';

    final fileName =
        '$dia$mes$anio-$codConsultorio$codHospital-$codFoco-$audioId-$edadStr$obsStr.wav';

    return fileName;
  }
}
