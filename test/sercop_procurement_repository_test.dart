import 'package:alcaldia_app/core/errors/app_exception.dart';
import 'package:alcaldia_app/models/procurement_detail.dart';
import 'package:alcaldia_app/models/procurement_process.dart';
import 'package:alcaldia_app/models/procurement_search_response.dart';
import 'package:alcaldia_app/repositories/sercop_procurement_repository.dart';
import 'package:alcaldia_app/services/sercop_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SercopProcurementRepository', () {
    test('combina años, filtra comprador y elimina duplicados', () async {
      final dataSource = _FakeDataSource(<int, Object>{
        2024: _response(<ProcurementProcess>[
          _process(
            ocid: 'duplicado',
            year: 2024,
            date: '2024-01-01T00:00:00-05:00',
          ),
          _process(
            ocid: 'otra-entidad',
            year: 2024,
            buyer: 'Empresa Pública Municipal de Guayaquil',
          ),
          _process(ocid: null, id: 7, year: 2025, title: 'Sin OCID'),
        ]),
        2025: _response(<ProcurementProcess>[
          _process(
            ocid: 'duplicado',
            year: 2025,
            date: '2025-06-01T00:00:00-05:00',
          ),
          _process(
            ocid: 'unico',
            year: 2025,
            buyer: '  MUNICIPALIDAD   DE GUAYAQUIL ',
          ),
          _process(ocid: null, id: 7, year: 2025, title: 'Sin OCID'),
        ]),
        2026: _response(const <ProcurementProcess>[]),
      });
      final repository = SercopProcurementRepository(
        dataSource,
        logger: (_) {},
      );

      final results = await repository.buscarProcesos(' Alborada ');

      expect(results, hasLength(3));
      expect(results.where((item) => item.ocid == 'duplicado'), hasLength(1));
      expect(results.firstWhere((item) => item.ocid == 'duplicado').year, 2025);
      expect(results.any((item) => item.ocid == 'otra-entidad'), isFalse);
      expect(results.where((item) => item.ocid == null), hasLength(1));
      expect(dataSource.requestedYears, <int>[2024, 2025, 2026]);
      expect(dataSource.keywords.toSet(), <String>{'Alborada'});
      expect(dataSource.buyers.toSet(), <String>{'Municipalidad de Guayaquil'});
    });

    test('conserva resultados si falla un año', () async {
      final repository = SercopProcurementRepository(
        _FakeDataSource(<int, Object>{
          2024: const NetworkException(),
          2025: _response(<ProcurementProcess>[_process(ocid: 'valido')]),
          2026: _response(const <ProcurementProcess>[]),
        }),
        logger: (_) {},
      );

      final results = await repository.buscarProcesos('Alborada');

      expect(results.map((item) => item.ocid), <String?>['valido']);
    });

    test('propaga error cuando fallan todos los años', () {
      final repository = SercopProcurementRepository(
        _FakeDataSource(<int, Object>{
          2024: const NetworkException(),
          2025: const NetworkException(),
          2026: const NetworkException(),
        }),
        logger: (_) {},
      );

      expect(
        repository.buscarProcesos('Alborada'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}

ProcurementProcess _process({
  String? ocid = 'ocid',
  int? id,
  int? year = 2025,
  String? buyer = 'Municipalidad de Guayaquil',
  String? title,
  String? date,
}) {
  return ProcurementProcess.fromJson(<String, dynamic>{
    'ocid': ocid,
    'id': id,
    'year': year,
    'buyer': buyer,
    'title': title,
    'date': date,
  });
}

ProcurementSearchResponse _response(List<ProcurementProcess> results) {
  return ProcurementSearchResponse(
    total: results.length,
    page: 1,
    pages: results.isEmpty ? 0 : 1,
    results: results,
  );
}

class _FakeDataSource implements SercopDataSource {
  _FakeDataSource(this.responses);

  final Map<int, Object> responses;
  final List<int> requestedYears = <int>[];
  final List<String> keywords = <String>[];
  final List<String> buyers = <String>[];

  @override
  Future<ProcurementSearchResponse> buscarProcesos({
    required int year,
    required String keyword,
    required String buyer,
    int page = 1,
  }) async {
    requestedYears.add(year);
    keywords.add(keyword);
    buyers.add(buyer);
    final response = responses[year];
    if (response is Exception) throw response;
    return response! as ProcurementSearchResponse;
  }

  @override
  Future<ProcurementDetail> obtenerDetalle(String ocid) async {
    return const ProcurementDetail();
  }
}
