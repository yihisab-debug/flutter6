import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../repositories/seed_repository.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _seeding = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Ошибка входа')),
      );
    }
  }

  Future<void> _seedTestData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Создать тестовые данные?'),
        content: const Text(
          'Будут добавлены:\n'
          '• 2 тестовых водителя\n'
          '• 2 тестовых пассажира\n'
          '• 2 заказа со статусом "searching"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Создать'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _seeding = true);

    try {
      final result = await SeedRepository().seedAll();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.toString()),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.local_taxi,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  if (v == null || !v.contains('@')) {
                    return 'Неверный email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Пароль'),
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return 'Минимум 6 символов';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.loading ? null : _submit,
                child: auth.loading
                    ? const CircularProgressIndicator()
                    : const Text('Войти'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text('Нет аккаунта? Зарегистрироваться'),
              ),

              const Divider(height: 32),
              
              OutlinedButton.icon(
                onPressed: _seeding ? null : _seedTestData,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,        
                  side: const BorderSide(
                    color: Colors.red,              
                    width: 1.5,                         
                  ),
                ),
                icon: _seeding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.data_object),
                label: Text(
                  _seeding ? 'Создание...' : 'Заполнить тестовые данные',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
