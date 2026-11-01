import 'dart:async';

import 'package:couple_app/features/auth/data/auth_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _PendingProfileApi extends AuthApi {
  final pending = Completer<AppUserProfile>();

  @override
  Future<AuthResult> login(
          {required String email, required String password}) async =>
      const AuthResult(
          token: 'test-token',
          user: AppUserProfile(
              displayName: 'Người kiểm thử', partnerCode: 'CPL-TESTCODE'));

  @override
  Future<AppUserProfile> me(String token) => pending.future;

  @override
  Future<AppUserProfile> updateProfile(
          String token, String displayName) async =>
      AppUserProfile(displayName: displayName, partnerCode: 'CPL-TESTCODE');

  @override
  Future<AppUserProfile> disconnectPartner(
          String token, String partnerCode) async =>
      const AppUserProfile(
          displayName: 'Người kiểm thử', partnerCode: 'CPL-TESTCODE');

  @override
  Future<void> signOut() async {}
}

void main() {
  test('old profile refresh cannot overwrite a newly saved name', () async {
    final api = _PendingProfileApi();
    final session = SessionController(api: api);
    addTearDown(session.dispose);
    await session.login('test@example.invalid', 'test-password');
    final refresh = session.refreshProfile();
    await session.updateProfile('Tên mới');
    api.pending.complete(const AppUserProfile(
        displayName: 'Tên cũ', partnerCode: 'CPL-TESTCODE'));
    await refresh;
    expect(session.user?.displayName, 'Tên mới');
  });

  test('old refresh cannot restore partner after successful disconnect',
      () async {
    final api = _PendingProfileApi();
    final session = SessionController(api: api);
    addTearDown(session.dispose);
    await session.login('test@example.invalid', 'test-password');
    final refresh = session.refreshProfile();
    await session.disconnectPartner('CPL-OLDPARTNER');
    api.pending.complete(const AppUserProfile(
        displayName: 'Tên cũ',
        partnerCode: 'CPL-TESTCODE',
        partner: PartnerProfile(
            displayName: 'Partner cũ', partnerCode: 'CPL-OLDPARTNER')));
    await refresh;
    expect(session.user?.partner, isNull);
  });

  test('late profile response cannot restore a signed-out account', () async {
    final api = _PendingProfileApi();
    final session = SessionController(api: api);
    addTearDown(session.dispose);
    await session.login('test@example.invalid', 'test-password');
    final refresh = session.refreshProfile();
    await session.signOut();
    api.pending.complete(const AppUserProfile(
        displayName: 'Hồ sơ cũ', partnerCode: 'CPL-TESTCODE'));
    await refresh;
    expect(session.user, isNull);
    expect(session.token, isNull);
  });
}
