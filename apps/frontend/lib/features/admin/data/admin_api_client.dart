import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../domain/admin_models.dart';

class AdminApiClient {
  AdminApiClient({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _httpClient;
  final String _baseUrl;

  void close() {
    _httpClient.close();
  }

  Future<AdminOverview> fetchOverview({required String accessToken}) async {
    final decoded = await _request(
      'GET',
      '/admin/overview',
      accessToken: accessToken,
    );
    return AdminOverview.fromJson(decoded);
  }

  Future<List<AdminEntityDefinition>> fetchEntities({
    required String accessToken,
  }) async {
    final decoded = await _request(
      'GET',
      '/admin/entities',
      accessToken: accessToken,
    );
    final entities = decoded['entities'];
    if (entities is List) {
      return entities
          .whereType<Map>()
          .map((item) => AdminEntityDefinition.fromJson(Map.from(item)))
          .toList(growable: false);
    }
    return const [];
  }

  Future<AdminRecordListResponse> fetchRecords({
    required String accessToken,
    required String entityKey,
    int page = 1,
    int pageSize = 25,
    String? search,
    bool activeOnly = false,
  }) async {
    final query = {
      'page': '$page',
      'page_size': '$pageSize',
      'active_only': '$activeOnly',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final decoded = await _request(
      'GET',
      '/admin/entities/$entityKey/records',
      accessToken: accessToken,
      query: query,
    );
    return AdminRecordListResponse.fromJson(decoded);
  }

  Future<Map<String, Object?>> createRecord({
    required String accessToken,
    required String entityKey,
    required Map<String, Object?> data,
  }) async {
    final decoded = await _request(
      'POST',
      '/admin/entities/$entityKey/records',
      accessToken: accessToken,
      body: {'data': data},
    );
    return _jsonMap(decoded['record']);
  }

  Future<Map<String, Object?>> updateRecord({
    required String accessToken,
    required String entityKey,
    required int recordId,
    required Map<String, Object?> data,
  }) async {
    final decoded = await _request(
      'PUT',
      '/admin/entities/$entityKey/records/$recordId',
      accessToken: accessToken,
      body: {'data': data},
    );
    return _jsonMap(decoded['record']);
  }

  Future<void> deleteRecord({
    required String accessToken,
    required String entityKey,
    required int recordId,
  }) async {
    await _request(
      'DELETE',
      '/admin/entities/$entityKey/records/$recordId',
      accessToken: accessToken,
    );
  }

  Future<String> exportCsv({
    required String accessToken,
    required String entityKey,
    String? search,
    bool activeOnly = false,
  }) async {
    final query = {
      'active_only': '$activeOnly',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final uri = _uri('/admin/entities/$entityKey/export', query);
    final response = await _httpClient
        .get(uri, headers: _headers(accessToken))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return utf8.decode(response.bodyBytes);
    }
    throw _failureFromResponse(response);
  }

  Future<AdminImportResponse> importRows({
    required String accessToken,
    required String entityKey,
    required String fileName,
    required List<Map<String, Object?>> rows,
  }) async {
    final decoded = await _request(
      'POST',
      '/admin/entities/$entityKey/import',
      accessToken: accessToken,
      body: {'file_name': fileName, 'rows': rows, 'mode': 'create'},
    );
    return AdminImportResponse.fromJson(decoded);
  }

  Future<AdminAuditLogListResponse> fetchAuditLogs({
    required String accessToken,
    int page = 1,
    int pageSize = 25,
    String? search,
  }) async {
    final query = {
      'page': '$page',
      'page_size': '$pageSize',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final decoded = await _request(
      'GET',
      '/admin/audit-logs',
      accessToken: accessToken,
      query: query,
    );
    return AdminAuditLogListResponse.fromJson(decoded);
  }

  Future<Map<String, Object?>> _request(
    String method,
    String path, {
    required String accessToken,
    Map<String, String>? query,
    Map<String, Object?>? body,
  }) async {
    final uri = _uri(path, query);
    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _httpClient
              .get(uri, headers: _headers(accessToken))
              .timeout(const Duration(seconds: 10));
        case 'POST':
          response = await _httpClient
              .post(
                uri,
                headers: _headers(accessToken),
                body: jsonEncode(body ?? const {}),
              )
              .timeout(const Duration(seconds: 15));
        case 'PUT':
          response = await _httpClient
              .put(
                uri,
                headers: _headers(accessToken),
                body: jsonEncode(body ?? const {}),
              )
              .timeout(const Duration(seconds: 15));
        case 'DELETE':
          response = await _httpClient
              .delete(uri, headers: _headers(accessToken))
              .timeout(const Duration(seconds: 10));
        default:
          throw const AdminFailure('지원하지 않는 요청입니다.');
      }
    } on AdminFailure {
      rethrow;
    } on Exception {
      throw const AdminFailure('관리자 API 서버에 연결할 수 없습니다.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map) {
        return Map<String, Object?>.from(decoded);
      }
      return {};
    }
    throw _failureFromResponse(response);
  }

  Uri _uri(String path, Map<String, String>? query) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: query);
  }

  Map<String, String> _headers(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  AdminFailure _failureFromResponse(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map) {
          final message = error['message'] as String?;
          if (message != null && message.isNotEmpty) {
            return AdminFailure(message);
          }
        }
      }
    } on Exception {
      // Fall through to the status-code message.
    }
    if (response.statusCode == 401) {
      return const AdminFailure('로그인 세션이 만료되었습니다.');
    }
    if (response.statusCode == 403) {
      return const AdminFailure('관리자 권한이 없습니다.');
    }
    return AdminFailure('관리자 요청에 실패했습니다. 코드: ${response.statusCode}');
  }
}

Map<String, Object?> _jsonMap(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.from(value);
  }
  return {};
}
