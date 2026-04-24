import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_constants.dart';
import '../../../core/auth_provider.dart';
import '../../../core/notification_service.dart';
import '../../../models/ride_model.dart';
import '../../../repositories/ride_repository.dart';

class ActiveRideScreen extends StatefulWidget {
  final String rideId;

  const ActiveRideScreen({super.key, required this.rideId});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  final _rideRepo = RideRepository();

  Timer? _timer;
  RideModel? _ride;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(AppConstants.pollingInterval, (_) => _check());
    _check();
  }

  Future<void> _check() async {
    try {
      final ride = await _rideRepo.getRide(widget.rideId);
      final prevStatus = _ride?.status;
      setState(() => _ride = ride);

      if (prevStatus != ride.status) {
        NotificationService().showLocalNotification(
          title: 'Статус поездки',
          body: RideStatus.label(ride.status),
        );
      }

      if (ride.status == RideStatus.completed ||
          ride.status == RideStatus.cancelled) {
        _timer?.cancel();

        await context.read<AuthProvider>().refreshUser();

        if (mounted) {
          final message = ride.status == RideStatus.completed
              ? 'Поездка завершена. Списано ${ride.price.toStringAsFixed(0)} ₸'
              : 'Поездка отменена';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );

          Navigator.of(context).pop();
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ride == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ride = _ride!;

    return Scaffold(
      appBar: AppBar(title: const Text('Поездка')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Статус: ${RideStatus.label(ride.status)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _row(Icons.person, 'Водитель', ride.driverName),
                    _row(Icons.directions_car, 'Авто', ride.carInfo),
                    const Divider(),
                    _row(Icons.my_location, 'Откуда', ride.fromAddress),
                    _row(Icons.location_on, 'Куда', ride.toAddress),
                    const Divider(),
                    _row(
                      Icons.attach_money,
                      'Стоимость',
                      '${ride.price.toStringAsFixed(0)} ₸',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
