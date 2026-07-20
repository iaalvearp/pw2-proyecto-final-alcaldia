import 'dart:async';

import 'package:alcaldia_app/models/procurement_detail.dart';
import 'package:alcaldia_app/models/procurement_process.dart';
import 'package:alcaldia_app/repositories/procurement_repository.dart';
import 'package:alcaldia_app/state/search_controller.dart';
import 'package:alcaldia_app/state/search_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expone resultados encontrados', () async {
    final repository = _FakeRepository(<ProcurementProcess>[
      const ProcurementProcess(ocid: 'local-1', description: 'Obra local'),
    ]);
    final controller = ProcurementSearchController(repository);

    await controller.buscar('obra');

    expect(controller.state.status, SearchStatus.results);
    expect(controller.results, hasLength(1));
    expect(controller.errorMessage, isNull);
  });

  test('expone el estado sin resultados', () async {
    final controller = ProcurementSearchController(_FakeRepository(const []));

    await controller.buscar('inexistente');

    expect(controller.state.status, SearchStatus.empty);
    expect(controller.results, isEmpty);
  });

  test('valida palabras menores a tres caracteres sin consultar', () async {
    final repository = _FakeRepository(const []);
    final controller = ProcurementSearchController(repository);

    await controller.buscar('ab');

    expect(controller.state.status, SearchStatus.initial);
    expect(controller.validationMessage, 'Escribe al menos tres caracteres.');
    expect(repository.searchCalls, 0);
  });

  test('un proceso con valores null no provoca fallos', () async {
    final process = ProcurementProcess.fromJson(<String, dynamic>{
      'ocid': null,
      'description': null,
      'title': null,
      'amount': null,
      'suppliers': <String, dynamic>{'estructura': 'inesperada'},
    });
    final controller = ProcurementSearchController(
      _FakeRepository(<ProcurementProcess>[process]),
    );

    await controller.buscar('nulos');

    expect(controller.state.status, SearchStatus.results);
    expect(controller.results.single.displayTitle, 'Proceso de contratación');
  });

  test('evita repetir la misma búsqueda en curso o ya completada', () async {
    final repository = _DelayedRepository();
    final controller = ProcurementSearchController(repository);

    final firstSearch = controller.buscar('  Alborada  ');
    final repeatedInFlight = controller.buscar('alborada');
    expect(repository.searchCalls, 1);

    repository.complete(<ProcurementProcess>[
      const ProcurementProcess(ocid: 'remote-1'),
    ]);
    await Future.wait(<Future<void>>[firstSearch, repeatedInFlight]);
    await controller.buscar('ALBORADA');

    expect(repository.searchCalls, 1);
    expect(controller.state.status, SearchStatus.results);
  });
}

class _FakeRepository implements ProcurementRepository {
  _FakeRepository(this.response);

  final List<ProcurementProcess> response;
  int searchCalls = 0;

  @override
  Future<List<ProcurementProcess>> buscarProcesos(String palabraClave) async {
    searchCalls++;
    return response;
  }

  @override
  Future<ProcurementDetail> obtenerDetalle(String ocid) async {
    return const ProcurementDetail();
  }
}

class _DelayedRepository implements ProcurementRepository {
  final Completer<List<ProcurementProcess>> _completer =
      Completer<List<ProcurementProcess>>();
  int searchCalls = 0;

  void complete(List<ProcurementProcess> results) {
    _completer.complete(results);
  }

  @override
  Future<List<ProcurementProcess>> buscarProcesos(String palabraClave) {
    searchCalls++;
    return _completer.future;
  }

  @override
  Future<ProcurementDetail> obtenerDetalle(String ocid) async {
    return const ProcurementDetail();
  }
}
