// test/presentation/blocs/diagnostico/diagnostico_bloc_test.dart
//
// Pruebas unitarias para HU-003: Validación clínica del diagnóstico
// Clase: DiagnosticoBlocTest
//
// CP00301 – El médico puede confirmar o descartar un diagnóstico
// CP00302 – El estado del diagnóstico se actualiza en la base de datos

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_ascs/data/datasources/remote/diagnostico_remote_datasource.dart';
import 'package:app_ascs/data/models/diagnostico/diagnostico_model.dart';
import 'package:app_ascs/presentation/blocs/diagnostico/diagnostico_bloc.dart';
import 'package:app_ascs/presentation/blocs/diagnostico/diagnostico_event.dart';
import 'package:app_ascs/presentation/blocs/diagnostico/diagnostico_state.dart';

// ============================================================================
// Test Doubles
// ============================================================================

/// Mock de [DiagnosticoRemoteDataSource] configurado para pruebas HU-003.
class MockDiagnosticoRemoteDataSource implements DiagnosticoRemoteDataSource {
  // -- obtenerPorCreador --
  List<DiagnosticoGrupoModel> obtenerResult = [];
  Exception? obtenerError;

  // -- confirmarValvulopatia --
  DiagnosticoModel? confirmarResult;
  Exception? confirmarError;
  bool confirmarCalled = false;
  int? lastDiagnosticoId;
  bool? lastValvulopatia;

  @override
  Future<List<DiagnosticoGrupoModel>> obtenerPorCreador(
      int usuarioCreaId) async {
    if (obtenerError != null) throw obtenerError!;
    return obtenerResult;
  }

  @override
  Future<DiagnosticoModel> confirmarValvulopatia({
    required int diagnosticoId,
    required bool valvulopatia,
  }) async {
    confirmarCalled = true;
    lastDiagnosticoId = diagnosticoId;
    lastValvulopatia = valvulopatia;
    if (confirmarError != null) throw confirmarError!;
    return confirmarResult ??
        DiagnosticoModel(
          id: diagnosticoId,
          verificado: true,
          valvulopatia: valvulopatia,
        );
  }

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
  }) async =>
      throw UnimplementedError();
}

// ============================================================================
// Datos de prueba
// ============================================================================

/// Diagnóstico pendiente de verificación (generado por IA, aún no revisado)
const _diagPendiente = DiagnosticoModel(
  id: 10,
  creadoEn: '2025-04-10T08:00:00Z',
  institucion: 'Hospital Departamental',
  esNormal: false,
  verificado: false,
  valvulopatia: true,
  edad: 55,
  genero: 'M',
  focoId: 1,
  focoNombre: 'Aórtico',
);

/// Grupo que contiene el diagnóstico pendiente
final _grupoPendiente = DiagnosticoGrupoModel(
  usuarioCreadorId: 1,
  nombreUsuario: 'Dr. García',
  totalDiagnosticos: 1,
  diagnosticos: [_diagPendiente],
);

// ============================================================================
// Tests HU-003: Validación clínica del diagnóstico
// ============================================================================

void main() {
  late MockDiagnosticoRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockDiagnosticoRemoteDataSource();
  });

  DiagnosticoBloc buildBloc() {
    return DiagnosticoBloc(dataSource: mockDataSource);
  }

  group('HU-003 – Validación clínica del diagnóstico', () {
    // ──────────────────────────────────────────────────────────────────────
    // CP00301 – El médico confirma un diagnóstico generado por la IA
    // CID: 1
    // Escenario: El médico revisa un diagnóstico y lo marca como confirmado.
    // Resultado esperado: Se emite ValvulopatiaConfirmada con valvulopatia=true.
    // ──────────────────────────────────────────────────────────────────────
    blocTest<DiagnosticoBloc, DiagnosticoState>(
      'hu003_shouldAllowDoctorToConfirmDiagnosis '
      '(CP00301 – CID 1)',
      setUp: () {
        // Primero cargar diagnósticos para tener lista en el state
        mockDataSource.obtenerResult = [_grupoPendiente];
        mockDataSource.confirmarResult = _diagPendiente.copyWith(
          verificado: true,
          valvulopatia: true,
        );
      },
      build: buildBloc,
      seed: () => DiagnosticoLoaded(grupos: [_grupoPendiente]),
      act: (bloc) => bloc.add(
        const ConfirmarValvulopatiaEvent(
          diagnosticoId: 10,
          valvulopatia: true,
        ),
      ),
      expect: () => [
        isA<ValvulopatiaConfirmada>(),
      ],
      verify: (bloc) {
        final state = bloc.state;
        expect(state, isA<ValvulopatiaConfirmada>(),
            reason:
                'CP00301: Debe emitir ValvulopatiaConfirmada al confirmar diagnóstico');
        final confirmed = state as ValvulopatiaConfirmada;
        expect(confirmed.diagnosticoId, 10,
            reason: 'CP00301: Debe corresponder al diagnóstico confirmado');
        expect(confirmed.valvulopatia, isTrue,
            reason: 'CP00301: La valvulopatía debe estar confirmada');
        // Verificar que el diagnóstico en la lista local se actualizó
        final diag = confirmed.grupos.first.diagnosticos.first;
        expect(diag.verificado, isTrue,
            reason:
                'CP00301: El diagnóstico debe quedar marcado como verificado');
        expect(diag.valvulopatia, isTrue,
            reason: 'CP00301: La valvulopatía del diagnóstico debe ser true');
      },
    );

    // ──────────────────────────────────────────────────────────────────────
    // CP00302 – El médico descarta la valvulopatía de un diagnóstico
    // CID: 1 (complemento – descartar)
    // Escenario: El médico revisa un diagnóstico y lo marca como descartado.
    // Resultado esperado: Se emite ValvulopatiaConfirmada con valvulopatia=false.
    // ──────────────────────────────────────────────────────────────────────
    blocTest<DiagnosticoBloc, DiagnosticoState>(
      'hu003_shouldAllowDoctorToDiscardDiagnosis '
      '(CP00302 – CID 1 descartar)',
      setUp: () {
        mockDataSource.obtenerResult = [_grupoPendiente];
        mockDataSource.confirmarResult = _diagPendiente.copyWith(
          verificado: true,
          valvulopatia: false,
        );
      },
      build: buildBloc,
      seed: () => DiagnosticoLoaded(grupos: [_grupoPendiente]),
      act: (bloc) => bloc.add(
        const ConfirmarValvulopatiaEvent(
          diagnosticoId: 10,
          valvulopatia: false,
        ),
      ),
      expect: () => [
        isA<ValvulopatiaConfirmada>(),
      ],
      verify: (bloc) {
        final state = bloc.state as ValvulopatiaConfirmada;
        expect(state.valvulopatia, isFalse,
            reason: 'CP00302: La valvulopatía debe estar descartada (false)');
        final diag = state.grupos.first.diagnosticos.first;
        expect(diag.verificado, isTrue,
            reason:
                'CP00302: El diagnóstico debe quedar marcado como verificado');
        expect(diag.valvulopatia, isFalse,
            reason: 'CP00302: La valvulopatía del diagnóstico debe ser false');
      },
    );

    // ──────────────────────────────────────────────────────────────────────
    // CP00303 – El sistema actualiza el estado en la base de datos
    // CID: 2
    // Escenario: Al confirmar, el datasource recibe los parámetros correctos
    //            y la lista local se actualiza.
    // Resultado esperado: Se invoca confirmarValvulopatia con los parámetros
    //                     correctos y el diagnóstico queda verificado=true.
    // ──────────────────────────────────────────────────────────────────────
    blocTest<DiagnosticoBloc, DiagnosticoState>(
      'hu003_shouldUpdateDiagnosisStateInDatabase '
      '(CP00303 – CID 2)',
      setUp: () {
        mockDataSource.confirmarCalled = false;
        mockDataSource.confirmarResult = _diagPendiente.copyWith(
          verificado: true,
          valvulopatia: true,
        );
      },
      build: buildBloc,
      seed: () => DiagnosticoLoaded(grupos: [_grupoPendiente]),
      act: (bloc) => bloc.add(
        const ConfirmarValvulopatiaEvent(
          diagnosticoId: 10,
          valvulopatia: true,
        ),
      ),
      expect: () => [
        isA<ValvulopatiaConfirmada>(),
      ],
      verify: (bloc) {
        // Verificar que se invocó el datasource con los parámetros correctos
        expect(mockDataSource.confirmarCalled, isTrue,
            reason:
                'CP00303: Debe invocar confirmarValvulopatia en el datasource');
        expect(mockDataSource.lastDiagnosticoId, 10,
            reason:
                'CP00303: Debe enviar el diagnosticoId correcto al servidor');
        expect(mockDataSource.lastValvulopatia, isTrue,
            reason: 'CP00303: Debe enviar valvulopatia=true al servidor');
        // Verificar que la lista local se actualizó
        final state = bloc.state as ValvulopatiaConfirmada;
        final diag = state.grupos.first.diagnosticos.first;
        expect(diag.verificado, isTrue,
            reason:
                'CP00303: El campo verificado debe ser true tras la actualización');
      },
    );
  });
}
