import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_constants.dart';
import '../../../core/auth_provider.dart';
import '../../../models/ride_model.dart';
import '../../../repositories/ride_repository.dart';
import '../searching/searching_screen.dart';
import '../active_ride/active_ride_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _rideRepo = RideRepository();

  bool _loading = false;
  double _estimatedPrice = 0;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  double _calculatePrice() {
    final random = Random();
    final distance = AppConstants.minDistance +
        random.nextDouble() *
            (AppConstants.maxDistance - AppConstants.minDistance);
    return AppConstants.basePrice + distance * AppConstants.pricePerKm;
  }

  Future<void> _topUp() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.topUpBalance(5000);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Баланс пополнен на 5000 ₸'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Ошибка пополнения')),
      );
    }
  }

  Future<void> _openCurrentRide() async {
    final user = context.read<AuthProvider>().user!;

    try {
      final active = await _rideRepo.getActiveRideForPassenger(user.id);

      if (!mounted) return;

      if (active == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('У вас нет активных поездок')),
        );
        return;
      }

      if (active.status == RideStatus.searching) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SearchingScreen(rideId: active.id),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActiveRideScreen(rideId: active.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _orderTaxi() async {
    if (_fromCtrl.text.isEmpty || _toCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните оба адреса')),
      );
      return;
    }

    final user = context.read<AuthProvider>().user!;
    final price = _calculatePrice();

    if (user.balance < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Недостаточно средств. Нужно: ${price.toStringAsFixed(0)} ₸',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final ride = RideModel(
        id: '',
        passengerId: user.id,
        passengerName: user.name,
        fromAddress: _fromCtrl.text,
        toAddress: _toCtrl.text,
        price: double.parse(price.toStringAsFixed(0)),
        status: RideStatus.searching,
      );

      final created = await _rideRepo.createRide(ride);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SearchingScreen(rideId: created.id),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taxi App'),
        actions: [
          IconButton(
            tooltip: 'Текущая поездка',
            icon: const Icon(Icons.directions_car),
            onPressed: _openCurrentRide,
          ),
          IconButton(
            tooltip: 'История',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Профиль',
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.amber,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ваш баланс',
                            style: TextStyle(color: Colors.black54),
                          ),
                          Text(
                            '${user?.balance.toStringAsFixed(0) ?? 0} ₸',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('5000'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onPressed: auth.loading ? null : _topUp,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _fromCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.my_location, color: Colors.green),
                labelText: 'Откуда',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                setState(() {
                  _estimatedPrice = _calculatePrice();
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _toCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_on, color: Colors.red),
                labelText: 'Куда',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                setState(() {
                  _estimatedPrice = _calculatePrice();
                });
              },
            ),
            const SizedBox(height: 20),
            if (_fromCtrl.text.isNotEmpty && _toCtrl.text.isNotEmpty)
              Text(
                'Примерная стоимость: ${_estimatedPrice.toStringAsFixed(0)} ₸',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.local_taxi),
              label: const Text(
                'Заказать такси',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              onPressed: _loading ? null : _orderTaxi,
            ),
          ],
        ),
      ),
    );
  }
}
