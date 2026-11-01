import 'package:couple_app/core/theme/app_tokens.dart';
import 'package:couple_app/core/widgets/app_surface_card.dart';
import 'package:couple_app/features/auth/data/auth_api.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.session, super.key});
  final SessionController session;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _sessionToken;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.session.user?.displayName);
    _sessionToken = widget.session.token;
    widget.session.addListener(_sessionChanged);
    _load();
  }

  @override
  void dispose() {
    widget.session.removeListener(_sessionChanged);
    _name.dispose();
    super.dispose();
  }

  void _sessionChanged() {
    if (!mounted || _sessionToken == widget.session.token) return;
    setState(() {
      _sessionToken = widget.session.token;
      _name.text = widget.session.user?.displayName ?? '';
      _saving = false;
      _loading = false;
      _error = _sessionToken == null ? 'Hãy đăng nhập lại để tiếp tục.' : null;
    });
  }

  Future<void> _load() async {
    final token = widget.session.token;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.session.refreshProfile();
      if (!mounted || widget.session.token != token) return;
      _name.text = widget.session.user?.displayName ?? '';
    } catch (error) {
      if (mounted && widget.session.token == token) _error = _message(error);
    } finally {
      if (mounted && widget.session.token == token)
        setState(() => _loading = false);
    }
  }

  String _message(Object error) => error is ApiException
      ? error.message
      : 'Không thể kết nối máy chủ. Vui lòng thử lại.';

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final token = widget.session.token;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.session.updateProfile(_name.text.trim());
      if (!mounted || widget.session.token != token) return;
      _name.text = widget.session.user?.displayName ?? _name.text.trim();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã cập nhật hồ sơ.')));
    } catch (error) {
      if (mounted && widget.session.token == token) _error = _message(error);
    } finally {
      if (mounted && widget.session.token == token)
        setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: Scaffold(
          appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
          body: ListenableBuilder(
              listenable: widget.session,
              builder: (context, _) => ListView(
                    padding: const EdgeInsets.all(AppSpace.x5),
                    children: [
                      AppSurfaceCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Mã cá nhân',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: AppSpace.x2),
                            SelectableText(
                                widget.session.user?.partnerCode ?? '—',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: AppSpace.x2),
                            const Text(
                                'Mã này dùng để gửi lời mời kết nối và không thay đổi khi bạn sửa tên.'),
                          ])),
                      const SizedBox(height: AppSpace.x6),
                      if (_loading) const LinearProgressIndicator(),
                      Form(
                          key: _form,
                          child: TextFormField(
                            controller: _name,
                            enabled: !_loading &&
                                !_saving &&
                                widget.session.user != null,
                            maxLength: 80,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                                labelText: 'Tên hiển thị'),
                            validator: (value) {
                              final name = value?.trim() ?? '';
                              return name.isEmpty || name.length > 80
                                  ? 'Tên hiển thị cần từ 1 đến 80 ký tự.'
                                  : null;
                            },
                            onFieldSubmitted: (_) {
                              if (!_loading && !_saving) _save();
                            },
                          )),
                      const SizedBox(height: AppSpace.x3),
                      if (_error != null) ...[
                        Semantics(
                            liveRegion: true,
                            child: Text(_error!,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error))),
                        TextButton(
                            onPressed: _loading || _saving ? null : _load,
                            child: const Text('Tải lại hồ sơ')),
                      ],
                      FilledButton.icon(
                        onPressed:
                            _loading || _saving || widget.session.user == null
                                ? null
                                : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'Đang lưu…' : 'Lưu thay đổi'),
                      ),
                    ],
                  )),
        ),
      );
}
