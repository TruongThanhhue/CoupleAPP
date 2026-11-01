import 'package:couple_app/core/theme/app_tokens.dart';
import 'package:couple_app/features/auth/data/auth_api.dart';
import 'package:couple_app/features/auth/presentation/profile_screen.dart';
import 'package:couple_app/features/couple/presentation/partner_connection_screen.dart';
import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({required this.session, super.key});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: session,
        builder: (context, _) => ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.x5, AppSpace.x5, AppSpace.x5, AppSpace.x10),
              children: [
                Text('Thêm', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpace.x4),
                _MoreItem(
                  Icons.person_outline,
                  'Hồ sơ cá nhân',
                  session.user?.displayName ?? 'Cập nhật tên và xem mã cá nhân',
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => ProfileScreen(session: session))),
                ),
                const _MoreItem(Icons.water_drop_outlined, 'Chu kỳ',
                    'Riêng tư, chỉ chia sẻ khi bạn cho phép'),
                const _MoreItem(Icons.photo_library_outlined, 'Kỷ niệm',
                    'Những điều đáng nhớ của cả hai'),
                const _MoreItem(Icons.payments_outlined, 'Chi tiêu',
                    'Chi chung minh bạch, dễ hiểu'),
                const _MoreItem(Icons.shopping_bag_outlined,
                    'Danh sách mua sắm', 'Cùng cập nhật khi cần'),
                const _MoreItem(Icons.favorite_border, 'Mốc kỷ niệm',
                    'Đếm ngược những ngày quan trọng'),
                _MoreItem(
                  Icons.people_outline,
                  'Kết nối partner',
                  'Chia sẻ mã cá nhân và quản lý lời mời một cách riêng tư',
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => PartnerConnectionScreen(session: session),
                  )),
                ),
                const _MoreItem(
                    Icons.settings_outlined,
                    'Cài đặt & quyền riêng tư',
                    'Bạn luôn kiểm soát dữ liệu của mình'),
                const SizedBox(height: AppSpace.x4),
                Text('Đang đăng nhập: ${session.user?.displayName ?? 'Bạn'}',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpace.x2),
                OutlinedButton.icon(
                  onPressed: session.signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                ),
              ],
            ));
  }
}

class _MoreItem extends StatelessWidget {
  const _MoreItem(this.icon, this.title, this.subtitle, {this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpace.x1),
      minVerticalPadding: AppSpace.x2,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap ??
          () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('$title sẽ được triển khai theo lộ trình.')),
              ),
    );
  }
}
