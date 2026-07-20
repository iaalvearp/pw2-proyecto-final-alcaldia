import '../config/app_config.dart';
import '../core/errors/app_exception.dart';
import '../models/procurement_detail.dart';
import '../models/procurement_process.dart';
import 'procurement_repository.dart';

class LocalProcurementRepository implements ProcurementRepository {
  LocalProcurementRepository({
    this.simulatedDelay = const Duration(milliseconds: 450),
  });

  final Duration simulatedDelay;

  static final List<ProcurementProcess>
  _developmentFixtures = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': -1,
      'ocid': 'local-dev-alborada-001',
      'year': 2025,
      'month': 7,
      'method': 'open',
      'internal_type': 'Obra local de desarrollo',
      'locality': 'Guayaquil',
      'region': 'Guayas',
      'suppliers': <Map<String, dynamic>>[],
      'buyer': AppConfig.municipalityBuyerName,
      'amount': '1250000.50',
      'date': '2025-07-15T10:00:00-05:00',
      'title': 'Ejemplo local: intervención vial en Alborada',
      'description':
          '[DATO LOCAL DE DESARROLLO] Rehabilitación vial y adecuación de aceras en un sector de la Alborada.',
      'budget': 1400000,
    },
    <String, dynamic>{
      'id': -2,
      'ocid': 'local-dev-aeropuerto-002',
      'year': 2024,
      'month': 10,
      'method': 'open',
      'internal_type': 'Consultoría local de desarrollo',
      'locality': 'Guayaquil',
      'region': 'Guayas',
      'suppliers': 'Proveedor local ficticio',
      'buyer': AppConfig.municipalityBuyerName,
      'amount': 320000,
      'date': '2024-10-08T09:30:00-05:00',
      'title': 'Ejemplo local: estudios del entorno aeroportuario',
      'description':
          '[DATO LOCAL DE DESARROLLO] Estudios de movilidad en vías cercanas al aeropuerto.',
      'budget': '350000.00',
    },
    <String, dynamic>{
      'id': -3,
      'ocid': 'local-dev-pavimentacion-003',
      'year': 2026,
      'month': 2,
      'method': 'open',
      'internal_type': 'Licitación local de desarrollo',
      'locality': 'Guayaquil',
      'region': 'Guayas',
      'suppliers': <String>['Consorcio ficticio de desarrollo'],
      'buyer': AppConfig.municipalityBuyerName,
      'amount': 2780000.75,
      'date': '2026-02-12T14:00:00-05:00',
      'title': 'Ejemplo local: pavimentación urbana',
      'description':
          '[DATO LOCAL DE DESARROLLO] Pavimentación, bordillos y drenaje en varias calles urbanas.',
      'budget': 3000000,
    },
    <String, dynamic>{
      'id': -4,
      'ocid': 'local-dev-null-004',
      'year': null,
      'month': null,
      'method': null,
      'internal_type': null,
      'locality': 'Guayaquil',
      'region': null,
      'suppliers': <String, dynamic>{'formato': 'inesperado'},
      'buyer': null,
      'amount': null,
      'date': null,
      'title': null,
      'description': null,
      'budget': 'valor no numérico',
    },
  ].map(ProcurementProcess.fromJson).toList(growable: false);

  @override
  Future<List<ProcurementProcess>> buscarProcesos(String palabraClave) async {
    await Future<void>.delayed(simulatedDelay);
    final query = _normalize(palabraClave.trim());

    final results = _developmentFixtures
        .where((process) {
          if (query.isEmpty) return true;
          return <String?>[
            process.description,
            process.title,
            process.locality,
            process.region,
          ].any((value) => _normalize(value ?? '').contains(query));
        })
        .take(AppConfig.initialResultsLimit)
        .toList(growable: false);

    return results;
  }

  @override
  Future<ProcurementDetail> obtenerDetalle(String ocid) async {
    await Future<void>.delayed(simulatedDelay);
    ProcurementProcess? process;
    for (final candidate in _developmentFixtures) {
      if (candidate.ocid == ocid) {
        process = candidate;
        break;
      }
    }
    if (process == null) throw const ProcessNotFoundException();

    return ProcurementDetail.fromJson(<String, dynamic>{
      'version': 'local-development-fixture',
      'releases': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': process.ocid,
          'ocid': process.ocid,
          'tag': <String>['planning', 'tender'],
          'date': process.date?.toIso8601String(),
          'buyer': <String, dynamic>{
            'id': AppConfig.municipalityBuyerId,
            'name': process.buyerName,
          },
          'planning': <String, dynamic>{
            'budget': <String, dynamic>{
              'amount': <String, dynamic>{
                'amount': process.budget,
                'currency': 'USD',
              },
            },
          },
          'tender': <String, dynamic>{
            'id': process.title,
            'description': process.description,
            'procurementMethod': process.method,
            'procurementMethodDetails': process.internalType,
            'value': <String, dynamic>{
              'amount': process.amount,
              'currency': 'USD',
            },
          },
        },
      ],
    });
  }

  static String _normalize(String value) {
    const replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
    };
    var normalized = value.toLowerCase();
    replacements.forEach((source, target) {
      normalized = normalized.replaceAll(source, target);
    });
    return normalized;
  }
}
