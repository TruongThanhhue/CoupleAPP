import 'package:couple_app/features/auth/data/auth_api.dart';
import 'package:couple_app/features/workspace/data/workspace_api.dart';
import 'package:flutter/foundation.dart';

class WorkspaceController extends ChangeNotifier {
  WorkspaceController({required this.session, WorkspaceApi? api})
      : _api = api ?? WorkspaceApi() {
    _sessionToken = session.token;
    _partnerCode = session.user?.partner?.partnerCode;
    session.addListener(_sessionChanged);
  }

  final SessionController session;
  final WorkspaceApi _api;
  List<WorkspaceTask> _tasks = [];
  List<WorkspaceEvent> _events = [];
  bool loading = false;
  bool busy = false;
  String? error;
  bool _disposed = false;
  int _revision = 0;
  String? _sessionToken;
  String? _partnerCode;

  List<WorkspaceTask> get tasks => List.unmodifiable(_tasks);
  List<WorkspaceEvent> get events => List.unmodifiable(_events);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _sessionChanged() {
    if (_sessionToken == session.token &&
        _partnerCode == session.user?.partner?.partnerCode) return;
    _sessionToken = session.token;
    _partnerCode = session.user?.partner?.partnerCode;
    _revision++;
    _tasks = [];
    _events = [];
    error = null;
    loading = false;
    busy = false;
    _notify();
    if (session.token != null) refresh();
  }

  Future<void> refresh() async {
    if (busy || _disposed) return;
    final token = session.token;
    final revision = ++_revision;
    if (token == null) {
      _tasks = [];
      _events = [];
      error = 'Hãy đăng nhập để xem dữ liệu.';
      loading = false;
      _notify();
      return;
    }
    loading = true;
    error = null;
    _notify();
    try {
      final results =
          await Future.wait([_api.tasks(token), _api.events(token)]);
      if (_disposed || revision != _revision) return;
      _tasks = results[0].cast<WorkspaceTask>();
      _events = results[1].cast<WorkspaceEvent>();
      _sort();
    } catch (failure) {
      if (_disposed || revision != _revision) return;
      _tasks = [];
      _events = [];
      error = workspaceErrorMessage(failure);
    } finally {
      if (!_disposed && revision == _revision) {
        loading = false;
        _notify();
      }
    }
  }

  Future<void> saveTask({String? id, required Map<String, dynamic> values}) =>
      _mutate((token) async {
        final saved = await _api.saveTask(token, values, id: id);
        return () {
          _tasks.removeWhere((task) => task.id == saved.id);
          _tasks.add(saved);
        };
      });

  Future<void> saveEvent({String? id, required Map<String, dynamic> values}) =>
      _mutate((token) async {
        final saved = await _api.saveEvent(token, values, id: id);
        return () {
          _events.removeWhere((event) => event.id == saved.id);
          _events.add(saved);
        };
      });

  Future<void> toggleTask(WorkspaceTask task) => saveTask(
      id: task.id,
      values: {...task.toValues(), 'isComplete': !task.isComplete});

  Future<void> removeTask(String id) => _mutate((token) async {
        await _api.removeTask(token, id);
        return () => _tasks.removeWhere((task) => task.id == id);
      });

  Future<void> removeEvent(String id) => _mutate((token) async {
        await _api.removeEvent(token, id);
        return () => _events.removeWhere((event) => event.id == id);
      });

  Future<void> _mutate(
      Future<VoidCallback> Function(String token) operation) async {
    if (_disposed || busy || loading)
      throw const ApiException('Đang xử lý dữ liệu. Vui lòng chờ.');
    if (error != null)
      throw const ApiException('Hãy tải lại dữ liệu trước khi thay đổi.');
    final token = session.token;
    if (token == null)
      throw const ApiException('Hãy đăng nhập lại để tiếp tục.',
          statusCode: 401);
    final revision = ++_revision;
    busy = true;
    _notify();
    try {
      final apply = await operation(token);
      if (_disposed || revision != _revision)
        throw const ApiException('Phiên làm việc đã thay đổi. Hãy tải lại.');
      apply();
      error = null;
      _sort();
    } finally {
      if (!_disposed && revision == _revision) {
        busy = false;
        _notify();
      }
    }
  }

  void _sort() {
    _tasks.sort((a, b) {
      final completed = (a.isComplete ? 1 : 0).compareTo(b.isComplete ? 1 : 0);
      if (completed != 0) return completed;
      if (a.dueAt == null && b.dueAt == null) return a.title.compareTo(b.title);
      if (a.dueAt == null) return 1;
      if (b.dueAt == null) return -1;
      return a.dueAt!.compareTo(b.dueAt!);
    });
    _events.sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    session.removeListener(_sessionChanged);
    _api.dispose();
    super.dispose();
  }
}
