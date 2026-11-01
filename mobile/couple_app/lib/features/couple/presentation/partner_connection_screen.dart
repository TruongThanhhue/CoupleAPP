import 'package:couple_app/core/theme/app_tokens.dart';
import 'package:couple_app/core/widgets/app_surface_card.dart';
import 'package:couple_app/features/auth/data/auth_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PartnerConnectionScreen extends StatefulWidget {
  const PartnerConnectionScreen({required this.session, super.key});
  final SessionController session;

  @override
  State<PartnerConnectionScreen> createState() =>
      _PartnerConnectionScreenState();
}

class _PartnerConnectionScreenState extends State<PartnerConnectionScreen> {
  final _code = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  String? _error;
  List<PartnerInvite> _invites = const [];
  List<SentPartnerInvite> _sentInvites = const [];
  int _loadVersion = 0;
  String? _sessionToken;
  String? _partnerCode;

  @override
  void initState() {
    super.initState();
    _sessionToken = widget.session.token;
    _partnerCode = widget.session.user?.partner?.partnerCode;
    widget.session.addListener(_sessionChanged);
    _load();
  }

  @override
  void dispose() {
    _loadVersion++;
    widget.session.removeListener(_sessionChanged);
    _code.dispose();
    super.dispose();
  }

  void _sessionChanged() {
    if (!mounted) return;
    final token = widget.session.token;
    final partnerCode = widget.session.user?.partner?.partnerCode;
    setState(() {
      if (token != _sessionToken) {
        _loadVersion++;
        _loading = false;
        _invites = const [];
        _sentInvites = const [];
        _code.clear();
      }
      if (partnerCode != _partnerCode) {
        _invites = const [];
        _sentInvites = const [];
      }
      _sessionToken = token;
      _partnerCode = partnerCode;
    });
  }

  Future<void> _load() async {
    final token = widget.session.token;
    if (token == null) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Hãy đăng nhập lại để tiếp tục.';
        });
      return;
    }
    final version = ++_loadVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.session.refreshProfile();
      if (!mounted || version != _loadVersion || widget.session.token != token)
        return;
      final invites = await widget.session.api.invites(token);
      final sentInvites = await widget.session.api.sentInvites(token);
      if (!mounted || version != _loadVersion || widget.session.token != token)
        return;
      _invites = invites;
      _sentInvites = sentInvites;
    } on ApiException catch (error) {
      if (mounted && version == _loadVersion) _error = error.message;
    } catch (_) {
      if (mounted && version == _loadVersion)
        _error = 'Không thể kết nối máy chủ. Kiểm tra mạng rồi thử lại.';
    } finally {
      if (mounted && version == _loadVersion) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final token = widget.session.token;
    if (_sending || token == null || _code.text.trim().isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.session.api
          .sendInvite(token, _code.text.trim().toUpperCase());
      if (!mounted || widget.session.token != token) return;
      _code.clear();
      if (mounted) await _load();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã gửi lời mời kết nối.')));
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted)
        setState(() =>
            _error = 'Không thể kết nối máy chủ. Kiểm tra mạng rồi thử lại.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _respond(PartnerInvite invite, bool accept) async {
    final token = widget.session.token;
    if (_sending || token == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      if (accept) {
        await widget.session.api.acceptInvite(token, invite.id);
      } else {
        await widget.session.api.declineInvite(token, invite.id);
      }
      if (mounted) await _load();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted)
        setState(() =>
            _error = 'Không thể kết nối máy chủ. Kiểm tra mạng rồi thử lại.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _cancel(SentPartnerInvite invite) async {
    final token = widget.session.token;
    if (_sending || token == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.session.api.cancelInvite(token, invite.id);
      if (mounted) await _load();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted)
        setState(() =>
            _error = 'Không thể kết nối máy chủ. Kiểm tra mạng rồi thử lại.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _disconnect() async {
    if (_sending || _loading) return;
    final partner = widget.session.user?.partner;
    final token = widget.session.token;
    if (partner == null || token == null) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              scrollable: true,
              title: const Text('Ngắt kết nối partner?'),
              content: Text('Bạn sẽ ngắt kết nối với ${partner.displayName}. '
                  'Mỗi người giữ các công việc và sự kiện do mình tạo; những mục từng chia sẻ sẽ trở về riêng tư. '
                  'Kết nối lại sẽ không tự khôi phục chia sẻ cũ.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Giữ kết nối')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Xác nhận ngắt kết nối')),
              ],
            ));
    if (confirmed != true ||
        !mounted ||
        _sending ||
        widget.session.token != token) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.session.disconnectPartner(partner.partnerCode);
      if (!mounted || widget.session.token != token) return;
      _invites = const [];
      _sentInvites = const [];
      _code.clear();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã ngắt kết nối partner.')));
      await _load();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Không thể ngắt kết nối. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.user;
    return PopScope(
        canPop: !_sending,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Kết nối partner'),
            actions: [
              IconButton(
                onPressed: _loading || _sending ? null : _load,
                tooltip: 'Làm mới lời mời',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpace.x5, AppSpace.x4, AppSpace.x5, AppSpace.x10),
                  children: [
                    Text('Mã của bạn',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpace.x2),
                    Text(
                        'Chỉ gửi mã này cho người bạn muốn kết nối. Họ vẫn phải xác nhận lời mời.',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: AppSpace.x3),
                    AppSurfaceCard(
                      child: Row(children: [
                        Expanded(
                            child: SelectableText(user?.partnerCode ?? '—',
                                style:
                                    Theme.of(context).textTheme.headlineSmall)),
                        IconButton(
                          tooltip: 'Sao chép mã',
                          onPressed: user == null
                              ? null
                              : () async {
                                  await Clipboard.setData(
                                      ClipboardData(text: user.partnerCode));
                                  if (context.mounted)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Đã sao chép mã.')));
                                },
                          icon: const Icon(Icons.copy_outlined),
                        ),
                      ]),
                    ),
                    const SizedBox(height: AppSpace.x6),
                    if (user?.partner != null)
                      AppSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.favorite_outline,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: AppSpace.x2),
                            Text('Đã kết nối với ${user!.partner!.displayName}',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: AppSpace.x2),
                            const Text(
                                'Hai bạn đã xác nhận kết nối. Các quyền chia sẻ dữ liệu vẫn do từng người kiểm soát.'),
                            const SizedBox(height: AppSpace.x3),
                            OutlinedButton.icon(
                              onPressed: _sending ? null : _disconnect,
                              icon: const Icon(Icons.link_off),
                              label: Text(
                                  _sending ? 'Đang xử lý…' : 'Ngắt kết nối'),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Text('Nhập mã partner',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpace.x2),
                      Text(
                          'Nhập mã mà partner chia sẻ để gửi lời mời. Bạn không thể tự kết nối bằng mã của mình.',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: AppSpace.x3),
                      TextField(
                        controller: _code,
                        enabled: !_sending,
                        autocorrect: false,
                        maxLength: 12,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                            labelText: 'Ví dụ: CPL-7KQ9M2AB'),
                      ),
                      const SizedBox(height: AppSpace.x3),
                      FilledButton.icon(
                          onPressed: _sending ? null : _send,
                          icon: const Icon(Icons.send_outlined),
                          label: const Text('Gửi lời mời')),
                    ],
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpace.x4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_error!,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error)),
                            TextButton(
                                onPressed: _sending ? null : _load,
                                child: const Text('Thử lại')),
                          ],
                        ),
                      ),
                    if (_sentInvites.isNotEmpty && user?.partner == null) ...[
                      const SizedBox(height: AppSpace.x8),
                      Text('Lời mời đã gửi',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpace.x2),
                      for (final invite in _sentInvites)
                        Card(
                          child: ListTile(
                            title: Text(invite.toDisplayName),
                            subtitle: const Text('Đang chờ xác nhận'),
                            trailing: TextButton(
                              onPressed:
                                  _sending ? null : () => _cancel(invite),
                              child: const Text('Hủy'),
                            ),
                          ),
                        ),
                    ],
                    if (_invites.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.x8),
                      Text('Lời mời đang chờ',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpace.x2),
                      for (final invite in _invites)
                        Card(
                            child: Padding(
                                padding: const EdgeInsets.all(AppSpace.x4),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${invite.fromDisplayName} muốn kết nối với bạn.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      const SizedBox(height: AppSpace.x3),
                                      Wrap(spacing: AppSpace.x2, children: [
                                        TextButton(
                                            onPressed: _sending
                                                ? null
                                                : () => _respond(invite, false),
                                            child: const Text('Từ chối')),
                                        FilledButton(
                                            onPressed: _sending
                                                ? null
                                                : () => _respond(invite, true),
                                            child: const Text('Chấp nhận')),
                                      ]),
                                    ]))),
                    ],
                  ],
                ),
        ));
  }
}
