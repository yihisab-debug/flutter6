import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_constants.dart';
import '../../../core/auth_provider.dart';
import '../../../models/ride_model.dart';
import '../../../repositories/ride_repository.dart';
import '../active_ride/driver_active_ride_screen.dart';
import '../history/driver_history_screen.dart';
import '../profile/driver_profile_screen.dart';

class AvailableRidesScreen extends StatefulWidget {
  const AvailableRidesScreen({super.key});

  @override
  State<AvailableRidesScreen> createState() => _AvailableRidesScreenState();
}

class _AvailableRidesScreenState extends State<AvailableRidesScreen> {
  final _rideRepo = RideRepository();

  Timer? _timer;
  List<RideModel> _rides = [];
  bool _loading = true;

  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _checkActiveRide();
    _startPolling();
  }

  Future<void> _checkActiveRide() async {
    final user = context.read<AuthProvider>().user!;
    final active = await _rideRepo.getActiveRideForDriver(user.id);

    if (active != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DriverActiveRideScreen(rideId: active.id),
        ),
      );
    }
  }

  Future<void> _openCurrentRide() async {
    final user = context.read<AuthProvider>().user!;

    try {
      final active = await _rideRepo.getActiveRideForDriver(user.id);

      if (!mounted) return;

      if (active == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('У вас нет активных заказов')),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DriverActiveRideScreen(rideId: active.id),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _startPolling() {
    _load();
    _timer = Timer.periodic(
      AppConstants.pollingInterval,
      (_) => _load(),
    );
  }

  Future<void> _load() async {
    try {
      final rides = await _rideRepo.getAvailableRides();
      if (mounted) {
        setState(() {
          _rides = rides;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(RideModel ride) async {
    final user = context.read<AuthProvider>().user!;

    try {
      final accepted = await _rideRepo.acceptRide(ride.id, user);
      _timer?.cancel();

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DriverActiveRideScreen(rideId: accepted.id),
        ),
      ).then((_) => _startPolling());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось принять заказ: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<RideModel> get _filtered {
    if (_filter == 'all') return _rides;
    return _rides.where((r) => r.type == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступные заказы'),
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
                  builder: (_) => const DriverHistoryScreen(),
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
                  builder: (_) => const DriverProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _filterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _filterChip(label: 'Все', value: 'all'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _filterChip(label: 'Такси', value: RideType.taxi),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _filterChip(label: 'Доставка', value: RideType.delivery),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({required String label, required String value}) {
    final selected = _filter == value;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.amber : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.black : Colors.grey[800],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = _filtered;

    if (list.isEmpty) {
      return const Center(child: Text('Нет доступных заказов'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final r = list[i];
          return _rideCard(r);
        },
      ),
    );
  }

  Widget _rideCard(RideModel r) {
    final isDelivery = r.isDelivery;
    final accentColor = isDelivery ? Colors.deepPurple : Colors.amber[800]!;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDelivery
                        ? Colors.deepPurple[50]
                        : Colors.amber[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDelivery
                            ? Icons.local_shipping
                            : Icons.local_taxi,
                        size: 16,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        RideType.label(r.type),
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isDelivery
                  ? 'Клиент: ${r.passengerName}'
                  : 'Пассажир: ${r.passengerName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              isDelivery
                  ? 'Забрать: ${r.fromAddress}'
                  : 'Откуда: ${r.fromAddress}',
            ),
            Text(
              isDelivery
                  ? 'Доставить: ${r.toAddress}'
                  : 'Куда: ${r.toAddress}',
            ),
            if (isDelivery && r.packageDescription.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Посылка: ${r.packageDescription}',
                style: const TextStyle(color: Colors.black87),
              ),
            ],
            if (isDelivery && r.weight > 0)
              Text(
                'Вес: ${r.weight.toStringAsFixed(1)} кг',
                style: const TextStyle(color: Colors.black87),
              ),
            const SizedBox(height: 4),
            Text(
              'Доход: ${r.price.toStringAsFixed(0)} ₸',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _accept(r),
                child: Text(
                  isDelivery ? 'Принять доставку' : 'Принять заказ',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
