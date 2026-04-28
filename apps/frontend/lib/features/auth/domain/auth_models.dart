class LoginRequest {
  const LoginRequest({
    required this.companyCode,
    required this.loginId,
    required this.password,
  });

  final String companyCode;
  final String loginId;
  final String password;

  Map<String, Object?> toJson() {
    return {
      'company_code': companyCode,
      'login_id': loginId,
      'password': password,
    };
  }
}

class RegisterRequest {
  const RegisterRequest({
    required this.companyCode,
    required this.loginId,
    required this.password,
  });

  final String companyCode;
  final String loginId;
  final String password;

  Map<String, Object?> toJson() {
    return {
      'company_code': companyCode,
      'login_id': loginId,
      'password': password,
    };
  }
}

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
    required this.tenant,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final AuthUser user;
  final AuthTenant tenant;

  factory LoginResponse.fromJson(Map<String, Object?> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: json['expires_in'] as int,
      user: AuthUser.fromJson(_jsonMap(json['user'])),
      tenant: AuthTenant.fromJson(_jsonMap(json['tenant'])),
    );
  }
}

class AuthTenant {
  const AuthTenant({
    required this.id,
    required this.code,
    required this.name,
    required this.timezone,
    required this.locale,
  });

  final int id;
  final String code;
  final String name;
  final String timezone;
  final String locale;

  factory AuthTenant.fromJson(Map<String, Object?> json) {
    return AuthTenant(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      timezone: json['timezone'] as String,
      locale: json['locale'] as String,
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.loginId,
    required this.name,
    required this.userType,
    required this.roles,
    this.email,
    this.companyId,
    this.branchId,
  });

  final int id;
  final String loginId;
  final String name;
  final String userType;
  final List<String> roles;
  final String? email;
  final int? companyId;
  final int? branchId;

  factory AuthUser.fromJson(Map<String, Object?> json) {
    return AuthUser(
      id: json['id'] as int,
      loginId: json['login_id'] as String,
      name: json['name'] as String,
      userType: json['user_type'] as String,
      roles: _stringList(json['roles']),
      email: json['email'] as String?,
      companyId: json['company_id'] as int?,
      branchId: json['branch_id'] as int?,
    );
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

Map<String, Object?> _jsonMap(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.from(value);
  }
  return {};
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList(growable: false);
  }
  return const [];
}
