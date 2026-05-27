import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/pricing_service.dart';
import '../../models/location_model.dart';
import '../../models/ride_model.dart';
import '../../repositories/location_repository.dart';
import '../../repositories/ride_repository.dart';
import 'searching_screen.dart';
import 'active_ride_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  final _rideRepo = RideRepository();
  final _locationRepo = LocationRepository();

  late final List<LocationModel> _locations;

  String _orderType = RideType.taxi;

  LocationModel? _from;
  LocationModel? _to;

  final _senderNameCtrl = TextEditingController();
  final _receiverNameCtrl = TextEditingController();
  final _receiverPhoneCtrl = TextEditingController();
  final _packageDescCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _locations = _locationRepo.getAll();

    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _senderNameCtrl.text = user.name;
    }
  }

  @override
  void dispose() {
    _senderNameCtrl.dispose();
    _receiverNameCtrl.dispose();
    _receiverPhoneCtrl.dispose();
    _packageDescCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  TripEstimate? get _estimate {
    if (_from == null || _to == null) return null;
    if (_from!.id == _to!.id) return null;
    return PricingService.estimate(_from!, _to!, type: _orderType);
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
          const SnackBar(content: Text('У вас нет активных заказов')),
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

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
    });
  }

  String? _validateDeliveryFields() {
    if (_senderNameCtrl.text.trim().isEmpty) {
      return 'Укажите имя отправителя';
    }
    if (_receiverNameCtrl.text.trim().isEmpty) {
      return 'Укажите имя получателя';
    }
    if (_receiverPhoneCtrl.text.trim().isEmpty) {
      return 'Укажите телефон получателя';
    }
    if (_packageDescCtrl.text.trim().isEmpty) {
      return 'Опишите посылку';
    }
    return null;
  }

  Future<void> _placeOrder() async {
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите точки A и B')),
      );
      return;
    }

    if (_from!.id == _to!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Точки отправления и назначения совпадают')),
      );
      return;
    }

    if (_orderType == RideType.delivery) {
      final err = _validateDeliveryFields();
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
        return;
      }
    }

    final est = _estimate!;
    final user = context.read<AuthProvider>().user!;
    final price = double.parse(est.price.toStringAsFixed(0));

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
      final isDelivery = _orderType == RideType.delivery;
      final weight = double.tryParse(
            _weightCtrl.text.trim().replaceAll(',', '.'),
          ) ??
          0;

      final ride = RideModel(
        id: '',
        type: _orderType,
        passengerId: user.id,
        passengerName: user.name,
        fromAddress: _from!.name,
        toAddress: _to!.name,
        price: price,
        status: RideStatus.searching,
        createdAt: DateTime.now(),
        senderName: isDelivery ? _senderNameCtrl.text.trim() : '',
        receiverName: isDelivery ? _receiverNameCtrl.text.trim() : '',
        receiverPhone: isDelivery ? _receiverPhoneCtrl.text.trim() : '',
        packageDescription: isDelivery ? _packageDescCtrl.text.trim() : '',
        weight: isDelivery ? weight : 0,

        deliveryFee: isDelivery ? est.deliveryFee : 0,
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
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _typeSwitcher() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: _typeButton(
                label: 'Такси',
                icon: Icons.local_taxi,
                value: RideType.taxi,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _typeButton(
                label: 'Доставка',
                icon: Icons.local_shipping,
                value: RideType.delivery,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeButton({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final selected = _orderType == value;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _orderType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.amber : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.black : Colors.grey[700],
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.black : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationDropdown({
    required String label,
    required IconData icon,
    required Color iconColor,
    required LocationModel? value,
    required ValueChanged<LocationModel?> onChanged,
  }) {
    return DropdownButtonFormField<LocationModel>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor),
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: _locations
          .map(
            (l) => DropdownMenuItem<LocationModel>(
              value: l,
              child: Text(l.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        setState(() => onChanged(v));
      },
    );
  }

  Widget _deliveryFields() {
    return Card(
      color: Colors.deepPurple[50],
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Данные посылки',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _senderNameCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                labelText: 'Отправитель',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _receiverNameCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person),
                labelText: 'Получатель',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _receiverPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone),
                labelText: 'Телефон получателя',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _packageDescCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.description),
                labelText: 'Описание посылки',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.scale),
                labelText: 'Вес, кг (необязательно)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _estimateCard(TripEstimate est) {
    final isDelivery = est.isDelivery;
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Расстояние: ${est.distanceKm.toStringAsFixed(2)} км',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Посадка: ${est.boardingFee.toStringAsFixed(0)} ₸',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            Text(
              'За км: ${est.perKm.toStringAsFixed(0)} ₸ × '
              '${est.distanceKm.toStringAsFixed(2)} = '
              '${(est.perKm * est.distanceKm).toStringAsFixed(0)} ₸',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            if (isDelivery)
              Text(
                'Доплата за доставку: ${est.deliveryFee.toStringAsFixed(0)} ₸',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const Divider(height: 16),
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Итого: ${est.price.toStringAsFixed(0)} ₸',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final est = _estimate;
    final isDelivery = _orderType == RideType.delivery;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taxi App'),
        actions: [
          IconButton(
            tooltip: 'Текущий заказ',
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
      body: SingleChildScrollView(
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
            const SizedBox(height: 16),

            _typeSwitcher(),
            const SizedBox(height: 16),
            _locationDropdown(
              label: isDelivery ? 'Откуда забрать' : 'Откуда (точка A)',
              icon: Icons.my_location,
              iconColor: Colors.green,
              value: _from,
              onChanged: (v) => _from = v,
            ),
            const SizedBox(height: 8),
            Center(
              child: IconButton(
                tooltip: 'Поменять местами',
                icon: const Icon(Icons.swap_vert),
                onPressed: (_from == null && _to == null) ? null : _swap,
              ),
            ),
            const SizedBox(height: 8),
            _locationDropdown(
              label: isDelivery ? 'Куда доставить' : 'Куда (точка B)',
              icon: Icons.location_on,
              iconColor: Colors.red,
              value: _to,
              onChanged: (v) => _to = v,
            ),
            const SizedBox(height: 16),

            if (isDelivery) ...[
              _deliveryFields(),
              const SizedBox(height: 16),
            ],
            if (est != null) _estimateCard(est),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(
                isDelivery ? Icons.local_shipping : Icons.local_taxi,
              ),
              label: Text(
                isDelivery ? 'Заказать доставку' : 'Заказать такси',
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isDelivery ? Colors.deepPurple : Colors.amber,
                foregroundColor: isDelivery ? Colors.white : Colors.black,
              ),
              onPressed: (_loading || est == null) ? null : _placeOrder,
            ),
          ],
        ),
      ),
    );
  }
}
