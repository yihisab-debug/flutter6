import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _carModelCtrl = TextEditingController();
  final _carNumCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _role = 'passenger';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _carModelCtrl.dispose();
    _carNumCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
      role: _role,
      carModel: _carModelCtrl.text.trim(),
      carNumber: _carNumCtrl.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Ошибка регистрации')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Имя'),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
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
              const SizedBox(height: 16),
              const Text('Выберите роль:'),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'passenger',
                      groupValue: _role,
                      title: const Text('Пассажир'),
                      onChanged: (v) => setState(() => _role = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'driver',
                      groupValue: _role,
                      title: const Text('Водитель'),
                      onChanged: (v) => setState(() => _role = v!),
                    ),
                  ),
                ],
              ),
              if (_role == 'driver') ...[
                TextFormField(
                  controller: _carModelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Модель авто',
                  ),
                ),
                TextFormField(
                  controller: _carNumCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Гос. номер',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.loading ? null : _submit,
                child: auth.loading
                    ? const CircularProgressIndicator()
                    : const Text('Зарегистрироваться'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
