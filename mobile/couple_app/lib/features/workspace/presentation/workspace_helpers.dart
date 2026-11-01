import 'package:flutter/material.dart';

String workspaceDateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String workspaceTimeLabel(DateTime date) =>
    '${workspaceDateLabel(date)} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

Future<DateTime?> pickWorkspaceDateTime(
    BuildContext context, DateTime initial) async {
  final first = DateTime(2000);
  final last = DateTime(2100, 12, 31);
  final bounded = initial.isBefore(first)
      ? first
      : initial.isAfter(last)
          ? last
          : initial;
  final date = await showDatePicker(
      context: context,
      initialDate: bounded,
      firstDate: first,
      lastDate: last,
      helpText: 'Chọn ngày',
      cancelText: 'Hủy',
      confirmText: 'Tiếp tục');
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Chọn giờ',
      cancelText: 'Hủy',
      confirmText: 'Chọn');
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

Future<bool> confirmWorkspaceDelete(BuildContext context, String title,
        {required bool shared}) async =>
    await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              scrollable: true,
              title: const Text('Xóa nội dung này?'),
              content: Text(
                  '“$title” sẽ bị xóa.${shared ? ' Partner cũng sẽ không còn thấy nội dung này.' : ''}'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Giữ lại')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Xóa')),
              ],
            )) ??
    false;
