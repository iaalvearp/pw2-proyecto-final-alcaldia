import 'package:alcaldia_app/models/procurement_detail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recupera valores calculados desde un release parcial', () {
    final detail = ProcurementDetail.fromJson(<String, dynamic>{
      'uri': 'local-development',
      'releases': <Map<String, dynamic>>[
        <String, dynamic>{
          'ocid': 'local-ocid',
          'buyer': <String, dynamic>{'id': 'buyer-1', 'name': 'Comprador'},
          'planning': <String, dynamic>{
            'budget': <String, dynamic>{
              'amount': <String, dynamic>{
                'amount': '1000.50',
                'currency': 'USD',
              },
            },
          },
          'tender': <String, dynamic>{
            'description': 'Obra de prueba',
            'status': 'active',
            'value': <String, dynamic>{'amount': 900, 'currency': 'USD'},
          },
          'awards': <Map<String, dynamic>>[
            <String, dynamic>{
              'value': <String, dynamic>{'amount': '850'},
              'suppliers': <Map<String, dynamic>>[
                <String, dynamic>{'name': 'Proveedor'},
              ],
            },
          ],
          'contracts': <Map<String, dynamic>>[
            <String, dynamic>{
              'status': 'active',
              'dateSigned': '2025-01-02T00:00:00-05:00',
              'value': <String, dynamic>{'amount': 850},
            },
          ],
        },
      ],
    });

    expect(detail.ocid, 'local-ocid');
    expect(detail.buyerId, 'buyer-1');
    expect(detail.description, 'Obra de prueba');
    expect(detail.budget, 1000.5);
    expect(detail.tenderValue, 900);
    expect(detail.awardedAmount, 850);
    expect(detail.contractAmount, 850);
    expect(detail.awardedSupplier, 'Proveedor');
    expect(detail.signedDate, isNotNull);
  });

  test('tolera releases vacíos y estructuras incompletas', () {
    final detail = ProcurementDetail.fromJson(<String, dynamic>{
      'releases': <Object?>[null, 'inesperado', <String, dynamic>{}],
    });

    expect(detail.releases, hasLength(1));
    expect(detail.ocid, isNull);
    expect(detail.documents, isEmpty);
    expect(() => detail.awardedSupplier, returnsNormally);
  });
}
