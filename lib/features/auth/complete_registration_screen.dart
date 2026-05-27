import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';

class CompleteRegistrationScreen extends StatefulWidget {
  const CompleteRegistrationScreen({
    super.key,
    required this.firebaseUid,
    required this.email,
    this.initialName = '',
    required this.roleLabel,
  });

  final String firebaseUid;
  final String email;
  final String initialName;
  final String roleLabel;

  @override
  State<CompleteRegistrationScreen> createState() =>
      _CompleteRegistrationScreenState();
}

class _CompleteRegistrationScreenState
    extends State<CompleteRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final _carModelCtrl = TextEditingController();
  final _carNumberCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _carModelCtrl.dispose();
    _carNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    final ok = await auth.completeRegistration(
      firebaseUid: widget.firebaseUid,
      email: widget.email,
      name: _nameCtrl.text.trim(),
      carModel: _carModelCtrl.text.trim(),
      carNumber: _carNumberCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDriver = auth.expectedRole == 'driver';

    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Вы регистрируетесь как ${widget.roleLabel}',
                        style: TextStyle(color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ваше имя',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Введите имя' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: widget.email,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              if (isDriver) ...[
                const SizedBox(height: 20),
                const Text(
                  'Данные автомобиля',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _carModelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Модель (например, Toyota Camry)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (isDriver && (v == null || v.trim().isEmpty)) {
                      return 'Укажите модель';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _carNumberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Госномер',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (isDriver && (v == null || v.trim().isEmpty)) {
                      return 'Укажите номер';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: auth.loading
                    ? const CircularProgressIndicator()
                    : const Text('Завершить регистрацию',
                        style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
