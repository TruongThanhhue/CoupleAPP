import 'dart:async';
import 'dart:convert';

import 'package:couple_app/features/auth/data/auth_api.dart';
import 'package:couple_app/features/calendar/presentation/calendar_screen.dart';
import 'package:couple_app/features/tasks/presentation/tasks_screen.dart';
import 'package:couple_app/features/workspace/application/workspace_controller.dart';
import 'package:couple_app/features/workspace/data/workspace_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Session extends SessionController {
  String? currentToken = 'test-token';
  AppUserProfile? currentUser =
      const AppUserProfile(displayName: 'Mai', partnerCode: 'CPL-MAI');
  @override
  String? get token => currentToken;
  @override
  AppUserProfile? get user => currentUser;
  void logout() {
    currentToken = null;
    currentUser = null;
    notifyListeners();
  }

  void changePartner(String? partnerCode) {
    currentUser = AppUserProfile(
        displayName: 'Mai',
        partnerCode: 'CPL-MAI',
        partner: partnerCode == null
            ? null
            : PartnerProfile(displayName: 'Partner', partnerCode: partnerCode));
    notifyListeners();
  }
}

Map<String, dynamic> _task(
        {String title = 'Việc từ máy chủ', bool complete = false}) =>
    {
      'id': 'task-1',
      'title': title,
      'notes': null,
      'isComplete': complete,
      'isShared': false,
      'priority': 'normal',
      'dueAt': null,
      'createdByMe': true,
    };

http.Response _json(Object data, [int status = 200]) =>
    http.Response(jsonEncode(data), status,
        headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  test('API sends bearer token and exact mutation body; handles empty delete',
      () async {
    final requests = <http.Request>[];
    final api = WorkspaceApi(
        baseUrl: 'https://test.invalid/api/v1',
        client: MockClient((request) async {
          requests.add(request);
          return request.method == 'DELETE'
              ? http.Response('', 204)
              : _json(_task(), 201);
        }));
    await api.saveTask('secret', {'title': 'Mua hoa', 'isShared': false});
    await api.removeTask('secret', 'task-1');
    expect(requests.first.url.path, '/api/v1/tasks');
    expect(requests.first.method, 'POST');
    expect(requests.first.headers['Authorization'], 'Bearer secret');
    expect(jsonDecode(requests.first.body),
        {'title': 'Mua hoa', 'isShared': false});
    expect(requests.last.method, 'DELETE');
  });

  test('API surfaces validation and expired-session messages', () async {
    final api = WorkspaceApi(
        client:
            MockClient((request) async => request.url.path.endsWith('/events')
                ? _json({
                    'errors': {
                      'endsAt': ['Giờ kết thúc không hợp lệ.']
                    }
                  }, 400)
                : http.Response('', 401)));
    await expectLater(
        api.tasks('expired'),
        throwsA(isA<ApiException>()
            .having((error) => error.statusCode, 'status', 401)
            .having((error) => error.message, 'message', contains('hết hạn'))));
    await expectLater(
        api.saveEvent('token', {}),
        throwsA(isA<ApiException>().having((error) => error.message, 'message',
            'Giờ kết thúc không hợp lệ.')));
  });

  test('failed completion keeps server-confirmed task state and clears busy',
      () async {
    final session = _Session();
    final controller = WorkspaceController(
        session: session,
        api: WorkspaceApi(client: MockClient((request) async {
          if (request.method == 'PUT')
            return _json({'message': 'Không thể lưu.'}, 500);
          return _json(request.url.path.endsWith('/tasks') ? [_task()] : []);
        })));
    addTearDown(() {
      controller.dispose();
      session.dispose();
    });
    await controller.refresh();
    await expectLater(controller.toggleTask(controller.tasks.single),
        throwsA(isA<ApiException>()));
    expect(controller.tasks.single.isComplete, false);
    expect(controller.busy, false);
  });

  test('logout discards a pending response and clears private cached data',
      () async {
    final session = _Session();
    final pending = Completer<http.Response>();
    final controller = WorkspaceController(
        session: session,
        api: WorkspaceApi(client: MockClient((request) async {
          if (request.url.path.endsWith('/tasks')) return pending.future;
          return _json([]);
        })));
    addTearDown(() {
      controller.dispose();
      session.dispose();
    });
    final request = controller.refresh();
    session.logout();
    pending.complete(_json([_task()]));
    await request;
    expect(controller.tasks, isEmpty);
    expect(controller.events, isEmpty);
    expect(controller.loading, false);
  });

  test('load failure blocks mutations until a successful refresh', () async {
    final session = _Session();
    var fail = true;
    var postCount = 0;
    final controller = WorkspaceController(
        session: session,
        api: WorkspaceApi(client: MockClient((request) async {
          if (request.method == 'POST') {
            postCount++;
            return _json(_task(), 201);
          }
          return fail ? http.Response('', 503) : _json([]);
        })));
    addTearDown(() {
      controller.dispose();
      session.dispose();
    });
    await controller.refresh();
    expect(controller.error, isNotNull);
    await expectLater(controller.saveTask(values: {'title': 'Test'}),
        throwsA(isA<ApiException>()));
    expect(postCount, 0);
    fail = false;
    await controller.refresh();
    await controller.saveTask(values: {'title': 'Test'});
    expect(postCount, 1);
    expect(controller.tasks, hasLength(1));
  });

  test('partner change clears shared cache and ignores the old pending refresh',
      () async {
    final session = _Session()..changePartner('CPL-OLD');
    final pendingOld = Completer<http.Response>();
    var taskReads = 0;
    final controller = WorkspaceController(
        session: session,
        api: WorkspaceApi(client: MockClient((request) async {
          if (!request.url.path.endsWith('/tasks')) return _json([]);
          taskReads++;
          if (taskReads == 1)
            return _json([
              {..._task(), 'isShared': true}
            ]);
          if (taskReads == 2) return pendingOld.future;
          return _json([]);
        })));
    addTearDown(() {
      controller.dispose();
      session.dispose();
    });
    await controller.refresh();
    expect(controller.tasks, hasLength(1));
    final oldRefresh = controller.refresh();
    // Allow the request to enter MockClient before changing the relationship.
    await Future<void>.delayed(Duration.zero);
    session.changePartner(null);
    expect(controller.tasks, isEmpty);
    await Future<void>.delayed(Duration.zero);
    pendingOld.complete(_json([
      {..._task(), 'isShared': true}
    ]));
    await oldRefresh;
    expect(controller.tasks, isEmpty);
    expect(controller.events, isEmpty);
    expect(controller.loading, false);
  });

  testWidgets(
      'task form validates title and saves privately before showing success',
      (tester) async {
    final session = _Session();
    Map<String, dynamic>? sent;
    final controller = WorkspaceController(
        session: session,
        api: WorkspaceApi(client: MockClient((request) async {
          if (request.method == 'POST') {
            sent = jsonDecode(request.body) as Map<String, dynamic>;
            return _json({..._task(), ...sent!}, 201);
          }
          return _json([]);
        })));
    addTearDown(() {
      controller.dispose();
      session.dispose();
    });
    await controller.refresh();
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: TasksScreen(controller: controller))));
    expect(find.text('Chưa có việc nào'), findsOneWidget);
    await tester.tap(find.text('Thêm việc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Hãy nhập tên công việc.'), findsOneWidget);
    expect(sent, isNull);
    final sharing = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(sharing.onChanged, isNull);
    await tester.enterText(
        find.byType(TextFormField).first, 'Mua hoa cuối tuần');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(sent?['isShared'], false);
    expect(sent?['title'], 'Mua hoa cuối tuần');
    expect(controller.tasks.single.title, 'Mua hoa cuối tuần');
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Đã tạo công việc.'), findsOneWidget);
  });

  testWidgets(
      'calendar save failure preserves editor text and displays server error',
      (tester) async {
    final session = _Session();
    final controller = WorkspaceController(
        session: session,
        api: WorkspaceApi(client: MockClient((request) async {
          if (request.method == 'POST')
            return _json({'message': 'Không thể tạo cuộc hẹn.'}, 409);
          return _json([]);
        })));
    addTearDown(() {
      controller.dispose();
      session.dispose();
    });
    await controller.refresh();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CalendarScreen(controller: controller))));
    await tester.tap(find.text('Tạo sự kiện'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Ăn tối');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Ăn tối'), findsOneWidget);
    expect(find.text('Không thể tạo cuộc hẹn.'), findsOneWidget);
    expect(controller.events, isEmpty);
  });

  testWidgets('tasks show error without a misleading zero progress count',
      (tester) async {
    final session = _Session();
    final controller = WorkspaceController(
        session: session,
        api: WorkspaceApi(
            client: MockClient((_) async => http.Response('', 503))));
    addTearDown(() {
      controller.dispose();
      session.dispose();
    });
    await controller.refresh();
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: TasksScreen(controller: controller))));
    expect(find.text('Chưa tải được công việc'), findsOneWidget);
    expect(find.text('0 / 0 việc đã hoàn thành'), findsNothing);
    final create = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Thêm việc'));
    expect(create.onPressed, isNull);
  });
}
