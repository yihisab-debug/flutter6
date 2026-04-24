import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';

class CompleteRegistrationScreen extends StatefulWidget {
  final String firebaseUid;
  final String email;
  final String initialName;

  const CompleteRegistrationScreen({
    super.key,
    required this.firebaseUid,
    required this.email,
    this.initialName = '',
  });

  @override
  State<CompleteRegistrationScreen> createState() =>
      _CompleteRegistrationScreenState();
}

class _CompleteRegistrationScreenState
    extends State<CompleteRegistrationScreen> {
  late final TextEditingController _nameCtrl;
  final _carModelCtrl = TextEditingController();
  final _carNumCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _role = 'passenger';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _carModelCtrl.dispose();
    _carNumCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    final ok = await auth.completeRegistration(
      firebaseUid: widget.firebaseUid,
      email: widget.email,
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
      appBar: AppBar(
        title: const Text('Завершение регистрации'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.amber[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Добро пожаловать!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.email,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Осталось заполнить пару деталей',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ваше имя',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Кто вы?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _carModelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Модель авто',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (_role == 'driver' && (v == null || v.trim().isEmpty)) {
                      return 'Введите модель авто';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _carNumCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Гос. номер',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (_role == 'driver' && (v == null || v.trim().isEmpty)) {
                      return 'Введите гос. номер';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: auth.loading ? null : _submit,
                child: auth.loading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Продолжить',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
