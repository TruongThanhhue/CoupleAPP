import 'package:couple_app/core/theme/app_tokens.dart';
import 'package:couple_app/core/widgets/app_state_panel.dart';
import 'package:couple_app/core/widgets/app_surface_card.dart';
import 'package:couple_app/features/workspace/application/workspace_controller.dart';
import 'package:couple_app/features/workspace/data/workspace_api.dart';
import 'package:couple_app/features/workspace/presentation/workspace_helpers.dart';
import 'package:flutter/material.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({required this.controller, super.key});
  final WorkspaceController controller;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _filter = 'all';

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(workspaceErrorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final disabled =
              controller.loading || controller.busy || controller.error != null;
          final tasks = controller.tasks
              .where((task) =>
                  _filter == 'all' ||
                  (_filter == 'done' ? task.isComplete : !task.isComplete))
              .toList();
          final completed =
              controller.tasks.where((task) => task.isComplete).length;
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.x5, AppSpace.x5, AppSpace.x5, AppSpace.x10),
              children: [
                Text('Việc cần làm',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpace.x1),
                Text(controller.loading
                    ? 'Đang tải dữ liệu…'
                    : controller.error != null
                        ? 'Chưa tải được dữ liệu'
                        : '$completed / ${controller.tasks.length} việc đã hoàn thành'),
                const SizedBox(height: AppSpace.x4),
                Wrap(spacing: AppSpace.x2, runSpacing: AppSpace.x2, children: [
                  FilledButton.icon(
                      onPressed: disabled
                          ? null
                          : () => showTaskEditor(context, controller),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm việc')),
                  OutlinedButton.icon(
                      onPressed: controller.busy || controller.loading
                          ? null
                          : controller.refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tải lại')),
                ]),
                const SizedBox(height: AppSpace.x3),
                Wrap(spacing: AppSpace.x2, runSpacing: AppSpace.x1, children: [
                  for (final entry in {
                    'all': 'Tất cả',
                    'open': 'Chưa xong',
                    'done': 'Đã xong'
                  }.entries)
                    ChoiceChip(
                        label: Text(entry.value),
                        selected: _filter == entry.key,
                        onSelected: (_) => setState(() => _filter = entry.key)),
                ]),
                const SizedBox(height: AppSpace.x4),
                if (controller.busy) const LinearProgressIndicator(),
                if (controller.loading)
                  const AppStatePanel(
                      kind: AppStateKind.loading,
                      title: 'Đang tải việc cần làm…')
                else if (controller.error != null)
                  AppStatePanel(
                      kind: AppStateKind.error,
                      title: 'Chưa tải được công việc',
                      message: controller.error,
                      actionLabel: 'Thử lại',
                      onAction: controller.refresh)
                else if (tasks.isEmpty)
                  AppStatePanel(
                      kind: AppStateKind.empty,
                      title: _filter == 'all'
                          ? 'Chưa có việc nào'
                          : 'Chưa có việc trong bộ lọc này',
                      message:
                          'Thêm việc cho bản thân hoặc chia sẻ cùng partner.')
                else
                  ...tasks.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.x3),
                        child: AppSurfaceCard(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Semantics(
                                        label: 'Hoàn thành ${task.title}',
                                        child: Checkbox(
                                            value: task.isComplete,
                                            onChanged: disabled
                                                ? null
                                                : (_) => _run(
                                                    () => controller
                                                        .toggleTask(task),
                                                    task.isComplete
                                                        ? 'Đã chuyển sang chưa hoàn thành.'
                                                        : 'Đã hoàn thành công việc.'))),
                                    const SizedBox(width: AppSpace.x1),
                                    Expanded(
                                        child: Padding(
                                            padding: const EdgeInsets.only(
                                                top: AppSpace.x3),
                                            child: Text(task.title,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                        decoration:
                                                            task.isComplete
                                                                ? TextDecoration
                                                                    .lineThrough
                                                                : null)))),
                                  ]),
                              const SizedBox(height: AppSpace.x2),
                              Text(
                                  '${task.isShared ? 'Chia sẻ với partner' : 'Chỉ mình tôi'} · Ưu tiên ${_priorityLabel(task.priority)}'),
                              if (task.dueAt != null)
                                Text(
                                    'Hạn: ${workspaceTimeLabel(task.dueAt!)}${!task.isComplete && task.dueAt!.isBefore(DateTime.now()) ? ' · Quá hạn' : ''}'),
                              if (task.notes?.isNotEmpty == true)
                                Padding(
                                    padding:
                                        const EdgeInsets.only(top: AppSpace.x2),
                                    child: Text(task.notes!)),
                              const SizedBox(height: AppSpace.x2),
                              Wrap(spacing: AppSpace.x2, children: [
                                TextButton.icon(
                                    onPressed: disabled
                                        ? null
                                        : () => showTaskEditor(
                                            context, controller, task),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Sửa')),
                                TextButton.icon(
                                    onPressed: disabled
                                        ? null
                                        : () async {
                                            final confirmed =
                                                await confirmWorkspaceDelete(
                                                    context, task.title,
                                                    shared: task.isShared);
                                            if (confirmed && mounted)
                                              await _run(
                                                  () => controller
                                                      .removeTask(task.id),
                                                  'Đã xóa công việc.');
                                          },
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Xóa')),
                              ]),
                            ])),
                      )),
              ],
            ),
          );
        },
      );
}

String _priorityLabel(String value) =>
    switch (value) { 'high' => 'cao', 'low' => 'thấp', _ => 'bình thường' };

Future<void> showTaskEditor(
    BuildContext context, WorkspaceController controller,
    [WorkspaceTask? task]) async {
  final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TaskEditor(controller: controller, task: task));
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(task == null ? 'Đã tạo công việc.' : 'Đã lưu công việc.')));
  }
}

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({required this.controller, this.task});
  final WorkspaceController controller;
  final WorkspaceTask? task;
  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.task?.title);
  late final TextEditingController _notes =
      TextEditingController(text: widget.task?.notes);
  late bool _shared = widget.task?.isShared ?? false;
  late String _priority = widget.task?.priority ?? 'normal';
  late DateTime? _dueAt = widget.task?.dueAt;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.controller.saveTask(id: widget.task?.id, values: {
        'title': _title.text.trim(),
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        'isComplete': widget.task?.isComplete ?? false,
        'isShared': _shared,
        'priority': _priority,
        'dueAt': _dueAt?.toUtc().toIso8601String(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted)
        setState(() {
          _saving = false;
          _error = workspaceErrorMessage(error);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.task?.createdByMe ?? true;
    final hasPartner = widget.controller.session.user?.partner != null;
    return PopScope(
        canPop: !_saving,
        child: AlertDialog(
          scrollable: true,
          title: Text(widget.task == null ? 'Thêm việc' : 'Sửa công việc'),
          content: Form(
              key: _form,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                        controller: _title,
                        enabled: !_saving,
                        autofocus: true,
                        maxLength: 200,
                        textCapitalization: TextCapitalization.sentences,
                        decoration:
                            const InputDecoration(labelText: 'Tên công việc'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Hãy nhập tên công việc.'
                                : null),
                    const SizedBox(height: AppSpace.x2),
                    TextFormField(
                        controller: _notes,
                        enabled: !_saving,
                        minLines: 2,
                        maxLines: 5,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                            labelText: 'Ghi chú (không bắt buộc)')),
                    const SizedBox(height: AppSpace.x2),
                    DropdownButtonFormField<String>(
                        initialValue: _priority,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(labelText: 'Mức ưu tiên'),
                        items: ['low', 'normal', 'high']
                            .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(_priorityLabel(value))))
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _priority = value!)),
                    const SizedBox(height: AppSpace.x3),
                    OutlinedButton.icon(
                        onPressed: _saving
                            ? null
                            : () async {
                                final chosen = await pickWorkspaceDateTime(
                                    context,
                                    _dueAt ??
                                        DateTime.now()
                                            .add(const Duration(hours: 1)));
                                if (chosen != null && mounted)
                                  setState(() => _dueAt = chosen);
                              },
                        icon: const Icon(Icons.event_outlined),
                        label: Text(_dueAt == null
                            ? 'Chọn hạn hoàn thành'
                            : workspaceTimeLabel(_dueAt!))),
                    if (_dueAt != null)
                      TextButton(
                          onPressed: _saving
                              ? null
                              : () => setState(() => _dueAt = null),
                          child: const Text('Bỏ thời hạn')),
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Chia sẻ với partner'),
                        subtitle: Text(!isOwner
                            ? 'Chỉ người tạo có thể thay đổi chia sẻ.'
                            : !hasPartner
                                ? 'Kết nối partner để chia sẻ.'
                                : 'Cả hai có thể xem, sửa và xóa việc này.'),
                        value: _shared,
                        onChanged:
                            _saving || !isOwner || (!hasPartner && !_shared)
                                ? null
                                : (value) => setState(() => _shared = value)),
                    if (_error != null)
                      Text(_error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                  ])),
          actions: [
            TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context, false),
                child: const Text('Hủy')),
            FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Đang lưu…' : 'Lưu')),
          ],
        ));
  }
}
