import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../core/errors/app_exception.dart';
import '../models/procurement_detail.dart';
import '../models/procurement_process.dart';
import '../services/sercop_api_service.dart';
import 'procurement_repository.dart';

class SercopProcurementRepository implements ProcurementRepository {
  SercopProcurementRepository(
    this._dataSource, {
    void Function(String message)? logger,
  }) : _logger = logger ?? debugPrint;

  final SercopDataSource _dataSource;
  final void Function(String message) _logger;

  @override
  Future<List<ProcurementProcess>> buscarProcesos(String palabraClave) async {
    final combined = <ProcurementProcess>[];
    final failures = <AppException>[];
    var successfulYears = 0;

    for (final year in AppConfig.searchYears) {
      try {
        final response = await _dataSource.buscarProcesos(
          year: year,
          keyword: palabraClave.trim(),
          buyer: AppConfig.municipalityBuyerName,
          page: 1,
        );
        successfulYears++;
        combined.addAll(response.results);
      } on AppException catch (error) {
        failures.add(error);
        _logger('Falló la consulta SERCOP del año $year: ${error.runtimeType}');
      } catch (error) {
        failures.add(const UnknownAppException());
        _logger('Falló la consulta SERCOP del año $year: ${error.runtimeType}');
      }
    }

    if (successfulYears == 0) {
      throw failures.isEmpty ? const UnknownAppException() : failures.first;
    }

    final expectedBuyer = _normalize(AppConfig.municipalityBuyerName);
    final valid =
        combined
            .where(
              (process) => _normalize(process.buyerName ?? '') == expectedBuyer,
            )
            .toList(growable: false)
          ..sort(_compareMostRecentFirst);

    final unique = <String, ProcurementProcess>{};
    for (final process in valid) {
      unique.putIfAbsent(_deduplicationKey(process), () => process);
    }
    return unique.values.toList(growable: false);
  }

  @override
  Future<ProcurementDetail> obtenerDetalle(String ocid) {
    final normalizedOcid = ocid.trim();
    if (normalizedOcid.isEmpty) {
      throw const ProcessNotFoundException();
    }
    return _dataSource.obtenerDetalle(normalizedOcid);
  }

  static String _deduplicationKey(ProcurementProcess process) {
    final ocid = process.ocid?.trim();
    if (ocid != null && ocid.isNotEmpty) return 'ocid:$ocid';
    return 'fallback:${process.id}|${process.year}|${_normalize(process.title ?? '')}';
  }

  static int _compareMostRecentFirst(
    ProcurementProcess first,
    ProcurementProcess second,
  ) {
    final firstDate =
        first.date ?? DateTime(first.year ?? 0, first.month?.clamp(1, 12) ?? 1);
    final secondDate =
        second.date ??
        DateTime(second.year ?? 0, second.month?.clamp(1, 12) ?? 1);
    return secondDate.compareTo(firstDate);
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
    var normalized = value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    replacements.forEach((source, target) {
      normalized = normalized.replaceAll(source, target);
    });
    return normalized;
  }
}
