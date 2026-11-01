import 'package:couple_app/features/auth/data/auth_api.dart';
import 'package:couple_app/features/auth/presentation/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('registration asks for a name and validates a long password',
      (tester) async {
    final session = SessionController();
    addTearDown(session.dispose);
    await tester.pumpWidget(MaterialApp(home: AuthScreen(session: session)));

    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pump();
    expect(find.text('Tên hiển thị'), findsOneWidget);

    await tester.tap(find.text('Tạo tài khoản'));
    await tester.pump();
    expect(find.text('Hãy nhập tên của bạn.'), findsOneWidget);
    expect(find.text('Mật khẩu cần tối thiểu 12 ký tự.'), findsOneWidget);
  });
}
