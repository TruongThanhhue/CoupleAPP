import 'package:couple_app/core/routing/main_shell.dart';
import 'package:couple_app/core/theme/app_tokens.dart';
import 'package:couple_app/features/auth/data/auth_api.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final SessionController _session;

  @override
  void initState() {
    super.initState();
    _session = SessionController()..restore();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _session,
        builder: (context, _) {
          if (_session.loading)
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          if (_session.error != null) {
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.x5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_session.error!, textAlign: TextAlign.center),
                        const SizedBox(height: AppSpace.x4),
                        FilledButton(
                            onPressed: _session.restore,
                            child: const Text('Thử lại')),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          return _session.user == null
              ? AuthScreen(session: _session)
              : MainShell(session: _session);
        },
      );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({required this.session, super.key});
  final SessionController session;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (_registering) {
        await widget.session.register(_name.text, _email.text, _password.text);
      } else {
        await widget.session.login(_email.text, _password.text);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted)
        setState(() =>
            _error = 'Không thể kết nối máy chủ. Kiểm tra mạng rồi thử lại.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpace.x5),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Chuyện của hai mình',
                            style: Theme.of(context).textTheme.displaySmall),
                        const SizedBox(height: AppSpace.x2),
                        Text(
                            'Tạo không gian riêng tư để cùng nhau lưu giữ và sắp xếp cuộc sống.',
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: AppSpace.x8),
                        if (_registering) ...[
                          TextFormField(
                              controller: _name,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                  labelText: 'Tên hiển thị'),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Hãy nhập tên của bạn.'
                                      : null),
                          const SizedBox(height: AppSpace.x3),
                        ],
                        TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                            validator: (value) =>
                                value == null || !value.contains('@')
                                    ? 'Email chưa hợp lệ.'
                                    : null),
                        const SizedBox(height: AppSpace.x3),
                        TextFormField(
                            controller: _password,
                            obscureText: true,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: const InputDecoration(
                                labelText: 'Mật khẩu',
                                helperText: 'Ít nhất 12 ký tự'),
                            validator: (value) =>
                                value == null || value.length < 12
                                    ? 'Mật khẩu cần tối thiểu 12 ký tự.'
                                    : null),
                        if (_error != null)
                          Padding(
                              padding: const EdgeInsets.only(top: AppSpace.x3),
                              child: Text(_error!,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error))),
                        const SizedBox(height: AppSpace.x5),
                        FilledButton(
                            onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Text(_registering
                                    ? 'Tạo tài khoản'
                                    : 'Đăng nhập')),
                        TextButton(
                            onPressed: _submitting
                                ? null
                                : () => setState(() {
                                      _registering = !_registering;
                                      _error = null;
                                    }),
                            child: Text(_registering
                                ? 'Đã có tài khoản? Đăng nhập'
                                : 'Chưa có tài khoản? Đăng ký')),
                      ]),
                ),
              ),
            ),
          ),
        ),
      );
}
