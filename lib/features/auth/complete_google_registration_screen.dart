import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';

class CompleteGoogleRegistrationScreen extends StatefulWidget {
  final String firebaseUid;
  final String email;
  final String name;

  const CompleteGoogleRegistrationScreen({
    super.key,
    required this.firebaseUid,
    required this.email,
    required this.name,
  });

  @override
  State<CompleteGoogleRegistrationScreen> createState() =>
      _CompleteGoogleRegistrationScreenState();
}

class _CompleteGoogleRegistrationScreenState
    extends State<CompleteGoogleRegistrationScreen> {
  final _carModelCtrl = TextEditingController();
  final _carNumCtrl = TextEditingController();
  String _role = 'passenger';

  @override
  void dispose() {
    _carModelCtrl.dispose();
    _carNumCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();

    final ok = await auth.completeGoogleRegistration(
      firebaseUid: widget.firebaseUid,
      email: widget.email,
      name: widget.name,
      role: _role,
      carModel: _carModelCtrl.text.trim(),
      carNumber: _carNumCtrl.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Ошибка завершения регистрации')),
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
                    Text(
                      'Привет, ${widget.name}!',
                      style: const TextStyle(
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
                      'Чтобы продолжить, выберите роль в приложении:',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Выберите роль:',
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
              TextField(
                controller: _carModelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Модель авто',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _carNumCtrl,
                decoration: const InputDecoration(
                  labelText: 'Гос. номер',
                  border: OutlineInputBorder(),
                ),
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
    );
  }
}
