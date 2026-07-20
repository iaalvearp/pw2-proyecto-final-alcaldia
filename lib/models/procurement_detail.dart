class ProcurementDetail {
  const ProcurementDetail({
    this.uri,
    this.license,
    this.version,
    this.releases = const <ProcurementRelease>[],
    this.publisher,
    this.extensions = const <Object?>[],
    this.publishedDate,
    this.publicationPolicy,
  });

  final String? uri;
  final String? license;
  final String? version;
  final List<ProcurementRelease> releases;
  final Object? publisher;
  final List<Object?> extensions;
  final DateTime? publishedDate;
  final Object? publicationPolicy;

  factory ProcurementDetail.fromJson(Map<String, dynamic> json) {
    return ProcurementDetail(
      uri: _string(json['uri']),
      license: _string(json['license']),
      version: _string(json['version']),
      releases: _mapList(
        json['releases'],
      ).map(ProcurementRelease.fromJson).toList(growable: false),
      publisher: json['publisher'],
      extensions: _objectList(json['extensions']),
      publishedDate: _date(json['publishedDate']),
      publicationPolicy: json['publicationPolicy'],
    );
  }

  ProcurementRelease? get primaryRelease =>
      releases.isEmpty ? null : releases.last;

  String? get ocid => primaryRelease?.ocid;
  String? get description =>
      primaryRelease?.tender?.description ??
      primaryRelease?.planning?.rationale;
  String? get buyerName => primaryRelease?.buyer?.name;
  String? get buyerId => primaryRelease?.buyer?.id;
  double? get budget => primaryRelease?.planning?.budget?.amount?.amount;
  double? get tenderValue => primaryRelease?.tender?.value.amount;
  double? get awardedAmount =>
      _firstValue(primaryRelease?.awards.map((award) => award.value.amount));
  double? get contractAmount => _firstValue(
    primaryRelease?.contracts.map((contract) => contract.value.amount),
  );
  String? get awardedSupplier {
    final awards = primaryRelease?.awards ?? const <ProcurementAward>[];
    for (final award in awards) {
      for (final supplier in award.suppliers) {
        if (supplier.name != null) return supplier.name;
      }
    }
    return null;
  }

  String? get tenderStatus => primaryRelease?.tender?.status;
  String? get contractStatus => primaryRelease?.contracts
      .where((contract) => contract.status != null)
      .firstOrNull
      ?.status;
  DateTime? get signedDate => primaryRelease?.contracts
      .where((contract) => contract.dateSigned != null)
      .firstOrNull
      ?.dateSigned;
  DateTime? get contractStartDate => primaryRelease?.contracts
      .where((contract) => contract.period?.startDate != null)
      .firstOrNull
      ?.period
      ?.startDate;
  DateTime? get contractEndDate => primaryRelease?.contracts
      .where((contract) => contract.period?.endDate != null)
      .firstOrNull
      ?.period
      ?.endDate;
  DateTime? get tenderStartDate =>
      primaryRelease?.tender?.tenderPeriod?.startDate;
  DateTime? get tenderEndDate => primaryRelease?.tender?.tenderPeriod?.endDate;
  DateTime? get awardDate => primaryRelease?.awards
      .where((award) => award.date != null)
      .firstOrNull
      ?.date;
  DateTime? get releaseDate => primaryRelease?.date;
  String? get tenderId => primaryRelease?.tender?.id;
  String? get tenderTitle => primaryRelease?.tender?.title;
  String? get awardDescription => primaryRelease?.awards
      .where((award) => award.description != null)
      .firstOrNull
      ?.description;
  String? get contractId => primaryRelease?.contracts
      .where((contract) => contract.id != null)
      .firstOrNull
      ?.id;
  String? get method => primaryRelease?.tender?.procurementMethod;
  String? get methodDetails => primaryRelease?.tender?.procurementMethodDetails;
  String? get category => primaryRelease?.tender?.mainProcurementCategory;

  bool get hasMeaningfulInformation {
    return <Object?>[
      description,
      buyerName,
      budget,
      tenderValue,
      awardedAmount,
      contractAmount,
      awardedSupplier,
      tenderStatus,
      contractStatus,
      method,
      methodDetails,
      category,
    ].any((value) => value != null);
  }

  List<Map<String, dynamic>> get documents {
    final release = primaryRelease;
    if (release == null) return const <Map<String, dynamic>>[];
    return <Map<String, dynamic>>[
      ...release.documents,
      ...?release.tender?.documents,
      for (final award in release.awards) ...award.documents,
      for (final contract in release.contracts) ...contract.documents,
    ];
  }

  static double? _firstValue(Iterable<double?>? values) {
    if (values == null) return null;
    for (final value in values) {
      if (value != null) return value;
    }
    return null;
  }
}

class ProcurementRelease {
  const ProcurementRelease({
    this.id,
    this.ocid,
    this.tags = const <String>[],
    this.date,
    this.buyer,
    this.planning,
    this.tender,
    this.awards = const <ProcurementAward>[],
    this.contracts = const <ProcurementContract>[],
    this.parties = const <ProcurementParty>[],
    this.documents = const <Map<String, dynamic>>[],
    this.implementation,
    this.relatedProcesses = const <Map<String, dynamic>>[],
  });

  final String? id;
  final String? ocid;
  final List<String> tags;
  final DateTime? date;
  final ProcurementBuyer? buyer;
  final ProcurementPlanning? planning;
  final ProcurementTender? tender;
  final List<ProcurementAward> awards;
  final List<ProcurementContract> contracts;
  final List<ProcurementParty> parties;
  final List<Map<String, dynamic>> documents;
  final Map<String, dynamic>? implementation;
  final List<Map<String, dynamic>> relatedProcesses;

  factory ProcurementRelease.fromJson(Map<String, dynamic> json) {
    return ProcurementRelease(
      id: _string(json['id']),
      ocid: _string(json['ocid']),
      tags: _strings(json['tag']),
      date: _date(json['date']),
      buyer: _nullableMap(json['buyer'], ProcurementBuyer.fromJson),
      planning: _nullableMap(json['planning'], ProcurementPlanning.fromJson),
      tender: _nullableMap(json['tender'], ProcurementTender.fromJson),
      awards: _mapList(
        json['awards'],
      ).map(ProcurementAward.fromJson).toList(growable: false),
      contracts: _mapList(
        json['contracts'],
      ).map(ProcurementContract.fromJson).toList(growable: false),
      parties: _mapList(
        json['parties'],
      ).map(ProcurementParty.fromJson).toList(growable: false),
      documents: _mapList(json['documents']),
      implementation: _map(json['implementation']),
      relatedProcesses: _mapList(json['relatedProcesses']),
    );
  }
}

class ProcurementBuyer {
  const ProcurementBuyer({this.id, this.name});

  final String? id;
  final String? name;

  factory ProcurementBuyer.fromJson(Map<String, dynamic> json) =>
      ProcurementBuyer(id: _string(json['id']), name: _string(json['name']));
}

class ProcurementPlanning {
  const ProcurementPlanning({this.budget, this.rationale});

  final ProcurementBudget? budget;
  final String? rationale;

  factory ProcurementPlanning.fromJson(Map<String, dynamic> json) {
    return ProcurementPlanning(
      budget: _nullableMap(json['budget'], ProcurementBudget.fromJson),
      rationale: _string(json['rationale']),
    );
  }
}

class ProcurementBudget {
  const ProcurementBudget({this.id, this.amount});

  final String? id;
  final ProcurementValue? amount;

  factory ProcurementBudget.fromJson(Map<String, dynamic> json) {
    return ProcurementBudget(
      id: _string(json['id']),
      amount: _nullableMap(json['amount'], ProcurementValue.fromJson),
    );
  }
}

class ProcurementTender {
  const ProcurementTender({
    this.id,
    this.title,
    this.description,
    this.status,
    this.procurementMethod,
    this.procurementMethodDetails,
    this.mainProcurementCategory,
    this.value = const ProcurementValue(),
    this.tenderPeriod,
    this.enquiryPeriod,
    this.awardPeriod,
    this.items = const <Map<String, dynamic>>[],
    this.documents = const <Map<String, dynamic>>[],
  });

  final String? id;
  final String? title;
  final String? description;
  final String? status;
  final String? procurementMethod;
  final String? procurementMethodDetails;
  final String? mainProcurementCategory;
  final ProcurementValue value;
  final ProcurementPeriod? tenderPeriod;
  final ProcurementPeriod? enquiryPeriod;
  final ProcurementPeriod? awardPeriod;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> documents;

  factory ProcurementTender.fromJson(Map<String, dynamic> json) {
    return ProcurementTender(
      id: _string(json['id']),
      title: _string(json['title']),
      description: _string(json['description']),
      status: _string(json['status']),
      procurementMethod: _string(json['procurementMethod']),
      procurementMethodDetails: _string(json['procurementMethodDetails']),
      mainProcurementCategory: _string(json['mainProcurementCategory']),
      value:
          _nullableMap(json['value'], ProcurementValue.fromJson) ??
          const ProcurementValue(),
      tenderPeriod: _nullableMap(
        json['tenderPeriod'],
        ProcurementPeriod.fromJson,
      ),
      enquiryPeriod: _nullableMap(
        json['enquiryPeriod'],
        ProcurementPeriod.fromJson,
      ),
      awardPeriod: _nullableMap(
        json['awardPeriod'],
        ProcurementPeriod.fromJson,
      ),
      items: _mapList(json['items']),
      documents: _mapList(json['documents']),
    );
  }
}

class ProcurementAward {
  const ProcurementAward({
    this.id,
    this.description,
    this.status,
    this.date,
    this.value = const ProcurementValue(),
    this.suppliers = const <ProcurementPartyReference>[],
    this.documents = const <Map<String, dynamic>>[],
  });

  final String? id;
  final String? description;
  final String? status;
  final DateTime? date;
  final ProcurementValue value;
  final List<ProcurementPartyReference> suppliers;
  final List<Map<String, dynamic>> documents;

  factory ProcurementAward.fromJson(Map<String, dynamic> json) {
    return ProcurementAward(
      id: _string(json['id']),
      description: _string(json['description']),
      status: _string(json['status']),
      date: _date(json['date']),
      value:
          _nullableMap(json['value'], ProcurementValue.fromJson) ??
          const ProcurementValue(),
      suppliers: _mapList(
        json['suppliers'],
      ).map(ProcurementPartyReference.fromJson).toList(growable: false),
      documents: _mapList(json['documents']),
    );
  }
}

class ProcurementContract {
  const ProcurementContract({
    this.id,
    this.awardId,
    this.title,
    this.description,
    this.status,
    this.dateSigned,
    this.period,
    this.value = const ProcurementValue(),
    this.documents = const <Map<String, dynamic>>[],
    this.implementation,
  });

  final String? id;
  final String? awardId;
  final String? title;
  final String? description;
  final String? status;
  final DateTime? dateSigned;
  final ProcurementPeriod? period;
  final ProcurementValue value;
  final List<Map<String, dynamic>> documents;
  final Map<String, dynamic>? implementation;

  factory ProcurementContract.fromJson(Map<String, dynamic> json) {
    return ProcurementContract(
      id: _string(json['id']),
      awardId: _string(json['awardID']),
      title: _string(json['title']),
      description: _string(json['description']),
      status: _string(json['status']),
      dateSigned: _date(json['dateSigned']),
      period: _nullableMap(json['period'], ProcurementPeriod.fromJson),
      value:
          _nullableMap(json['value'], ProcurementValue.fromJson) ??
          const ProcurementValue(),
      documents: _mapList(json['documents']),
      implementation: _map(json['implementation']),
    );
  }
}

class ProcurementParty {
  const ProcurementParty({
    this.id,
    this.name,
    this.roles = const <String>[],
    this.identifier,
    this.address,
    this.contactPoint,
  });

  final String? id;
  final String? name;
  final List<String> roles;
  final Map<String, dynamic>? identifier;
  final Map<String, dynamic>? address;
  final Map<String, dynamic>? contactPoint;

  factory ProcurementParty.fromJson(Map<String, dynamic> json) {
    return ProcurementParty(
      id: _string(json['id']),
      name: _string(json['name']),
      roles: _strings(json['roles']),
      identifier: _map(json['identifier']),
      address: _map(json['address']),
      contactPoint: _map(json['contactPoint']),
    );
  }
}

class ProcurementPartyReference {
  const ProcurementPartyReference({this.id, this.name});

  final String? id;
  final String? name;

  factory ProcurementPartyReference.fromJson(Map<String, dynamic> json) =>
      ProcurementPartyReference(
        id: _string(json['id']),
        name: _string(json['name']),
      );
}

class ProcurementValue {
  const ProcurementValue({this.amount, this.currency});

  final double? amount;
  final String? currency;

  factory ProcurementValue.fromJson(Map<String, dynamic> json) =>
      ProcurementValue(
        amount: _double(json['amount']),
        currency: _string(json['currency']),
      );
}

class ProcurementPeriod {
  const ProcurementPeriod({this.startDate, this.endDate, this.maxExtentDate});

  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? maxExtentDate;

  factory ProcurementPeriod.fromJson(Map<String, dynamic> json) =>
      ProcurementPeriod(
        startDate: _date(json['startDate']),
        endDate: _date(json['endDate']),
        maxExtentDate: _date(json['maxExtentDate']),
      );
}

T? _nullableMap<T>(Object? value, T Function(Map<String, dynamic>) parser) {
  final map = _map(value);
  return map == null ? null : parser(map);
}

Map<String, dynamic>? _map(Object? value) {
  if (value is! Map) return null;
  return value.map<String, dynamic>(
    (key, item) => MapEntry(key.toString(), item),
  );
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! Iterable) return const <Map<String, dynamic>>[];
  return value
      .map(_map)
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

List<Object?> _objectList(Object? value) {
  if (value is Iterable) return value.toList(growable: false);
  return value == null ? const <Object?>[] : <Object?>[value];
}

List<String> _strings(Object? value) {
  if (value is Iterable) {
    return value.map(_string).whereType<String>().toList(growable: false);
  }
  final single = _string(value);
  return single == null ? const <String>[] : <String>[single];
}

String? _string(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
}

double? _double(Object? value) {
  if (value is num) return value.toDouble();
  if (value is! String) return null;
  return double.tryParse(value.trim().replaceAll(',', ''));
}

DateTime? _date(Object? value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString().trim() ?? '');
}
