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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступные заказы'),
        actions: [
          IconButton(
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_rides.isEmpty) {
      return const Center(child: Text('Нет доступных заказов'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _rides.length,
        itemBuilder: (ctx, i) {
          final r = _rides[i];
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
                  Text(
                    'Пассажир: ${r.passengerName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Откуда: ${r.fromAddress}'),
                  Text('Куда: ${r.toAddress}'),
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
                      child: const Text('Принять заказ'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
