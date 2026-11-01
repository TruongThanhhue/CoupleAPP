import 'package:couple_app/core/theme/app_tokens.dart';
import 'package:couple_app/core/widgets/app_section_header.dart';
import 'package:couple_app/core/widgets/app_state_panel.dart';
import 'package:couple_app/core/widgets/app_surface_card.dart';
import 'package:couple_app/features/calendar/presentation/calendar_screen.dart';
import 'package:couple_app/features/tasks/presentation/tasks_screen.dart';
import 'package:couple_app/features/workspace/application/workspace_controller.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen(
      {required this.controller, required this.onSelectTab, super.key});

  final WorkspaceController controller;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([controller, controller.session]),
        builder: (context, _) {
          final user = controller.session.user;
          final partner = user?.partner;
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, now.day);
          final end = DateTime(now.year, now.month, now.day + 1);
          final todayEvents = controller.events
              .where((event) =>
                  event.startsAt.isBefore(end) && event.endsAt.isAfter(start))
              .toList()
            ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
          final completed =
              controller.tasks.where((task) => task.isComplete).length;
          final textTheme = Theme.of(context).textTheme;
          final colors = Theme.of(context).colorScheme;
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.x5, AppSpace.x5, AppSpace.x5, AppSpace.x10),
              children: [
                AppSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          partner == null
                              ? 'Chào ${user?.displayName ?? 'bạn'}'
                              : '${user!.displayName} & ${partner.displayName}',
                          style: textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: AppSpace.x2),
                      Text(partner == null
                          ? 'Không gian của bạn. Kết nối partner để cùng lên kế hoạch.'
                          : 'Một nơi cho những kế hoạch của cả hai.'),
                      if (partner == null) ...[
                        const SizedBox(height: AppSpace.x3),
                        OutlinedButton.icon(
                          onPressed: () => onSelectTab(4),
                          icon: const Icon(Icons.person_add_alt_outlined),
                          label: const Text('Kết nối partner'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.x8),
                const AppSectionHeader(title: 'Không gian của bạn'),
                const SizedBox(height: AppSpace.x3),
                if (controller.loading)
                  const AppStatePanel(
                      kind: AppStateKind.loading, title: 'Đang tải kế hoạch')
                else if (controller.error != null)
                  AppStatePanel(
                    kind: AppStateKind.error,
                    title: 'Chưa tải được kế hoạch',
                    message: controller.error,
                    actionLabel: 'Thử lại',
                    onAction: controller.refresh,
                  )
                else ...[
                  AppSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '$completed / ${controller.tasks.length} việc đã hoàn thành',
                            style: textTheme.titleMedium),
                        const SizedBox(height: AppSpace.x2),
                        Text(controller.tasks.isEmpty
                            ? 'Chưa có việc nào. Thêm điều bạn muốn làm hôm nay.'
                            : 'Tổng số việc cá nhân và việc được chia sẻ với bạn.'),
                        TextButton(
                            onPressed: () => onSelectTab(2),
                            child: const Text('Xem việc cần làm')),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.x6),
                  const AppSectionHeader(title: 'Lịch hôm nay'),
                  const SizedBox(height: AppSpace.x3),
                  if (todayEvents.isEmpty)
                    const AppStatePanel(
                      kind: AppStateKind.empty,
                      title: 'Hôm nay chưa có sự kiện',
                      message:
                          'Bạn có thể thêm một kế hoạch bằng lối tắt bên dưới.',
                    )
                  else
                    ...todayEvents.take(3).map((event) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.x3),
                          child: AppSurfaceCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event.title, style: textTheme.titleMedium),
                                const SizedBox(height: AppSpace.x1),
                                Text(
                                    '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(event.startsAt))}'
                                    ' · ${event.isShared ? 'Chia sẻ với partner' : 'Chỉ mình bạn'}'),
                                if (event.location?.isNotEmpty ?? false)
                                  Text(event.location!),
                              ],
                            ),
                          ),
                        )),
                  TextButton(
                      onPressed: () => onSelectTab(1),
                      child: const Text('Xem toàn bộ lịch')),
                ],
                const SizedBox(height: AppSpace.x8),
                const AppSectionHeader(title: 'Lối tắt'),
                const SizedBox(height: AppSpace.x3),
                Wrap(
                  spacing: AppSpace.x2,
                  runSpacing: AppSpace.x2,
                  children: [
                    OutlinedButton.icon(
                      onPressed: controller.busy ||
                              controller.loading ||
                              controller.error != null
                          ? null
                          : () => showTaskEditor(context, controller),
                      icon: const Icon(Icons.add_task_outlined),
                      label: const Text('Thêm việc'),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.busy ||
                              controller.loading ||
                              controller.error != null
                          ? null
                          : () => showEventEditor(context, controller),
                      icon: const Icon(Icons.event_outlined),
                      label: const Text('Tạo lịch'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.x8),
                AppSurfaceCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline, color: colors.onSurfaceVariant),
                      const SizedBox(width: AppSpace.x3),
                      const Expanded(
                          child: Text(
                        'Việc và sự kiện mặc định là riêng tư. Bạn chủ động chọn chia sẻ từng mục với partner. Chia sẻ vị trí chưa khả dụng.',
                      )),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
}
