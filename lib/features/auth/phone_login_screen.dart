// ==========================================================================
// PhoneLoginScreen — вход и регистрация по номеру телефона через Firebase.
// ==========================================================================
//
// КАК ЭТО РАБОТАЕТ
// ---------------------------------------------------------------------------
// Экран состоит из двух шагов в одном виджете:
//   1) ввод номера телефона   → нажатие "Получить код" → Firebase отправляет SMS
//   2) ввод 6-значного кода   → нажатие "Подтвердить" → Firebase делает вход
//
// Если пользователь с этим Firebase UID существует в нашей БД — сразу попадает
// на главный экран. Если нет — отправляется на CompleteRegistrationScreen,
// где выбирает роль (пассажир/водитель) и вводит имя.
//
// ТЕСТОВЫЕ НОМЕРА (БЕСПЛАТНО, БЕЗ ЛИМИТОВ)
// ---------------------------------------------------------------------------
// Firebase Spark (бесплатный план) НЕ отправляет реальные SMS. Чтобы тестировать
// флоу без перехода на платный Blaze, добавьте тестовые номера:
//
//   Firebase Console → Authentication → Sign-in method → Phone →
//   → Phone numbers for testing → Add phone number.
//
// Для тестового номера SMS не отправляется. Когда пользователь вводит этот
// номер — Firebase сразу принимает фиксированный код, который вы задали.
//
// Пример:
//   +7 700 000 00 01  →  код 123456
//   +7 700 000 00 02  →  код 654321
//
// РЕАЛЬНЫЕ SMS (ТРЕБУЕТСЯ ПЛАН BLAZE)
// ---------------------------------------------------------------------------
// Чтобы реальные пользователи могли регистрироваться по своим номерам, нужно:
//   1) Перейти на план Blaze (Firebase Console → Upgrade).
//   2) Включить нужные регионы: Authentication → Settings → SMS region policy.
//   3) Для Android: добавить SHA-1 и SHA-256 от подписи приложения в
//      Firebase Console → Project Settings → ваше приложение.
//   4) Скачать обновлённый google-services.json и положить в android/app/.
//
// УБРАТЬ ПОДСКАЗКУ ПЕРЕД РЕЛИЗОМ
// ---------------------------------------------------------------------------
// Синяя карточка с подсказкой про тестовые номера полезна при разработке,
// но в продакшене её показывать не нужно. Найдите комментарий
// "Подсказка для разработки" ниже и удалите соответствующий Card.
// ==========================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../repositories/auth_repository.dart';
import 'complete_registration_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _phoneFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();

  String? _verificationId;
  String _phoneNumber = '';

  // Таймер для повторной отправки кода
  Timer? _resendTimer;
  int _resendSeconds = 0;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) t.cancel();
    });
  }

  String _normalizePhone(String raw) {
    // Убираем все пробелы, скобки, дефисы — оставляем + и цифры.
    final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    // Если пользователь ввёл 8XXXXXXXXXX — заменяем на +7
    if (cleaned.startsWith('8') && cleaned.length == 11) {
      return '+7${cleaned.substring(1)}';
    }
    // Если 7XXXXXXXXXX без плюса
    if (cleaned.startsWith('7') && cleaned.length == 11) {
      return '+$cleaned';
    }
    return '+$cleaned';
  }

  void _onAuthResult(AuthFlowResult result) {
    if (!mounted) return;

    if (result.needsRole) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CompleteRegistrationScreen(
            firebaseUid: result.firebaseUid!,
            email: result.email ?? result.phone ?? '',
            initialName: result.name ?? '',
          ),
        ),
      );
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _sendCode() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    final phone = _normalizePhone(_phoneCtrl.text);
    _phoneNumber = phone;

    final auth = context.read<AuthProvider>();
    await auth.sendPhoneCode(
      phoneNumber: phone,
      onCodeSent: (verificationId, _) {
        if (!mounted) return;
        setState(() => _verificationId = verificationId);
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Код отправлен на $phone')),
        );
      },
      onAutoVerified: _onAuthResult,
    );

    if (!mounted) return;
    if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  Future<void> _verifyCode() async {
    if (!_codeFormKey.currentState!.validate()) return;
    if (_verificationId == null) return;

    final auth = context.read<AuthProvider>();
    final result = await auth.verifyPhoneCode(
      verificationId: _verificationId!,
      smsCode: _codeCtrl.text.trim(),
      phoneNumber: _phoneNumber,
    );

    if (!mounted) return;

    if (result == null) {
      if (auth.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error!)),
        );
      }
      return;
    }

    _onAuthResult(result);
  }

  void _resetPhoneStep() {
    setState(() {
      _verificationId = null;
      _codeCtrl.clear();
    });
    _resendTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isCodeStep = _verificationId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход по телефону'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (isCodeStep) {
              _resetPhoneStep();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: isCodeStep ? _buildCodeStep(auth) : _buildPhoneStep(auth),
      ),
    );
  }

  Widget _buildPhoneStep(AuthProvider auth) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.phone_android, size: 80, color: Colors.amber),
          const SizedBox(height: 20),
          const Text(
            'Введите номер телефона',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Мы отправим SMS с кодом подтверждения',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          // Подсказка для разработки — тестовые номера из Firebase Console.
          // Перед публикацией в продакшен этот блок нужно убрать.
          Card(
            color: Colors.blue[50],
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.blue[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 18, color: Colors.blue[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Тестовые номера (для разработки)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'SMS не отправляется. Код задан в Firebase Console:\n'
                    '• +7 700 000 00 01  →  код 123456\n'
                    '• +7 700 000 00 02  →  код 654321\n\n'
                    'Чтобы добавить свои: Firebase Console → Authentication → '
                    'Sign-in method → Phone → Phone numbers for testing.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d+\s()-]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Номер телефона',
              hintText: '+7 700 000 00 00',
              helperText: 'Формат: +7XXXXXXXXXX или 8XXXXXXXXXX (11 цифр)',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Введите номер телефона';
              }
              final cleaned = v.replaceAll(RegExp(r'[^\d]'), '');
              if (cleaned.length < 11) {
                return 'Номер должен содержать 11 цифр (например +7 700 000 00 00)';
              }
              if (cleaned.length > 15) {
                return 'Слишком длинный номер';
              }
              // Проверяем что номер казахстанский/российский: начинается с 7 или 8.
              if (!cleaned.startsWith('7') && !cleaned.startsWith('8')) {
                return 'Номер должен начинаться с +7 или 8';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: auth.loading ? null : _sendCode,
            child: auth.loading
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text(
                    'Получить код',
                    style: TextStyle(fontSize: 18),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep(AuthProvider auth) {
    // Определяем, является ли номер из стандартного тестового пула,
    // чтобы показать подходящую подсказку.
    final isLikelyTestNumber = _phoneNumber.startsWith('+7700000000');

    return Form(
      key: _codeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.sms, size: 80, color: Colors.amber),
          const SizedBox(height: 20),
          const Text(
            'Введите код из SMS',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Код отправлен на $_phoneNumber',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          if (isLikelyTestNumber)
            Card(
              color: Colors.blue[50],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.blue[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Это тестовый номер — введите код, который вы '
                        'указали в Firebase Console для этого номера.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              labelText: 'Код',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            validator: (v) {
              if (v == null || v.trim().length != 6) {
                return 'Введите 6-значный код';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: auth.loading ? null : _verifyCode,
            child: auth.loading
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text(
                    'Подтвердить',
                    style: TextStyle(fontSize: 18),
                  ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: (_resendSeconds > 0 || auth.loading) ? null : _sendCode,
            child: Text(
              _resendSeconds > 0
                  ? 'Отправить код повторно ($_resendSeconds)'
                  : 'Отправить код повторно',
            ),
          ),
          TextButton(
            onPressed: auth.loading ? null : _resetPhoneStep,
            child: const Text('Изменить номер'),
          ),
        ],
      ),
    );
  }
}
