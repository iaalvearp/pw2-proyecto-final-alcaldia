import 'package:alcaldia_app/models/procurement_process.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProcurementProcess.fromJson', () {
    test('interpreta una respuesta completa con las claves reales', () {
      final process = ProcurementProcess.fromJson(<String, dynamic>{
        'id': 2989932,
        'ocid': 'ocds-example',
        'year': 2025,
        'month': 7,
        'method': 'open',
        'internal_type': 'Licitación',
        'locality': 'GUAYAQUIL',
        'region': 'GUAYAS',
        'suppliers': <Map<String, dynamic>>[
          <String, dynamic>{'name': 'Proveedor de prueba'},
        ],
        'buyer': 'Municipalidad de Guayaquil',
        'amount': '3926285.300000',
        'date': '2026-05-27T18:28:38-05:00',
        'title': 'LICO-EJEMPLO',
        'description': 'Descripción completa de prueba',
        'budget': '4463086.6',
      });

      expect(process.id, 2989932);
      expect(process.ocid, 'ocds-example');
      expect(process.internalType, 'Licitación');
      expect(process.buyerName, 'Municipalidad de Guayaquil');
      expect(process.amount, 3926285.3);
      expect(process.budget, 4463086.6);
      expect(process.suppliers, isA<List<Object?>>());
      expect(process.displayTitle, 'Descripción completa de prueba');
      expect(process.toJson()['buyer'], 'Municipalidad de Guayaquil');
    });

    test('tolera campos ausentes y produce un título seguro', () {
      final process = ProcurementProcess.fromJson(<String, dynamic>{});

      expect(process.ocid, isNull);
      expect(process.amount, isNull);
      expect(process.budget, isNull);
      expect(process.suppliers, isNull);
      expect(process.displayTitle, 'Proceso de contratación');
      expect(() => process.toJson(), returnsNormally);
    });

    test('prioriza la descripción detallada sobre el resumen', () {
      const process = ProcurementProcess(
        title: 'LICO-MIMG-2025-011',
        description: 'Descripción resumida',
      );

      expect(
        process.resolveDisplayTitle(
          detailedDescription: 'Descripción completa del detalle',
        ),
        'Descripción completa del detalle',
      );
    });

    test('usa tipo y año cuando no hay título ni descripción', () {
      const process = ProcurementProcess(
        internalType: 'Fiscalización',
        year: 2025,
      );

      expect(process.displayTitle, 'Fiscalización · 2025');
    });

    test('usa un código corto antes del fallback final', () {
      const process = ProcurementProcess(
        ocid: 'ocds-5wno2w-LICO-MIMG-2025-011-12345',
      );

      expect(process.displayTitle, 'Proceso LICO-MIMG-2025-011');
      expect(process.displayTitle, isNot('Proceso sin descripción'));
    });

    test('acepta enteros, decimales y texto numérico en montos', () {
      final fromNumbers = ProcurementProcess.fromJson(<String, dynamic>{
        'amount': 1200,
        'budget': 1500.75,
      });
      final fromText = ProcurementProcess.fromJson(<String, dynamic>{
        'amount': '1,200.50',
        'budget': '1500.25',
      });
      final invalid = ProcurementProcess.fromJson(<String, dynamic>{
        'amount': <String>['inesperado'],
        'budget': 'no disponible',
      });

      expect(fromNumbers.amount, 1200.0);
      expect(fromNumbers.budget, 1500.75);
      expect(fromText.amount, 1200.5);
      expect(fromText.budget, 1500.25);
      expect(invalid.amount, isNull);
      expect(invalid.budget, isNull);
    });

    test('suppliers acepta lista, texto y mapa sin fallar', () {
      for (final suppliers in <Object?>[
        <String>['uno'],
        'proveedor',
        <String, dynamic>{'name': 'otro'},
        null,
      ]) {
        expect(
          () => ProcurementProcess.fromJson(<String, dynamic>{
            'suppliers': suppliers,
          }),
          returnsNormally,
        );
      }
    });
  });
}
