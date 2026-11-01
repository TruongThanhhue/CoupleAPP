import 'package:couple_app/core/theme/app_tokens.dart';
import 'package:couple_app/core/widgets/app_state_panel.dart';
import 'package:flutter/material.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.x5, AppSpace.x5, AppSpace.x5, AppSpace.x10),
      children: [
        Text('Vị trí', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpace.x1),
        const Text('Chỉ chia sẻ khi bạn chủ động chọn bật.'),
        const SizedBox(height: AppSpace.x8),
        AppStatePanel(
          kind: AppStateKind.permission,
          title: 'Chia sẻ vị trí đang tắt',
          message:
              'Partner không thể xem vị trí của bạn. Bạn có thể chọn chia sẻ lần cuối hoặc theo thời gian giới hạn.',
          actionLabel: 'Xem quyền riêng tư',
          onAction: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Cài đặt vị trí sẽ có ở Phase Location.')),
          ),
        ),
      ],
    );
  }
}
