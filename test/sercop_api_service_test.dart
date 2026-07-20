import 'dart:convert';

import 'package:alcaldia_app/core/errors/app_exception.dart';
import 'package:alcaldia_app/services/sercop_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('SercopApiService', () {
    test('construye la URI y parsea la raíz y buyer correctamente', () async {
      final client = MockClient((request) async {
        expect(request.url.path, endsWith('/api/search_ocds'));
        expect(request.url.queryParameters, <String, String>{
          'year': '2025',
          'search': 'Alborada central',
          'buyer': 'Municipalidad de Guayaquil',
          'page': '1',
        });
        return _jsonResponse(<String, dynamic>{
          'total': '1',
          'page': 1.0,
          'pages': '1',
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'ocid': 'ocds-test',
              'buyer': 'Municipalidad de Guayaquil',
              'description': 'Vía en Alborada',
            },
          ],
        });
      });
      final service = SercopApiService(client);

      final response = await service.buscarProcesos(
        year: 2025,
        keyword: 'Alborada central',
        buyer: 'Municipalidad de Guayaquil',
      );

      expect(response.total, 1);
      expect(response.page, 1);
      expect(response.pages, 1);
      expect(response.results.single.buyerName, 'Municipalidad de Guayaquil');
    });

    test(
      'parsea resultados remotos sin título ni descripción sin afectar la búsqueda',
      () async {
        final emptyService = SercopApiService(
          MockClient(
            (_) async => _jsonResponse(<String, dynamic>{
              'total': null,
              'page': null,
              'pages': null,
              'data': <Object?>[],
            }),
          ),
        );
        final partialService = SercopApiService(
          MockClient(
            (_) async => _jsonResponse(<String, dynamic>{
              'data': <Map<String, dynamic>>[<String, dynamic>{}],
            }),
          ),
        );

        final empty = await emptyService.buscarProcesos(
          year: 2024,
          keyword: 'obra',
          buyer: 'Municipalidad de Guayaquil',
        );
        final partial = await partialService.buscarProcesos(
          year: 2024,
          keyword: 'obra',
          buyer: 'Municipalidad de Guayaquil',
        );

        expect(empty.results, isEmpty);
        expect(empty.total, 0);
        expect(partial.results, hasLength(1));
        expect(partial.results.single.title, isNull);
        expect(partial.results.single.description, isNull);
        expect(partial.results.single.displayTitle, 'Proceso de contratación');
      },
    );

    test('convierte amount entero, decimal y texto', () async {
      final service = SercopApiService(
        MockClient(
          (_) async => _jsonResponse(<String, dynamic>{
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'amount': 10},
              <String, dynamic>{'amount': 10.5},
              <String, dynamic>{'amount': '10.75'},
            ],
          }),
        ),
      );

      final response = await service.buscarProcesos(
        year: 2026,
        keyword: 'vial',
        buyer: 'Municipalidad de Guayaquil',
      );

      expect(response.results.map((process) => process.amount), <double?>[
        10,
        10.5,
        10.75,
      ]);
    });

    test('traduce timeout', () async {
      final service = SercopApiService(
        MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return _jsonResponse(<String, dynamic>{'data': <Object?>[]});
        }),
        timeout: const Duration(milliseconds: 1),
      );

      expect(
        service.buscarProcesos(
          year: 2024,
          keyword: 'obra',
          buyer: 'Municipalidad de Guayaquil',
        ),
        throwsA(isA<RequestTimeoutException>()),
      );
    });

    test('traduce HTTP distinto de 200', () {
      final service = SercopApiService(
        MockClient((_) async => http.Response('error', 503)),
      );

      expect(
        service.buscarProcesos(
          year: 2024,
          keyword: 'obra',
          buyer: 'Municipalidad de Guayaquil',
        ),
        throwsA(isA<SercopHttpException>()),
      );
    });

    test('rechaza una raíz o data con estructura inválida', () async {
      for (final body in <Object?>[
        <Object?>[],
        <String, dynamic>{'data': 'no es una lista'},
      ]) {
        final service = SercopApiService(
          MockClient((_) async => _jsonResponse(body)),
        );

        await expectLater(
          service.buscarProcesos(
            year: 2024,
            keyword: 'obra',
            buyer: 'Municipalidad de Guayaquil',
          ),
          throwsA(isA<InvalidResponseException>()),
        );
      }
    });

    test('consulta y parsea el release package de detalle', () async {
      final service = SercopApiService(
        MockClient((request) async {
          expect(request.url.path, endsWith('/api/record'));
          expect(request.url.queryParameters, <String, String>{
            'ocid': 'ocds-detail-test',
          });
          return _jsonResponse(<String, dynamic>{
            'uri': 'https://example.test/record',
            'version': '1.1',
            'releases': <Map<String, dynamic>>[
              <String, dynamic>{
                'ocid': 'ocds-detail-test',
                'buyer': <String, dynamic>{
                  'id': 'buyer-id',
                  'name': 'Municipalidad de Guayaquil',
                },
              },
            ],
          });
        }),
      );

      final detail = await service.obtenerDetalle('ocds-detail-test');

      expect(detail.ocid, 'ocds-detail-test');
      expect(detail.buyerId, 'buyer-id');
      expect(detail.releases, hasLength(1));
    });
  });
}

http.Response _jsonResponse(Object? body) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    200,
    headers: const <String, String>{
      'content-type': 'application/json; charset=utf-8',
    },
  );
}
