import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../domain/transport_order_models.dart';

class TransportOrderApiClient {
  TransportOrderApiClient({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _httpClient;
  final String _baseUrl;

  void close() {
    _httpClient.close();
  }

  Future<TransportOrderResponse> createOrder(
    TransportOrderCreateRequest request, {
    required String accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/orders');

    late http.Response response;
    try {
      response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 8));
    } on Exception {
      throw const TransportOrderFailure(
        'API 서버에 연결할 수 없습니다. FastAPI 서버 상태를 확인해 주세요.',
      );
    }

    final decoded = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return TransportOrderResponse.fromJson(decoded);
      } on Object {
        throw const TransportOrderFailure('서버 응답을 처리할 수 없습니다.');
      }
    }

    final error = decoded['error'];
    if (error is Map) {
      final errorBody = Map<String, Object?>.from(error);
      final message = errorBody['message'] as String?;
      if (message != null && message.isNotEmpty) {
        throw TransportOrderFailure(message);
      }
    }

    if (response.statusCode == 401) {
      throw const TransportOrderFailure('로그인 세션이 만료되었습니다. 다시 로그인해 주세요.');
    }
    throw TransportOrderFailure(
      '운송오더 등록에 실패했습니다. 오류 코드: ${response.statusCode}',
    );
  }

  Map<String, Object?> _decodeBody(String body) {
    if (body.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return Map<String, Object?>.from(decoded);
      }
    } on FormatException {
      return {};
    }
    return {};
  }
}
