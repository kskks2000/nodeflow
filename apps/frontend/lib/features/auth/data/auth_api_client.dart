import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_config.dart';
import '../domain/auth_models.dart';

class AuthApiClient {
  AuthApiClient({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _httpClient;
  final String _baseUrl;

  void close() {
    _httpClient.close();
  }

  Future<LoginResponse> login(LoginRequest request) async {
    final uri = Uri.parse('$_baseUrl/auth/login');

    late http.Response response;
    try {
      response = await _httpClient
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 8));
    } on Exception {
      throw const AuthFailure('API 서버에 연결할 수 없습니다. FastAPI 서버 상태를 확인해 주세요.');
    }

    final decoded = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return LoginResponse.fromJson(decoded);
      } on Object {
        throw const AuthFailure('서버 응답을 처리할 수 없습니다.');
      }
    }

    final error = decoded['error'];
    if (error is Map) {
      final errorBody = Map<String, Object?>.from(error);
      final code = errorBody['code'] as String?;
      if (code == 'AUTH_INVALID_CREDENTIALS') {
        throw const AuthFailure('회사코드, 아이디 또는 비밀번호가 올바르지 않습니다.');
      }
      if (code == 'AUTH_ACCOUNT_LOCKED') {
        throw const AuthFailure('잠긴 계정입니다. 관리자에게 문의해 주세요.');
      }
      final message = errorBody['message'] as String?;
      if (message != null && message.isNotEmpty) {
        throw AuthFailure(message);
      }
    }

    throw AuthFailure('로그인에 실패했습니다. 오류 코드: ${response.statusCode}');
  }

  Future<LoginResponse> register(RegisterRequest request) async {
    final uri = Uri.parse('$_baseUrl/auth/register');

    late http.Response response;
    try {
      response = await _httpClient
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 8));
    } on Exception {
      throw const AuthFailure('API 서버에 연결할 수 없습니다. FastAPI 서버 상태를 확인해 주세요.');
    }

    final decoded = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return LoginResponse.fromJson(decoded);
      } on Object {
        throw const AuthFailure('서버 응답을 처리할 수 없습니다.');
      }
    }

    final error = decoded['error'];
    if (error is Map) {
      final errorBody = Map<String, Object?>.from(error);
      final code = errorBody['code'] as String?;
      if (code == 'AUTH_USER_ALREADY_EXISTS') {
        throw const AuthFailure('이미 사용 중인 아이디입니다.');
      }
      final message = errorBody['message'] as String?;
      if (message != null && message.isNotEmpty) {
        throw AuthFailure(message);
      }
    }

    throw AuthFailure('회원가입에 실패했습니다. 오류 코드: ${response.statusCode}');
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
