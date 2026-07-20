import 'procurement_process.dart';

class ProcurementSearchResponse {
  const ProcurementSearchResponse({
    required this.total,
    required this.page,
    required this.pages,
    required this.results,
  });

  final int total;
  final int page;
  final int pages;
  final List<ProcurementProcess> results;

  factory ProcurementSearchResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    if (rawData is! List) {
      throw const FormatException('data must be a list');
    }

    final results = rawData
        .whereType<Map>()
        .map(
          (item) => ProcurementProcess.fromJson(
            item.map<String, dynamic>(
              (key, value) => MapEntry(key.toString(), value),
            ),
          ),
        )
        .toList(growable: false);

    return ProcurementSearchResponse(
      total: _parseInt(json['total']) ?? results.length,
      page: _parseInt(json['page']) ?? 1,
      pages: _parseInt(json['pages']) ?? (results.isEmpty ? 0 : 1),
      results: results,
    );
  }

  static int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '');
  }
}
