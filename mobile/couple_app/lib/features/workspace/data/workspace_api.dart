import 'dart:convert';

import 'package:couple_app/features/auth/data/auth_api.dart';
import 'package:http/http.dart' as http;

class WorkspaceTask {
  const WorkspaceTask(
      {required this.id,
      required this.title,
      this.notes,
      required this.isComplete,
      required this.isShared,
      required this.priority,
      this.dueAt,
      required this.createdByMe});

  final String id;
  final String title;
  final String? notes;
  final bool isComplete;
  final bool isShared;
  final String priority;
  final DateTime? dueAt;
  final bool createdByMe;

  factory WorkspaceTask.fromJson(Map<String, dynamic> json) => WorkspaceTask(
      id: json['id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      isComplete: json['isComplete'] as bool,
      isShared: json['isShared'] as bool,
      priority: json['priority'] as String,
      dueAt: json['dueAt'] == null
          ? null
          : DateTime.parse(json['dueAt'] as String).toLocal(),
      createdByMe: json['createdByMe'] as bool);

  Map<String, dynamic> toValues() => {
        'title': title,
        'notes': notes,
        'isComplete': isComplete,
        'isShared': isShared,
        'priority': priority,
        'dueAt': dueAt?.toUtc().toIso8601String(),
      };
}

class WorkspaceEvent {
  const WorkspaceEvent(
      {required this.id,
      required this.title,
      this.notes,
      this.location,
      required this.startsAt,
      required this.endsAt,
      required this.isShared,
      required this.createdByMe});

  final String id;
  final String title;
  final String? notes;
  final String? location;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isShared;
  final bool createdByMe;

  factory WorkspaceEvent.fromJson(Map<String, dynamic> json) => WorkspaceEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      location: json['location'] as String?,
      startsAt: DateTime.parse(json['startsAt'] as String).toLocal(),
      endsAt: DateTime.parse(json['endsAt'] as String).toLocal(),
      isShared: json['isShared'] as bool,
      createdByMe: json['createdByMe'] as bool);
}

class WorkspaceApi {
  WorkspaceApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _baseUrl = baseUrl ??
            const String.fromEnvironment('API_BASE_URL',
                defaultValue: 'http://10.0.2.2:5248/api/v1');

  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;

  Future<List<WorkspaceTask>> tasks(String token) async =>
      ((await _request('GET', '/tasks', token)) as List<dynamic>)
          .map((item) => WorkspaceTask.fromJson(item as Map<String, dynamic>))
          .toList();

  Future<List<WorkspaceEvent>> events(String token) async =>
      ((await _request('GET', '/events', token)) as List<dynamic>)
          .map((item) => WorkspaceEvent.fromJson(item as Map<String, dynamic>))
          .toList();

  Future<WorkspaceTask> saveTask(String token, Map<String, dynamic> values,
          {String? id}) async =>
      WorkspaceTask.fromJson(await _request(
          id == null ? 'POST' : 'PUT',
          id == null ? '/tasks' : '/tasks/${Uri.encodeComponent(id)}',
          token,
          values) as Map<String, dynamic>);

  Future<WorkspaceEvent> saveEvent(String token, Map<String, dynamic> values,
          {String? id}) async =>
      WorkspaceEvent.fromJson(await _request(
          id == null ? 'POST' : 'PUT',
          id == null ? '/events' : '/events/${Uri.encodeComponent(id)}',
          token,
          values) as Map<String, dynamic>);

  Future<void> removeTask(String token, String id) async {
    await _request('DELETE', '/tasks/${Uri.encodeComponent(id)}', token);
  }

  Future<void> removeEvent(String token, String id) async {
    await _request('DELETE', '/events/${Uri.encodeComponent(id)}', token);
  }

  Future<dynamic> _request(String method, String path, String token,
      [Map<String, dynamic>? values]) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'));
    request.headers.addAll(
        {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'});
    if (values != null) request.body = jsonEncode(values);
    final response = await (() async =>
            http.Response.fromStream(await _client.send(request)))()
        .timeout(const Duration(seconds: 20));
    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } on FormatException {
        data = null;
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Không thể lưu thay đổi. Vui lòng thử lại.';
      if (data is Map<String, dynamic>) {
        if (data['message'] is String) message = data['message'] as String;
        final errors = data['errors'];
        if (errors is Map &&
            errors.values.isNotEmpty &&
            errors.values.first is List &&
            (errors.values.first as List).isNotEmpty) {
          message = (errors.values.first as List).first.toString();
        }
      }
      if (response.statusCode == 401)
        message =
            'Phiên đăng nhập đã hết hạn. Hãy đăng xuất rồi đăng nhập lại.';
      if (response.statusCode == 404)
        message =
            'Nội dung không còn tồn tại hoặc bạn không có quyền truy cập. Hãy tải lại.';
      throw ApiException(message, statusCode: response.statusCode);
    }
    if (response.statusCode != 204 && data == null) {
      throw const ApiException(
          'Máy chủ trả về dữ liệu không hợp lệ. Vui lòng thử lại.');
    }
    return data;
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}

String workspaceErrorMessage(Object error) => error is ApiException
    ? error.message
    : 'Không thể kết nối máy chủ. Kiểm tra mạng rồi thử lại.';
