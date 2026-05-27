import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/app_constants.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/test_accounts_panel.dart';
import 'complete_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.appTitle,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.testAccounts,
    required this.testAccountsTitle,
    this.showGoogleSignIn = true,
    this.showFacebookSignIn = true,
  });

  final String appTitle;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<TestAccount> testAccounts;
  final String testAccountsTitle;
  final bool showGoogleSignIn;
  final bool showFacebookSignIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[700]),
    );
  }

  void _handleAuthResult(AuthFlowResult? result, AuthProvider auth) {
    if (!mounted) return;
    if (result == null) {
      if (auth.error != null) {
        _showError(auth.error!);
        auth.clearError();
      }
      return;
    }

    if (result.needsRole) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CompleteRegistrationScreen(
            firebaseUid: result.firebaseUid!,
            email: result.email!,
            initialName: result.name ?? '',
            roleLabel: _roleLabel(auth.expectedRole),
          ),
        ),
      );
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'passenger':
        return 'пассажир';
      case 'driver':
        return 'водитель';
      case 'admin':
        return 'администратор';
      default:
        return role;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.signInOrRegister(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    _handleAuthResult(result, auth);
  }

  Future<void> _signInWithGoogle() async {
    final auth = context.read<AuthProvider>();
    final result = await auth.signInWithGoogle();
    _handleAuthResult(result, auth);
  }

  Future<void> _signInWithFacebook() async {
    final auth = context.read<AuthProvider>();
    final result = await auth.signInWithFacebook();
    _handleAuthResult(result, auth);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appTitle),
        backgroundColor: widget.accentColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(widget.icon, size: 80, color: widget.accentColor),
              const SizedBox(height: 16),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              TestAccountsPanel(
                accounts: widget.testAccounts,
                title: widget.testAccountsTitle,
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'или войти',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || !v.contains('@')) return 'Неверный email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) return 'Минимум 6 символов';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: widget.accentColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: auth.loading ? null : _submit,
                child: auth.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Продолжить', style: TextStyle(fontSize: 16)),
              ),

              if (widget.showGoogleSignIn || widget.showFacebookSignIn) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child:
                          Text('или', style: TextStyle(color: Colors.grey[600])),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (widget.showGoogleSignIn) ...[
                OutlinedButton.icon(
                  onPressed: auth.loading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  icon: const Icon(Icons.g_mobiledata,
                      size: 32, color: Colors.red),
                  label: const Text(
                    'Войти через Google',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (widget.showFacebookSignIn) ...[
                OutlinedButton.icon(
                  onPressed: auth.loading ? null : _signInWithFacebook,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  icon: const Icon(Icons.facebook,
                      size: 28, color: Color(0xFF1877F2)),
                  label: const Text(
                    'Войти через Facebook',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
