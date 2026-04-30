import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';
import '../../../core/pricing_service.dart';
import '../../../models/location_model.dart';
import '../../../models/ride_model.dart';
import '../../../repositories/location_repository.dart';
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
  final _rideRepo = RideRepository();
  final _locationRepo = LocationRepository();

  late final List<LocationModel> _locations;

  LocationModel? _from;
  LocationModel? _to;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _locations = _locationRepo.getAll();
  }

  TripEstimate? get _estimate {
    if (_from == null || _to == null) return null;
    if (_from!.id == _to!.id) return null;
    return PricingService.estimate(_from!, _to!);
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

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
    });
  }

  Future<void> _orderTaxi() async {
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
      final ride = RideModel(
        id: '',
        passengerId: user.id,
        passengerName: user.name,
        fromAddress: _from!.name,
        toAddress: _to!.name,
        price: price,
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final est = _estimate;

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
            const SizedBox(height: 20),
            _locationDropdown(
              label: 'Откуда (точка A)',
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
              label: 'Куда (точка B)',
              icon: Icons.location_on,
              iconColor: Colors.red,
              value: _to,
              onChanged: (v) => _to = v,
            ),
            const SizedBox(height: 20),
            if (est != null)
              Card(
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
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Стоимость: ${est.price.toStringAsFixed(0)} ₸',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
              onPressed: (_loading || est == null) ? null : _orderTaxi,
            ),
          ],
        ),
      ),
    );
  }
}
