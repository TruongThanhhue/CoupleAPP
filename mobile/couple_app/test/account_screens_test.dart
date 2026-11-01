import 'dart:async';

import 'package:couple_app/core/theme/couple_theme.dart';
import 'package:couple_app/features/auth/data/auth_api.dart';
import 'package:couple_app/features/auth/presentation/profile_screen.dart';
import 'package:couple_app/features/couple/presentation/partner_connection_screen.dart';
import 'package:couple_app/features/more/presentation/more_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _AccountApi extends AuthApi {
  @override
  Future<List<PartnerInvite>> invites(String token) async => [];

  @override
  Future<List<SentPartnerInvite>> sentInvites(String token) async => [];
}

class _AccountSession extends SessionController {
  _AccountSession() : super(api: _AccountApi());
  AppUserProfile profile = const AppUserProfile(
      displayName: 'Mai',
      partnerCode: 'CPL-TESTAAAA',
      partner: PartnerProfile(displayName: 'An', partnerCode: 'CPL-TESTBBBB'));
  String? savedName;
  String? disconnectedCode;
  bool failSave = false;
  Completer<void>? pendingSave;

  @override
  AppUserProfile get user => profile;
  @override
  String get token => 'test-token';
  @override
  Future<void> refreshProfile() async {}

  @override
  Future<void> updateProfile(String name) async {
    savedName = name;
    if (pendingSave != null) await pendingSave!.future;
    if (failSave) throw const ApiException('Không lưu được hồ sơ.');
    profile = AppUserProfile(
        displayName: name,
        partnerCode: profile.partnerCode,
        partner: profile.partner);
    notifyListeners();
  }

  @override
  Future<void> disconnectPartner(String code) async {
    disconnectedCode = code;
    profile = AppUserProfile(
        displayName: profile.displayName, partnerCode: profile.partnerCode);
    notifyListeners();
  }

  void changePartner() {
    profile = AppUserProfile(
        displayName: profile.displayName,
        partnerCode: profile.partnerCode,
        partner: const PartnerProfile(
            displayName: 'Bình', partnerCode: 'CPL-TESTCCCC'));
    notifyListeners();
  }
}

Future<void> _pump(WidgetTester tester, Widget screen,
    {bool largeText = false}) async {
  await tester.pumpWidget(MaterialApp(
    theme: CoupleTheme.light(),
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(largeText ? 2 : 1)),
        child: child!),
    home: screen,
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'profile rejects empty name and saves a trimmed name with stable code',
      (tester) async {
    final session = _AccountSession();
    addTearDown(session.dispose);
    await _pump(tester, ProfileScreen(session: session));
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(find.text('Tên hiển thị cần từ 1 đến 80 ký tự.'), findsOneWidget);
    expect(session.savedName, isNull);
    await tester.enterText(find.byType(TextFormField), '  Mai Anh  ');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(session.savedName, 'Mai Anh');
    expect(session.user.displayName, 'Mai Anh');
    expect(find.text('CPL-TESTAAAA'), findsOneWidget);
    expect(find.text('Đã cập nhật hồ sơ.'), findsOneWidget);
  });

  testWidgets(
      'failed save retains input and disables duplicate submissions while waiting',
      (tester) async {
    final session = _AccountSession()..failSave = true;
    session.pendingSave = Completer<void>();
    addTearDown(session.dispose);
    await _pump(tester, ProfileScreen(session: session));
    await tester.enterText(find.byType(TextFormField), 'Tên mới');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    session.pendingSave!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Không lưu được hồ sơ.'), findsOneWidget);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'Tên mới');
    session.failSave = false;
    session.pendingSave = null;
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(session.user.displayName, 'Tên mới');
  });

  testWidgets('More reacts to saved profile names', (tester) async {
    final session = _AccountSession();
    addTearDown(session.dispose);
    await _pump(tester, Scaffold(body: MoreScreen(session: session)));
    expect(find.text('Mai'), findsOneWidget);
    await session.updateProfile('Mai Anh');
    await tester.pump();
    expect(find.text('Mai Anh'), findsOneWidget);
  });

  testWidgets(
      'cancelled disconnect never calls API; confirmed disconnect clears partner',
      (tester) async {
    final session = _AccountSession();
    addTearDown(session.dispose);
    await _pump(tester, PartnerConnectionScreen(session: session));
    await tester.tap(find.text('Ngắt kết nối'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mỗi người giữ'), findsOneWidget);
    await tester.tap(find.text('Giữ kết nối'));
    await tester.pumpAndSettle();
    expect(session.disconnectedCode, isNull);
    await tester.tap(find.text('Ngắt kết nối'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận ngắt kết nối'));
    await tester.pumpAndSettle();
    expect(session.disconnectedCode, 'CPL-TESTBBBB');
    expect(session.user.partner, isNull);
    expect(find.text('Nhập mã partner'), findsOneWidget);
  });

  testWidgets('confirmation sends the originally displayed partner code',
      (tester) async {
    final session = _AccountSession();
    addTearDown(session.dispose);
    await _pump(tester, PartnerConnectionScreen(session: session));
    await tester.tap(find.text('Ngắt kết nối'));
    await tester.pumpAndSettle();
    session.changePartner();
    await tester.pump();
    await tester.tap(find.text('Xác nhận ngắt kết nối'));
    await tester.pumpAndSettle();
    expect(session.disconnectedCode, 'CPL-TESTBBBB');
  });

  testWidgets('disconnect confirmation supports small screen and large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = _AccountSession();
    addTearDown(session.dispose);
    await _pump(tester, PartnerConnectionScreen(session: session),
        largeText: true);
    await tester.scrollUntilVisible(find.text('Ngắt kết nối'), 250,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.text('Ngắt kết nối'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Giữ kết nối'));
    await tester.pumpAndSettle();
    expect(session.disconnectedCode, isNull);
  });
}
