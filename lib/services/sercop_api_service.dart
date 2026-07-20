import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/errors/app_exception.dart';
import '../models/procurement_detail.dart';
import '../models/procurement_search_response.dart';

abstract interface class SercopDataSource {
  Future<ProcurementSearchResponse> buscarProcesos({
    required int year,
    required String keyword,
    required String buyer,
    int page,
  });

  Future<ProcurementDetail> obtenerDetalle(String ocid);
}

class SercopApiService implements SercopDataSource {
  SercopApiService(this._client, {this.timeout = const Duration(seconds: 20)});

  final http.Client _client;
  final Duration timeout;

  @override
  Future<ProcurementSearchResponse> buscarProcesos({
    required int year,
    required String keyword,
    required String buyer,
    int page = 1,
  }) async {
    final root = await _getJsonObject(
      _buildUri('search_ocds', <String, String>{
        'year': year.toString(),
        'search': keyword,
        'buyer': buyer,
        'page': page.toString(),
      }),
    );
    if (root['data'] is! List) {
      throw const InvalidResponseException();
    }

    try {
      return ProcurementSearchResponse.fromJson(root);
    } on FormatException {
      throw const JsonParsingException();
    }
  }

  @override
  Future<ProcurementDetail> obtenerDetalle(String ocid) async {
    final normalizedOcid = ocid.trim();
    if (normalizedOcid.isEmpty) throw const ProcessNotFoundException();

    final root = await _getJsonObject(
      _buildUri('record', <String, String>{'ocid': normalizedOcid}),
    );
    try {
      return ProcurementDetail.fromJson(root);
    } on FormatException {
      throw const JsonParsingException();
    }
  }

  Uri _buildUri(String endpoint, Map<String, String> queryParameters) {
    final baseUri = Uri.parse(AppConfig.sercopApiBaseUrl);
    return baseUri.replace(
      path: '${baseUri.path}/$endpoint',
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> _getJsonObject(Uri uri) async {
    try {
      final response = await _client
          .get(
            uri,
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw const SercopHttpException();
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        throw const InvalidResponseException();
      }

      final root = decoded.map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), value),
      );
      return root;
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on http.ClientException {
      throw const NetworkException();
    } on AppException {
      rethrow;
    } on FormatException {
      throw const JsonParsingException();
    } catch (_) {
      throw const UnknownAppException();
    }
  }
}
