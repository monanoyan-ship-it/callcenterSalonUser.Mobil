import 'package:callcenter_salonuser_mobil/screens/forgot_password_page.dart';
import 'package:callcenter_salonuser_mobil/services/salon_api.dart';
import 'package:callcenter_salonuser_mobil/state/session_state.dart';
import 'package:callcenter_salonuser_mobil/util/api_errors.dart';
import 'package:callcenter_salonuser_mobil/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userName = TextEditingController();
  final _password = TextEditingController();
  final _verifyEmail = TextEditingController();
  bool _busy = false;
  bool _resending = false;
  String? _error;
  bool _needsEmailVerify = false;

  @override
  void dispose() {
    _userName.dispose();
    _password.dispose();
    _verifyEmail.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
      _needsEmailVerify = false;
    });
    try {
      final api = context.read<SalonApiClient>();
      final session = context.read<SessionState>();
      final result = await api.login(
        userName: _userName.text.trim(),
        password: _password.text,
      );
      await session.signIn(result);
      if (mounted) Navigator.of(context).maybePop(true);
    } catch (e) {
      final msg = dioErrorMessage(e);
      final lower = msg.toLowerCase();
      final hint = (lower.contains('doğrula') ||
              lower.contains('dogrula') ||
              lower.contains('email')) &&
          lower.contains('mail');
      setState(() {
        _error = msg;
        _needsEmailVerify = hint;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendVerification() async {
    final un = _verifyEmail.text.trim();
    if (un.isEmpty) {
      setState(() => _error = 'Doğrulama maili için kullanıcı adınızı girin.');
      return;
    }
    setState(() => _resending = true);
    try {
      await context.read<SalonApiClient>().sendVerificationEmail(userName: un);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğrulama maili tekrar gönderildi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dioErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş')),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Salon yönetim hesabınızla giriş yapın. Müşteri girişi değildir.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userName,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(labelText: 'Kullanıcı adı / E-posta'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Şifre'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
            if (_needsEmailVerify) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Doğrulama mailinizi alamadıysanız tekrar gönderebiliriz.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _verifyEmail,
                        decoration: const InputDecoration(
                          labelText: 'Hesap kullanıcı adı (e-posta)',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _resending ? null : _resendVerification,
                        icon: _resending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.outgoing_mail),
                        label: const Text('Doğrulama mailini tekrar gönder'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Giriş yap'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                      ),
              child: const Text('Şifremi unuttum'),
            ),
          ],
        ),
      ),
    );
  }
}
