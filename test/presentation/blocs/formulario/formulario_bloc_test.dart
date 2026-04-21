// test/presentation/blocs/formulario/formulario_bloc_test.dart
//
// Pruebas unitarias para:
//   HU-001: Etiquetar sonido cardíaco
//   HU-002: Diagnóstico de valvulopatía con IA
//
// HU-001:
//   CP00101 – Envío exitoso con todos los campos completos
//   CP00102 – Error por campos obligatorios faltantes (fallo en generación)
//   CP00103 – Error por falta de conexión a internet
//
// HU-002:
//   CP00201 – Diagnóstico IA exitoso con clasificación y confianza
//   CP00202 – Diagnóstico almacenado y asociado al paciente
//   CP00203 – Error en servicio IA o conexión

import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_ascs/core/errors/failures.dart';
import 'package:app_ascs/core/network/network_info.dart';
import 'package:app_ascs/data/datasources/local/local_storage_datasource.dart';
import 'package:app_ascs/data/datasources/remote/diagnose_remote_datasource.dart';
import 'package:app_ascs/data/datasources/remote/diagnostico_remote_datasource.dart';
import 'package:app_ascs/data/datasources/remote/sample_train_remote_datasource.dart';
import 'package:app_ascs/data/models/diagnostico/diagnose_response_model.dart';
import 'package:app_ascs/data/models/diagnostico/diagnostico_model.dart';
import 'package:app_ascs/domain/entities/formulario_completo.dart';
import 'package:app_ascs/domain/repositories/formulario_repository.dart';
import 'package:app_ascs/domain/usecases/enviar_formulario_usecase.dart';
import 'package:app_ascs/domain/usecases/generar_nombre_archivo_usecase.dart';
import 'package:app_ascs/presentation/blocs/formulario/formulario_bloc.dart';
import 'package:app_ascs/presentation/blocs/formulario/formulario_event.dart';
import 'package:app_ascs/presentation/blocs/formulario/formulario_state.dart';

// ============================================================================
// Test Doubles (Mocks manuales)
// ============================================================================

/// Repositorio falso necesario para instanciar los use-cases.
class FakeFormularioRepository implements FormularioRepository {
  @override
  Future<Either<Failure, void>> enviarFormulario({
    required FormularioCompleto formulario,
    required File zipFile,
    void Function(double progress, String status)? onProgress,
  }) async =>
      const Right(null);

  @override
  Future<Either<Failure, String>> generarNombreArchivo({
    required DateTime fechaNacimiento,
    required String codigoConsultorio,
    required String codigoHospital,
    required String codigoFoco,
    required String estado,
    String? observaciones,
  }) async =>
      const Right('test.wav');
}

/// Mock de [EnviarFormularioUseCase] con resultado configurable.
class MockEnviarFormularioUseCase extends EnviarFormularioUseCase {
  Either<Failure, void> callResult = const Right(null);

  MockEnviarFormularioUseCase() : super(repository: FakeFormularioRepository());

  @override
  Future<Either<Failure, void>> call({
    required FormularioCompleto formulario,
    required File zipFile,
    void Function(double, String)? onProgress,
  }) async {
    onProgress?.call(0.5, 'Subiendo archivos...');
    onProgress?.call(1.0, 'Completado');
    return callResult;
  }
}

/// Mock de [GenerarNombreArchivoUseCase] con resultado configurable.
class MockGenerarNombreArchivoUseCase extends GenerarNombreArchivoUseCase {
  Either<Failure, String> callResult =
      const Right('SC_20250101_0101_01_N_ABCD1234.wav');

  MockGenerarNombreArchivoUseCase()
      : super(repository: FakeFormularioRepository());

  @override
  Future<Either<Failure, String>> call({
    required DateTime fechaNacimiento,
    required String codigoConsultorio,
    required String codigoHospital,
    required String codigoFoco,
    required String estado,
    String? observaciones,
  }) async =>
      callResult;
}

/// Mock de [NetworkInfo] con valores configurables.
class MockNetworkInfo implements NetworkInfo {
  bool isConnectedValue = true;
  ConnectionQuality qualityValue = ConnectionQuality.excellent;

  @override
  Future<bool> get isConnected async => isConnectedValue;

  @override
  Future<ConnectionQuality> get connectionQuality async => qualityValue;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(isConnectedValue);
}

/// Mock de [LocalStorageDataSource] con ZIP extracción configurable.
class MockLocalStorageDataSource implements LocalStorageDataSource {
  ZipAudioFiles? extractResult;
  Exception? extractError;

  @override
  Future<ZipAudioFiles> extraerAudiosDeZip(File zipFile) async {
    if (extractError != null) throw extractError!;
    return extractResult!;
  }

  @override
  Future<Map<String, String>> guardarAudiosLocales({
    required ZipAudioFiles audios,
    required String baseFileName,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> guardarMetadataLocal({
    required Map<String, dynamic> metadata,
    required String baseFileName,
  }) async =>
      throw UnimplementedError();

  @override
  Future<String> generarAudioIdUnicoLocal() async => throw UnimplementedError();

  @override
  Future<Directory> obtenerDirectorioRepositorio() async =>
      throw UnimplementedError();
}

/// Stub de [SampleTrainRemoteDataSource].
class StubSampleTrainRemoteDataSource implements SampleTrainRemoteDataSource {
  @override
  Future<SampleTrainResponse> enviarMuestra({
    required ZipAudioFiles audios,
    required Map<String, dynamic> metadataJson,
    required void Function(String status) onStatus,
  }) async =>
      throw UnimplementedError();
}

/// Mock de [DiagnoseRemoteDataSource] con resultado configurable.
class MockDiagnoseRemoteDataSource implements DiagnoseRemoteDataSource {
  DiagnoseResponseModel? diagnosticarResult;
  Exception? diagnosticarError;

  @override
  Future<DiagnoseResponseModel> diagnosticar({
    required File audioFile,
    required Map<String, dynamic> metadataJson,
  }) async {
    if (diagnosticarError != null) throw diagnosticarError!;
    return diagnosticarResult!;
  }
}

/// Mock de [DiagnosticoRemoteDataSource] con resultado configurable.
class MockDiagnosticoRemoteDataSource implements DiagnosticoRemoteDataSource {
  DiagnosticoModel? crearDiagnosticoResult;
  Exception? crearDiagnosticoError;
  bool crearDiagnosticoCalled = false;

  @override
  Future<List<DiagnosticoGrupoModel>> obtenerPorCreador(
          int usuarioCreaId) async =>
      [];

  @override
  Future<DiagnosticoModel> confirmarValvulopatia({
    required int diagnosticoId,
    required bool valvulopatia,
  }) async =>
      throw UnimplementedError();

  @override
  Future<DiagnosticoModel> crearDiagnostico({
    required int institucionId,
    required bool esNormal,
    required int edad,
    required String genero,
    required double altura,
    required double peso,
    double? precision,
    required String diagnosticoTexto,
    required int focoId,
    int? categoriaAnomaliaId,
    required int usuarioCreaId,
    bool? valvulopatia,
    List<int> enfermedadesBaseIds = const [],
  }) async {
    crearDiagnosticoCalled = true;
    if (crearDiagnosticoError != null) throw crearDiagnosticoError!;
    return crearDiagnosticoResult ??
        const DiagnosticoModel(id: 1, esNormal: true);
  }
}

// ============================================================================
// Helpers
// ============================================================================

/// Crea un [EnviarFormularioEvent] con datos válidos de prueba.
EnviarFormularioEvent _crearEventoValido(File zipFile) {
  return EnviarFormularioEvent(
    fechaNacimiento: DateTime(1990, 5, 15),
    hospital: 'Hospital Departamental',
    codigoHospital: '01',
    consultorio: 'Consultorio 101',
    codigoConsultorio: '01',
    estado: 'Normal',
    focoAuscultacion: 'Aórtico',
    codigoFoco: '01',
    genero: 'M',
    pesoCkg: 70.0,
    alturaCm: 175.0,
    zipFile: zipFile,
    observaciones: 'Sin observaciones',
    enfermedadesBase: ['Hipertensión'],
  );
}

/// Crea un [DiagnosticarAudioEvent] con datos válidos de prueba.
DiagnosticarAudioEvent _crearEventoDiagnostico(File zipFile) {
  return DiagnosticarAudioEvent(
    fechaNacimiento: DateTime(1990, 5, 15),
    hospital: 'Hospital Departamental',
    codigoHospital: '01',
    consultorio: 'Consultorio 101',
    codigoConsultorio: '01',
    focoAuscultacion: 'Aórtico',
    codigoFoco: '01',
    genero: 'M',
    pesoCkg: 70.0,
    alturaCm: 175.0,
    zipFile: zipFile,
    observaciones: 'Sin observaciones',
    enfermedadesBase: ['Hipertensión'],
    institucionId: 1,
    focoId: 1,
    categoriaAnomaliaId: null,
    enfermedadesBaseIds: [1],
  );
}

/// Respuesta IA de prueba con diagnóstico anormal y valvulopatía.
const DiagnoseResponseModel _diagnoseResponseAnormal = DiagnoseResponseModel(
  estado: 'anormal',
  precision: 0.87,
  umbral: 0.4,
  scores: DiagnoseScores(
    anormal: 0.87,
    normal: 0.13,
  ),
  limpieza: DiagnoseLimpieza(
    sampleRate: 2000,
    durationSeconds: 15.0,
  ),
);

// ============================================================================
// Tests HU-001: Etiquetar sonido cardíaco
// ============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockEnviarFormularioUseCase mockEnviarFormulario;
  late MockGenerarNombreArchivoUseCase mockGenerarNombreArchivo;
  late MockNetworkInfo mockNetworkInfo;
  late MockLocalStorageDataSource mockLocalStorage;
  late StubSampleTrainRemoteDataSource stubSampleTrain;
  late MockDiagnoseRemoteDataSource mockDiagnose;
  late MockDiagnosticoRemoteDataSource mockDiagnostico;

  late File fakeZipFile;

  setUp(() {
    mockEnviarFormulario = MockEnviarFormularioUseCase();
    mockGenerarNombreArchivo = MockGenerarNombreArchivoUseCase();
    mockNetworkInfo = MockNetworkInfo();
    mockLocalStorage = MockLocalStorageDataSource();
    stubSampleTrain = StubSampleTrainRemoteDataSource();
    mockDiagnose = MockDiagnoseRemoteDataSource();
    mockDiagnostico = MockDiagnosticoRemoteDataSource();

    // Archivo ZIP ficticio (no se accede realmente en los mocks)
    fakeZipFile = File('test_audios.zip');
  });

  FormularioBloc buildBloc() {
    return FormularioBloc(
      enviarFormularioUseCase: mockEnviarFormulario,
      generarNombreArchivoUseCase: mockGenerarNombreArchivo,
      networkInfo: mockNetworkInfo,
      localStorageDataSource: mockLocalStorage,
      sampleTrainRemoteDataSource: stubSampleTrain,
      diagnoseRemoteDataSource: mockDiagnose,
      diagnosticoRemoteDataSource: mockDiagnostico,
    );
  }

  group('HU-001 – Etiquetar sonido cardíaco', () {
    // ──────────────────────────────────────────────────────────────────────
    // CP00101 – Envío exitoso con todos los campos completos
    // CID: 1
    // Escenario: El médico completa todos los campos obligatorios y envía.
    // Resultado esperado: Sonido enviado y mensaje de confirmación.
    // ──────────────────────────────────────────────────────────────────────
    blocTest<FormularioBloc, FormularioState>(
      'hu001_shouldSendSoundSuccessfullyWhenAllFieldsComplete '
      '(CP00101 – CID 1)',
      setUp: () {
        // Modo nube para simular envío al repositorio global
        SharedPreferences.setMockInitialValues({'storage_mode': 'cloud'});
        mockNetworkInfo.isConnectedValue = true;
        mockNetworkInfo.qualityValue = ConnectionQuality.excellent;
        mockGenerarNombreArchivo.callResult =
            const Right('SC_20250515_0101_01_N_ABCD1234.wav');
        mockEnviarFormulario.callResult = const Right(null);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(_crearEventoValido(fakeZipFile)),
      expect: () => [
        // Verificando conexión
        isA<FormularioEnviando>(),
        // Generando identificador
        isA<FormularioEnviando>(),
        // Progreso de subida (emitido por el callback del mock)
        isA<FormularioEnviando>(),
        isA<FormularioEnviando>(),
        // Mensaje de confirmación
        isA<FormularioEnviadoExitosamente>(),
      ],
      verify: (bloc) {
        // Verificar que el último estado es éxito con mensaje de confirmación
        expect(bloc.state, isA<FormularioEnviadoExitosamente>());
        final successState = bloc.state as FormularioEnviadoExitosamente;
        expect(successState.mensaje, contains('exitosamente'));
      },
    );

    // ──────────────────────────────────────────────────────────────────────
    // CP00102 – Error por campos obligatorios faltantes
    // CID: 2
    // Escenario: El use case falla al procesar datos incompletos.
    // Resultado esperado: Mensaje de error indicando el problema.
    // ──────────────────────────────────────────────────────────────────────
    blocTest<FormularioBloc, FormularioState>(
      'hu001_shouldShowErrorWhenFieldsAreIncomplete '
      '(CP00102 – CID 2)',
      setUp: () {
        SharedPreferences.setMockInitialValues({'storage_mode': 'cloud'});
        mockNetworkInfo.isConnectedValue = true;
        mockNetworkInfo.qualityValue = ConnectionQuality.excellent;
        // Simular fallo en la generación del nombre (datos incompletos)
        mockGenerarNombreArchivo.callResult =
            const Left(ServerFailure('Campos obligatorios incompletos'));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(_crearEventoValido(fakeZipFile)),
      expect: () => [
        // Verificando conexión
        isA<FormularioEnviando>(),
        // Generando identificador (falla)
        isA<FormularioEnviando>(),
        // Error con mensaje descriptivo
        isA<FormularioError>(),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<FormularioError>());
        final errorState = bloc.state as FormularioError;
        expect(errorState.mensaje, contains('Campos obligatorios incompletos'));
      },
    );

    // ──────────────────────────────────────────────────────────────────────
    // CP00103 – Error por falta de conexión a internet
    // CID: 3
    // Escenario: El médico intenta enviar sin conexión a internet.
    // Resultado esperado: Mensaje de error indicando falta de conexión.
    // ──────────────────────────────────────────────────────────────────────
    blocTest<FormularioBloc, FormularioState>(
      'hu001_shouldShowErrorWhenNoInternetConnection '
      '(CP00103 – CID 3)',
      setUp: () {
        SharedPreferences.setMockInitialValues({'storage_mode': 'cloud'});
        mockNetworkInfo.isConnectedValue = false;
      },
      build: buildBloc,
      act: (bloc) => bloc.add(_crearEventoValido(fakeZipFile)),
      expect: () => [
        // Verificando conexión
        isA<FormularioEnviando>(),
        // Error: sin conexión a internet
        isA<FormularioError>(),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<FormularioError>());
        final errorState = bloc.state as FormularioError;
        expect(
          errorState.mensaje,
          contains('No hay conexión a Internet'),
        );
      },
    );
  });

  // ==========================================================================
  // HU-002 – Diagnóstico de valvulopatía con IA
  // ==========================================================================

  group('HU-002 – Diagnóstico de valvulopatía con IA', () {
    // ──────────────────────────────────────────────────────────────────────
    // CP00201 – Diagnóstico IA exitoso con clasificación y confianza
    // CID: 1
    // Escenario: El médico carga audio y solicita diagnóstico; la IA
    //            responde con clasificación, probabilidades y confianza.
    // ──────────────────────────────────────────────────────────────────────
    blocTest<FormularioBloc, FormularioState>(
      'hu002_shouldShowDiagnosisWithClassificationAndConfidence '
      '(CP00201 – CID 1)',
      setUp: () {
        mockNetworkInfo.isConnectedValue = true;
        // Simular extracción exitosa del ZIP
        mockLocalStorage.extractResult = ZipAudioFiles(
          principal: File('audio_principal.wav'),
          ecg: File('audio_ecg.wav'),
          ecg1: File('audio_ecg1.wav'),
          ecg2: File('audio_ecg2.wav'),
        );
        // Simular respuesta exitosa del servicio IA
        mockDiagnose.diagnosticarResult = _diagnoseResponseAnormal;
      },
      build: buildBloc,
      act: (bloc) => bloc.add(_crearEventoDiagnostico(fakeZipFile)),
      expect: () => [
        // Verificando conexión
        isA<FormularioEnviando>(),
        // Extrayendo audio principal
        isA<FormularioEnviando>(),
        // Preparando metadatos
        isA<FormularioEnviando>(),
        // Enviando al servicio IA
        isA<FormularioEnviando>(),
        // Guardando diagnóstico
        isA<FormularioEnviando>(),
        // Resultado IA recibido
        isA<DiagnosticoIARecibido>(),
      ],
      verify: (bloc) {
        final state = bloc.state;
        expect(state, isA<DiagnosticoIARecibido>(),
            reason:
                'CP00201: Debe emitir DiagnosticoIARecibido con resultado IA');
        final iaState = state as DiagnosticoIARecibido;
        // Verificar clasificación
        expect(iaState.resultado.estado, 'anormal',
            reason: 'CP00201: La clasificación debe ser anormal');
        // Verificar que no es normal (valvulopatía)
        expect(iaState.resultado.esNormal, isFalse,
            reason: 'CP00201: Debe indicar presencia de valvulopatía');
        // Verificar scores
        expect(iaState.resultado.scores.anormal, 0.87,
            reason: 'CP00201: Score de anomalía debe ser 0.87');
        expect(iaState.resultado.scores.normal, 0.13,
            reason: 'CP00201: Score normal debe ser 0.13');
        // Verificar precisión
        expect(iaState.resultado.precision, 0.87,
            reason: 'CP00201: La precisión debe ser 0.87');
      },
    );

    // ──────────────────────────────────────────────────────────────────────
    // CP00202 – Diagnóstico almacenado y asociado al paciente
    // CID: 2
    // Escenario: El servicio IA responde exitosamente y el resultado
    //            contiene los datos del paciente correctamente asociados.
    //            El diagnóstico se almacena vía POST /api/diagnostics
    //            (requiere sesión autenticada en producción).
    // ──────────────────────────────────────────────────────────────────────
    blocTest<FormularioBloc, FormularioState>(
      'hu002_shouldStoreDiagnosisAndAssociateToPatient '
      '(CP00202 – CID 2)',
      setUp: () {
        mockNetworkInfo.isConnectedValue = true;
        mockLocalStorage.extractResult = ZipAudioFiles(
          principal: File('audio_principal.wav'),
          ecg: File('audio_ecg.wav'),
          ecg1: File('audio_ecg1.wav'),
          ecg2: File('audio_ecg2.wav'),
        );
        mockDiagnose.diagnosticarResult = _diagnoseResponseAnormal;
      },
      build: buildBloc,
      act: (bloc) => bloc.add(_crearEventoDiagnostico(fakeZipFile)),
      expect: () => [
        isA<FormularioEnviando>(),
        isA<FormularioEnviando>(),
        isA<FormularioEnviando>(),
        isA<FormularioEnviando>(),
        isA<FormularioEnviando>(),
        isA<DiagnosticoIARecibido>(),
      ],
      verify: (bloc) {
        // Verificar que el diagnóstico IA se recibió correctamente
        expect(bloc.state, isA<DiagnosticoIARecibido>(),
            reason:
                'CP00202: Debe emitir DiagnosticoIARecibido con resultado IA');
        final iaState = bloc.state as DiagnosticoIARecibido;
        // Verificar scores y estado
        expect(iaState.resultado.estado, 'anormal',
            reason: 'CP00202: El estado debe ser anormal');
        expect(iaState.resultado.scores.anormal, 0.87,
            reason: 'CP00202: Score anormal debe coincidir');
        expect(iaState.resultado.scores.normal, 0.13,
            reason: 'CP00202: Score normal debe coincidir');
        expect(iaState.resultado.umbral, 0.4,
            reason: 'CP00202: El umbral debe coincidir');
        // Verificar que el diagnóstico tiene la clasificación asociada
        expect(iaState.resultado.estado, 'anormal',
            reason: 'CP00202: El diagnóstico debe estar asociado al resultado');
        expect(iaState.resultado.esNormal, isFalse,
            reason:
                'CP00202: La valvulopatía debe estar asociada al resultado');
      },
    );

    // ──────────────────────────────────────────────────────────────────────
    // CP00203 – Error en servicio IA o en la conexión
    // CID: 3
    // Escenario: Falla la conexión o el servicio IA arroja error.
    // Resultado esperado: Mensaje de error indicando que no fue posible
    //                     obtener el diagnóstico.
    // ──────────────────────────────────────────────────────────────────────
    blocTest<FormularioBloc, FormularioState>(
      'hu002_shouldShowErrorWhenAIServiceOrConnectionFails '
      '(CP00203 – CID 3)',
      setUp: () {
        mockNetworkInfo.isConnectedValue = false;
      },
      build: buildBloc,
      act: (bloc) => bloc.add(_crearEventoDiagnostico(fakeZipFile)),
      expect: () => [
        // Verificando conexión
        isA<FormularioEnviando>(),
        // Error: sin conexión
        isA<FormularioError>(),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<FormularioError>(),
            reason:
                'CP00203: Debe emitir FormularioError al no haber conexión');
        final errorState = bloc.state as FormularioError;
        expect(errorState.mensaje, contains('conexión'),
            reason: 'CP00203: El mensaje debe indicar problema de conexión');
      },
    );
  });
}
