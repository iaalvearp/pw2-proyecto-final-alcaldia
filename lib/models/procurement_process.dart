class ProcurementProcess {
  const ProcurementProcess({
    this.id,
    this.ocid,
    this.year,
    this.month,
    this.method,
    this.internalType,
    this.locality,
    this.region,
    this.suppliers,
    this.buyerName,
    this.amount,
    this.date,
    this.title,
    this.description,
    this.budget,
  });

  final int? id;
  final String? ocid;
  final int? year;
  final int? month;
  final String? method;
  final String? internalType;
  final String? locality;
  final String? region;
  final Object? suppliers;
  final String? buyerName;
  final double? amount;
  final DateTime? date;
  final String? title;
  final String? description;
  final double? budget;

  String get displayTitle => resolveDisplayTitle();

  String resolveDisplayTitle({String? detailedDescription}) {
    final detailed = _nonEmpty(detailedDescription);
    if (detailed != null) return detailed;

    final summaryDescription = _nonEmpty(description);
    if (summaryDescription != null) return summaryDescription;

    final summaryTitle = _nonEmpty(title);
    if (summaryTitle != null) return summaryTitle;

    final type = _nonEmpty(internalType);
    if (type != null && year != null) return '$type · $year';
    if (type != null) return type;

    final processCode = _shortProcessCode(ocid);
    if (processCode != null) return 'Proceso $processCode';

    return 'Proceso de contratación';
  }

  factory ProcurementProcess.fromJson(Map<String, dynamic> json) {
    return ProcurementProcess(
      id: _parseInt(json['id']),
      ocid: _parseString(json['ocid']),
      year: _parseInt(json['year']),
      month: _parseInt(json['month']),
      method: _parseString(json['method']),
      internalType: _parseString(json['internal_type']),
      locality: _parseString(json['locality']),
      region: _parseString(json['region']),
      suppliers: _copyJsonValue(json['suppliers']),
      buyerName: _parseString(json['buyer']),
      amount: _parseDouble(json['amount']),
      date: _parseDate(json['date']),
      title: _parseString(json['title']),
      description: _parseString(json['description']),
      budget: _parseDouble(json['budget']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'ocid': ocid,
      'year': year,
      'month': month,
      'method': method,
      'internal_type': internalType,
      'locality': locality,
      'region': region,
      'suppliers': _copyJsonValue(suppliers),
      'buyer': buyerName,
      'amount': amount,
      'date': date?.toIso8601String(),
      'title': title,
      'description': description,
      'budget': budget,
    };
  }

  static String? _parseString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
  }

  static String? _nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static String? _shortProcessCode(String? value) {
    final normalized = _nonEmpty(value);
    if (normalized == null) return null;

    const ocdsPrefix = 'ocds-5wno2w-';
    final suffix = normalized.toLowerCase().startsWith(ocdsPrefix)
        ? normalized.substring(ocdsPrefix.length)
        : normalized;
    final parts = suffix
        .split('-')
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    final shortCode = parts.length > 4 ? parts.take(4).join('-') : suffix;
    if (shortCode.length <= 36) return shortCode;
    return '${shortCode.substring(0, 35)}…';
  }

  static int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '');
  }

  static double? _parseDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is! String) return null;
    final normalized = value.trim().replaceAll(',', '');
    return double.tryParse(normalized);
  }

  static DateTime? _parseDate(Object? value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString().trim() ?? '');
  }

  static Object? _copyJsonValue(Object? value) {
    if (value is Map) {
      return value.map<String, dynamic>(
        (key, item) => MapEntry(key.toString(), _copyJsonValue(item)),
      );
    }
    if (value is Iterable) {
      return value.map<Object?>((item) => _copyJsonValue(item)).toList();
    }
    return value;
  }
}
