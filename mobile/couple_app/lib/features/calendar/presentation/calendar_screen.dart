import 'package:couple_app/core/theme/app_tokens.dart';
import 'package:couple_app/core/widgets/app_state_panel.dart';
import 'package:couple_app/core/widgets/app_surface_card.dart';
import 'package:couple_app/features/workspace/application/workspace_controller.dart';
import 'package:couple_app/features/workspace/data/workspace_api.dart';
import 'package:couple_app/features/workspace/presentation/workspace_helpers.dart';
import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({required this.controller, super.key});
  final WorkspaceController controller;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _upcomingOnly = true;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final disabled =
            controller.loading || controller.busy || controller.error != null;
        final events = controller.events
            .where((event) =>
                !_upcomingOnly || !event.endsAt.isBefore(DateTime.now()))
            .toList();
        return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.x5, AppSpace.x5, AppSpace.x5, AppSpace.x10),
              children: [
                Text('Lịch của chúng mình',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpace.x1),
                const Text('Sự kiện cá nhân và những cuộc hẹn đã chia sẻ.'),
                const SizedBox(height: AppSpace.x4),
                Wrap(spacing: AppSpace.x2, runSpacing: AppSpace.x2, children: [
                  FilledButton.icon(
                      onPressed: disabled
                          ? null
                          : () => showEventEditor(context, controller),
                      icon: const Icon(Icons.add),
                      label: const Text('Tạo sự kiện')),
                  OutlinedButton.icon(
                      onPressed: controller.loading || controller.busy
                          ? null
                          : controller.refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tải lại')),
                ]),
                const SizedBox(height: AppSpace.x3),
                Wrap(spacing: AppSpace.x2, runSpacing: AppSpace.x1, children: [
                  ChoiceChip(
                      label: const Text('Sắp tới'),
                      selected: _upcomingOnly,
                      onSelected: (_) => setState(() => _upcomingOnly = true)),
                  ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: !_upcomingOnly,
                      onSelected: (_) => setState(() => _upcomingOnly = false)),
                ]),
                const SizedBox(height: AppSpace.x4),
                if (controller.busy) const LinearProgressIndicator(),
                if (controller.loading)
                  const AppStatePanel(
                      kind: AppStateKind.loading, title: 'Đang tải lịch…')
                else if (controller.error != null)
                  AppStatePanel(
                      kind: AppStateKind.error,
                      title: 'Chưa tải được lịch',
                      message: controller.error,
                      actionLabel: 'Thử lại',
                      onAction: controller.refresh)
                else if (events.isEmpty)
                  AppStatePanel(
                      kind: AppStateKind.empty,
                      title: _upcomingOnly
                          ? 'Chưa có lịch nào sắp tới'
                          : 'Chưa có sự kiện nào',
                      message: 'Tạo một cuộc hẹn và chọn người có thể xem.')
                else
                  ...events.map((event) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.x3),
                        child: AppSurfaceCard(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(event.title,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: AppSpace.x2),
                              Text(
                                  'Bắt đầu: ${workspaceTimeLabel(event.startsAt)}'),
                              Text(
                                  'Kết thúc: ${workspaceTimeLabel(event.endsAt)}'),
                              if (event.location?.isNotEmpty == true)
                                Text('Địa điểm: ${event.location}'),
                              const SizedBox(height: AppSpace.x2),
                              Text(event.isShared
                                  ? 'Chia sẻ với partner'
                                  : 'Chỉ mình tôi'),
                              if (event.notes?.isNotEmpty == true)
                                Padding(
                                    padding:
                                        const EdgeInsets.only(top: AppSpace.x2),
                                    child: Text(event.notes!)),
                              const SizedBox(height: AppSpace.x2),
                              Wrap(spacing: AppSpace.x2, children: [
                                TextButton.icon(
                                    onPressed: disabled
                                        ? null
                                        : () => showEventEditor(
                                            context, controller, event),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Sửa')),
                                TextButton.icon(
                                    onPressed: disabled
                                        ? null
                                        : () async {
                                            final confirmed =
                                                await confirmWorkspaceDelete(
                                                    context, event.title,
                                                    shared: event.isShared);
                                            if (!confirmed || !context.mounted)
                                              return;
                                            try {
                                              await controller
                                                  .removeEvent(event.id);
                                              if (context.mounted)
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                        content: Text(
                                                            'Đã xóa sự kiện.')));
                                            } catch (error) {
                                              if (context.mounted)
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                            workspaceErrorMessage(
                                                                error))));
                                            }
                                          },
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Xóa')),
                              ]),
                            ])),
                      )),
              ],
            ));
      });
}

Future<void> showEventEditor(
    BuildContext context, WorkspaceController controller,
    [WorkspaceEvent? event]) async {
  final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EventEditor(controller: controller, event: event));
  if (saved == true && context.mounted)
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(event == null ? 'Đã tạo sự kiện.' : 'Đã lưu sự kiện.')));
}

class _EventEditor extends StatefulWidget {
  const _EventEditor({required this.controller, this.event});
  final WorkspaceController controller;
  final WorkspaceEvent? event;
  @override
  State<_EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<_EventEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.event?.title);
  late final TextEditingController _notes =
      TextEditingController(text: widget.event?.notes);
  late final TextEditingController _location =
      TextEditingController(text: widget.event?.location);
  late DateTime _start =
      widget.event?.startsAt ?? DateTime.now().add(const Duration(hours: 1));
  late DateTime _end =
      widget.event?.endsAt ?? _start.add(const Duration(hours: 1));
  late bool _shared = widget.event?.isShared ?? false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!_end.isAfter(_start)) {
      setState(() => _error = 'Giờ kết thúc phải sau giờ bắt đầu.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.controller.saveEvent(id: widget.event?.id, values: {
        'title': _title.text.trim(),
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        'location':
            _location.text.trim().isEmpty ? null : _location.text.trim(),
        'startsAt': _start.toUtc().toIso8601String(),
        'endsAt': _end.toUtc().toIso8601String(),
        'isShared': _shared,
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
    final isOwner = widget.event?.createdByMe ?? true;
    final hasPartner = widget.controller.session.user?.partner != null;
    return PopScope(
        canPop: !_saving,
        child: AlertDialog(
          scrollable: true,
          title: Text(widget.event == null ? 'Tạo sự kiện' : 'Sửa sự kiện'),
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
                            const InputDecoration(labelText: 'Tên sự kiện'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Hãy nhập tên sự kiện.'
                                : null),
                    const SizedBox(height: AppSpace.x2),
                    TextFormField(
                        controller: _location,
                        enabled: !_saving,
                        maxLength: 300,
                        decoration: const InputDecoration(
                            labelText: 'Địa điểm (không bắt buộc)')),
                    const SizedBox(height: AppSpace.x2),
                    OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () async {
                                final chosen = await pickWorkspaceDateTime(
                                    context, _start);
                                if (chosen != null && mounted)
                                  setState(() {
                                    final duration = _end.difference(_start);
                                    _start = chosen;
                                    _end = chosen.add(duration.isNegative
                                        ? const Duration(hours: 1)
                                        : duration);
                                  });
                              },
                        child: Text('Bắt đầu: ${workspaceTimeLabel(_start)}')),
                    const SizedBox(height: AppSpace.x2),
                    OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () async {
                                final chosen =
                                    await pickWorkspaceDateTime(context, _end);
                                if (chosen != null && mounted)
                                  setState(() => _end = chosen);
                              },
                        child: Text('Kết thúc: ${workspaceTimeLabel(_end)}')),
                    const SizedBox(height: AppSpace.x2),
                    TextFormField(
                        controller: _notes,
                        enabled: !_saving,
                        minLines: 2,
                        maxLines: 5,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                            labelText: 'Ghi chú (không bắt buộc)')),
                    SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _shared,
                        title: const Text('Chia sẻ với partner'),
                        subtitle: Text(!isOwner
                            ? 'Chỉ người tạo có thể thay đổi chia sẻ.'
                            : !hasPartner
                                ? 'Kết nối partner để chia sẻ.'
                                : 'Cả hai có thể xem, sửa và xóa sự kiện.'),
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
