import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

const _defaultApiBaseUrl = 'http://10.0.2.2:5248/api/v1';
const _requestTimeout = Duration(seconds: 20);

class AppUserProfile {
  const AppUserProfile({
    required this.displayName,
    required this.partnerCode,
    this.partner,
  });

  final String displayName;
  final String partnerCode;
  final PartnerProfile? partner;

  factory AppUserProfile.fromJson(Map<String, dynamic> json) => AppUserProfile(
        displayName: json['displayName'] as String,
        partnerCode: json['partnerCode'] as String,
        partner: json['partner'] == null
            ? null
            : PartnerProfile.fromJson(json['partner'] as Map<String, dynamic>),
      );
}

class PartnerProfile {
  const PartnerProfile({required this.displayName, required this.partnerCode});

  final String displayName;
  final String partnerCode;

  factory PartnerProfile.fromJson(Map<String, dynamic> json) => PartnerProfile(
        displayName: json['displayName'] as String,
        partnerCode: json['partnerCode'] as String,
      );
}

class PartnerInvite {
  const PartnerInvite({required this.id, required this.fromDisplayName});

  final String id;
  final String fromDisplayName;

  factory PartnerInvite.fromJson(Map<String, dynamic> json) => PartnerInvite(
        id: json['id'] as String,
        fromDisplayName: json['fromDisplayName'] as String,
      );
}

class SentPartnerInvite {
  const SentPartnerInvite({required this.id, required this.toDisplayName});

  final String id;
  final String toDisplayName;

  factory SentPartnerInvite.fromJson(Map<String, dynamic> json) =>
      SentPartnerInvite(
        id: json['id'] as String,
        toDisplayName: json['toDisplayName'] as String,
      );
}

class AuthApi {
  AuthApi({http.Client? client, FlutterSecureStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  final http.Client _client;
  final FlutterSecureStorage _storage;
  static const _tokenKey = 'access_token';

  Uri _uri(String path) => Uri.parse(
        '${const String.fromEnvironment('API_BASE_URL', defaultValue: _defaultApiBaseUrl)}$path',
      );

  Future<AuthResult?> restore() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;
    try {
      return AuthResult(token: token, user: await me(token));
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await signOut();
        return null;
      }
      rethrow;
    }
  }

  Future<AuthResult> register(
          {required String name,
          required String email,
          required String password}) =>
      _authenticate('/auth/register',
          {'displayName': name, 'email': email, 'password': password});

  Future<AuthResult> login({required String email, required String password}) =>
      _authenticate('/auth/login', {'email': email, 'password': password});

  Future<AuthResult> _authenticate(
      String path, Map<String, String> body) async {
    final response = await _client
        .post(_uri(path),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body))
        .timeout(_requestTimeout);
    final json = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode == 401
            ? 'Email hoặc mật khẩu không đúng.'
            : _message(json),
        statusCode: response.statusCode,
      );
    }
    final token = json['accessToken'] as String;
    await _storage.write(key: _tokenKey, value: token);
    return AuthResult(
        token: token,
        user: AppUserProfile.fromJson(json['user'] as Map<String, dynamic>));
  }

  Future<AppUserProfile> me(String token) async {
    final response = await _client
        .get(_uri('/couples/me'), headers: _headers(token))
        .timeout(_requestTimeout);
    final json = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(json), statusCode: response.statusCode);
    }
    return AppUserProfile.fromJson(json);
  }

  Future<AppUserProfile> updateProfile(String token, String displayName) async {
    final response = await _client
        .put(_uri('/couples/me'),
            headers: _headers(token),
            body: jsonEncode({'displayName': displayName.trim()}))
        .timeout(_requestTimeout);
    return _profileResponse(response);
  }

  Future<AppUserProfile> disconnectPartner(
      String token, String partnerCode) async {
    final response = await _client
        .post(_uri('/couples/disconnect'),
            headers: _headers(token),
            body: jsonEncode({'partnerCode': partnerCode}))
        .timeout(_requestTimeout);
    return _profileResponse(response);
  }

  AppUserProfile _profileResponse(http.Response response) {
    final json = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
          response.statusCode == 401
              ? 'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.'
              : _message(json),
          statusCode: response.statusCode);
    }
    return AppUserProfile.fromJson(json as Map<String, dynamic>);
  }

  Future<List<PartnerInvite>> invites(String token) async {
    final response = await _client
        .get(_uri('/couples/invites'), headers: _headers(token))
        .timeout(_requestTimeout);
    final json = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(json), statusCode: response.statusCode);
    }
    return (json as List<dynamic>)
        .map((item) => PartnerInvite.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<SentPartnerInvite>> sentInvites(String token) async {
    final response = await _client
        .get(_uri('/couples/invites/sent'), headers: _headers(token))
        .timeout(_requestTimeout);
    final json = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(json), statusCode: response.statusCode);
    }
    return (json as List<dynamic>)
        .map((item) => SentPartnerInvite.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendInvite(String token, String partnerCode) =>
      _post('/couples/invites', token, {'partnerCode': partnerCode});

  Future<void> acceptInvite(String token, String inviteId) =>
      _post('/couples/invites/$inviteId/accept', token, const {});

  Future<void> declineInvite(String token, String inviteId) =>
      _post('/couples/invites/$inviteId/decline', token, const {});

  Future<void> cancelInvite(String token, String inviteId) =>
      _post('/couples/invites/$inviteId/cancel', token, const {});

  Future<void> _post(
      String path, String token, Map<String, String> body) async {
    final response = await _client
        .post(_uri(path), headers: _headers(token), body: jsonEncode(body))
        .timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(_decode(response)),
          statusCode: response.statusCode);
    }
  }

  Future<void> signOut() => _storage.delete(key: _tokenKey);

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return const <String, dynamic>{};
    try {
      return jsonDecode(response.body);
    } on FormatException {
      return const <String, dynamic>{};
    }
  }

  String _message(dynamic json) {
    if (json is Map<String, dynamic>) {
      final message = json['message'];
      if (message is String) return message;
      final errors = json['errors'];
      if (errors is Map &&
          errors.values.isNotEmpty &&
          errors.values.first is List &&
          (errors.values.first as List).isNotEmpty)
        return (errors.values.first as List).first.toString();
    }
    return 'Không thể hoàn tất thao tác. Vui lòng thử lại.';
  }
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final AppUserProfile user;
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}

class SessionController extends ChangeNotifier {
  SessionController({AuthApi? api}) : api = api ?? AuthApi();

  final AuthApi api;
  String? _token;
  AppUserProfile? _user;
  bool _loading = true;
  String? _error;
  int _profileRevision = 0;
  bool _changingProfile = false;
  bool _disposed = false;

  AppUserProfile? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> restore() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await api.restore();
      _token = result?.token;
      _user = result?.user;
    } catch (_) {
      _error = 'Không thể kết nối máy chủ. Kiểm tra mạng rồi thử lại.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _error = null;
    final result = await api.login(email: email, password: password);
    _token = result.token;
    _user = result.user;
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    _error = null;
    final result =
        await api.register(name: name, email: email, password: password);
    _token = result.token;
    _user = result.user;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final token = _token;
    if (token == null || _changingProfile || _disposed) return;
    final revision = ++_profileRevision;
    final profile = await api.me(token);
    // Ignore a response from an account that signed out or changed meanwhile.
    if (_disposed || _token != token || revision != _profileRevision) return;
    _user = profile;
    notifyListeners();
  }

  Future<void> updateProfile(String displayName) =>
      _changeProfile((token) => api.updateProfile(token, displayName));

  Future<void> disconnectPartner(String expectedPartnerCode) => _changeProfile(
      (token) => api.disconnectPartner(token, expectedPartnerCode));

  Future<void> _changeProfile(
      Future<AppUserProfile> Function(String) change) async {
    final token = _token;
    if (_disposed || token == null) {
      throw const ApiException('Hãy đăng nhập lại để tiếp tục.',
          statusCode: 401);
    }
    if (_changingProfile)
      throw const ApiException('Đang lưu thay đổi. Vui lòng chờ.');
    _changingProfile = true;
    ++_profileRevision;
    try {
      final profile = await change(token);
      if (_disposed || _token != token) {
        throw const ApiException(
            'Phiên đăng nhập đã thay đổi. Hãy đăng nhập lại.');
      }
      _user = profile;
      notifyListeners();
    } finally {
      ++_profileRevision;
      _changingProfile = false;
    }
  }

  Future<void> signOut() async {
    await api.signOut();
    ++_profileRevision;
    _token = null;
    _user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_profileRevision;
    super.dispose();
  }
}
