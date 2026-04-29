import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';
import '../../../models/review_model.dart';
import '../../../models/ride_model.dart';
import '../../../repositories/ride_repository.dart';
import '../../reviews/ride_reviews_screen.dart';
import '../../reviews/submit_review_screen.dart';

class DriverActiveRideScreen extends StatefulWidget {
  final String rideId;

  const DriverActiveRideScreen({super.key, required this.rideId});

  @override
  State<DriverActiveRideScreen> createState() =>
      _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState extends State<DriverActiveRideScreen> {
  final _rideRepo = RideRepository();

  RideModel? _ride;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ride = await _rideRepo.getRide(widget.rideId);
    setState(() => _ride = ride);
  }

  Future<void> _startRide() async {
    setState(() => _busy = true);

    try {
      final r = await _rideRepo.startRide(widget.rideId);
      setState(() => _ride = r);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeRide() async {
    setState(() => _busy = true);

    try {
      final completed = await _rideRepo.completeRide(_ride!);
      await context.read<AuthProvider>().refreshUser();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Поездка завершена. +${completed.price.toStringAsFixed(0)} ₸',
          ),
        ),
      );

      final driver = context.read<AuthProvider>().user!;

      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => SubmitReviewScreen(
            ride: completed,
            fromUserId: driver.id,
            toUserId: completed.passengerId,
            toUserName: completed.passengerName,
            role: ReviewRole.driverToPassenger,
          ),
        ),
      );

      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RideReviewsScreen(ride: completed),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
      appBar: AppBar(title: const Text('Текущая поездка')),
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
                    _row(Icons.person, 'Пассажир', ride.passengerName),
                    _row(Icons.my_location, 'Откуда', ride.fromAddress),
                    _row(Icons.location_on, 'Куда', ride.toAddress),
                    const Divider(),
                    _row(
                      Icons.attach_money,
                      'К получению',
                      '${ride.price.toStringAsFixed(0)} ₸',
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (ride.status == RideStatus.accepted)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: _busy ? null : _startRide,
                child: const Text(
                  'Начать поездку',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            if (ride.status == RideStatus.inProgress)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _busy ? null : _completeRide,
                child: const Text(
                  'Завершить поездку',
                  style: TextStyle(fontSize: 18),
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
