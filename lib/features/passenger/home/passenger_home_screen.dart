import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_constants.dart';
import '../../../core/auth_provider.dart';
import '../../../models/ride_model.dart';
import '../../../repositories/ride_repository.dart';
import '../searching/searching_screen.dart';
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
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taxi App'),
        actions: [
          IconButton(
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
              child: ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.amber,
                ),
                title: const Text('Ваш баланс'),
                subtitle: Text(
                  '${user?.balance.toStringAsFixed(0) ?? 0} ₸',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
