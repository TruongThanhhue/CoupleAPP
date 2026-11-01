import 'dart:convert';

import 'package:couple_app/core/theme/couple_theme.dart';
import 'package:couple_app/features/auth/data/auth_api.dart';
import 'package:couple_app/features/home/presentation/home_screen.dart';
import 'package:couple_app/features/workspace/application/workspace_controller.dart';
import 'package:couple_app/features/workspace/data/workspace_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _HomeSession extends SessionController {
  _HomeSession({this.connected = true});
  final bool connected;

  @override
  String get token => 'test-session';

  @override
  AppUserProfile get user => AppUserProfile(
        displayName: 'Nguyễn Thanh Trúc',
        partnerCode: 'CPL-TESTAAAA',
        partner: connected
            ? const PartnerProfile(
                displayName: 'Phạm Minh Khang', partnerCode: 'CPL-TESTBBBB')
            : null,
      );
}

Future<WorkspaceController> _controller({bool connected = true}) async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day, 15);
  final client = MockClient((request) async {
    if (request.url.path.endsWith('/tasks')) {
      return http.Response(
          jsonEncode([
            {
              'id': 'task-1',
              'title': 'Chuẩn bị bữa tối',
              'notes': null,
              'isComplete': true,
              'isShared': true,
              'priority': 'normal',
              'dueAt': null,
              'createdByMe': true,
            },
            {
              'id': 'task-2',
              'title': 'Đặt bàn cuối tuần',
              'notes': null,
              'isComplete': false,
              'isShared': false,
              'priority': 'high',
              'dueAt': null,
              'createdByMe': true,
            },
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    }
    return http.Response(
        jsonEncode([
          {
            'id': 'event-1',
            'title': 'Đi dạo cùng nhau bên hồ vào buổi chiều cuối tuần',
            'notes': null,
            'location': 'Công viên gần nhà',
            'startsAt': start.toUtc().toIso8601String(),
            'endsAt':
                start.add(const Duration(hours: 1)).toUtc().toIso8601String(),
            'isShared': true,
            'createdByMe': true,
          },
        ]),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'});
  });
  final session = _HomeSession(connected: connected);
  final controller =
      WorkspaceController(session: session, api: WorkspaceApi(client: client));
  addTearDown(() {
    controller.dispose();
    session.dispose();
    client.close();
  });
  await controller.refresh();
  return controller;
}

void main() {
  testWidgets('home shows real session and records and navigates to tasks',
      (tester) async {
    final controller = await _controller();
    int? selectedTab;
    await tester.pumpWidget(MaterialApp(
      theme: CoupleTheme.light(),
      home: Scaffold(
          body: HomeScreen(
              controller: controller,
              onSelectTab: (value) => selectedTab = value)),
    ));
    expect(find.text('Nguyễn Thanh Trúc & Phạm Minh Khang'), findsOneWidget);
    expect(find.text('1 / 2 việc đã hoàn thành'), findsOneWidget);
    expect(find.text('Minh & An'), findsNothing);
    expect(find.text('1.248 ngày cùng nhau'), findsNothing);
    await tester.tap(find.text('Xem việc cần làm'));
    expect(selectedTab, 2);
    await tester.scrollUntilVisible(find.text('Thêm việc'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Thêm việc'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home supports small screen, large text and dark theme',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = await _controller();
    await tester.pumpWidget(MaterialApp(
      theme: CoupleTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(
          body: HomeScreen(controller: controller, onSelectTab: (_) {})),
    ));
    expect(tester.takeException(), isNull);
    for (var step = 0; step < 10; step++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('unpaired profile offers the partner connection destination',
      (tester) async {
    final controller = await _controller(connected: false);
    int? selectedTab;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: HomeScreen(
              controller: controller,
              onSelectTab: (value) => selectedTab = value)),
    ));
    expect(find.text('Chào Nguyễn Thanh Trúc'), findsOneWidget);
    await tester.tap(find.text('Kết nối partner'));
    expect(selectedTab, 4);
  });
}
