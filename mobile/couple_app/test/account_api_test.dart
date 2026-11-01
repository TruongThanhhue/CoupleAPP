import 'dart:convert';

import 'package:couple_app/features/auth/data/auth_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('profile update authenticates and sends only the trimmed name',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/v1/couples/me');
      expect(request.headers['Authorization'], 'Bearer account-token');
      expect(jsonDecode(request.body), {'displayName': 'Tên mới'});
      return http.Response(
          jsonEncode({
            'displayName': 'Tên mới',
            'partnerCode': 'CPL-ORIGINAL',
            'partner': null
          }),
          200, headers: {'content-type': 'application/json; charset=utf-8'});
    });
    addTearDown(client.close);
    final profile = await AuthApi(client: client)
        .updateProfile('account-token', '  Tên mới  ');
    expect(profile.partnerCode, 'CPL-ORIGINAL');
    expect(profile.displayName, 'Tên mới');
  });

  test('disconnect binds confirmation to expected partner and exposes conflict',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/couples/disconnect');
      expect(jsonDecode(request.body), {'partnerCode': 'CPL-EXPECTED'});
      return http.Response(
          jsonEncode({'message': 'Kết nối đã thay đổi.'}), 409,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    addTearDown(client.close);
    await expectLater(
        AuthApi(client: client).disconnectPartner('token', 'CPL-EXPECTED'),
        throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 409)));
  });
}
