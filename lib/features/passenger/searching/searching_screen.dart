import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/app_constants.dart';
import '../../../core/notification_service.dart';
import '../../../models/ride_model.dart';
import '../../../repositories/ride_repository.dart';
import '../active_ride/active_ride_screen.dart';

class SearchingScreen extends StatefulWidget {
  final String rideId;

  const SearchingScreen({super.key, required this.rideId});

  @override
  State<SearchingScreen> createState() => _SearchingScreenState();
}

class _SearchingScreenState extends State<SearchingScreen> {
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
      setState(() => _ride = ride);

      if (ride.status == RideStatus.accepted) {
        _timer?.cancel();

        NotificationService().showLocalNotification(
          title: 'Водитель найден!',
          body: '${ride.driverName} едет к вам',
        );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ActiveRideScreen(rideId: ride.id),
            ),
          );
        }
      } else if (ride.status == RideStatus.cancelled) {
        _timer?.cancel();
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      // Игнорируем ошибки сети во время polling
    }
  }

  Future<void> _cancel() async {
    await _rideRepo.cancelRide(widget.rideId);
    _timer?.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Поиск водителя')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text(
                'Ищем для вас водителя...',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              if (_ride != null)
                Text(
                  'Стоимость: ${_ride!.price.toStringAsFixed(0)} ₸',
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: _cancel,
                child: const Text('Отменить заказ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
