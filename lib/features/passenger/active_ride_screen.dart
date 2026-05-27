import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_constants.dart';
import '../../core/auth_provider.dart';
import '../../core/notification_service.dart';
import '../../models/review_model.dart';
import '../../models/ride_model.dart';
import '../../repositories/ride_repository.dart';
import '../reviews/ride_reviews_screen.dart';
import '../reviews/submit_review_screen.dart';

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
          title: ride.isDelivery ? 'Статус доставки' : 'Статус поездки',
          body: RideStatus.labelForType(ride.status, ride.type),
        );
      }

      if (ride.isFinished) {
        _timer?.cancel();
        await context.read<AuthProvider>().refreshUser();

        if (!mounted) return;

        if (ride.isSuccessfullyCompleted) {
          final user = context.read<AuthProvider>().user!;

          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => SubmitReviewScreen(
                ride: ride,
                fromUserId: user.id,
                toUserId: ride.driverId,
                toUserName: ride.driverName,
                role: ReviewRole.passengerToDriver,
              ),
            ),
          );

          if (!mounted) return;

          await Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => RideReviewsScreen(ride: ride),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ride.isDelivery ? 'Доставка отменена' : 'Поездка отменена',
              ),
            ),
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
    final isDelivery = ride.isDelivery;

    return Scaffold(
      appBar: AppBar(title: Text(isDelivery ? 'Доставка' : 'Поездка')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            _typeBadge(ride),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Статус: ${RideStatus.labelForType(ride.status, ride.type)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _row(
                      Icons.person,
                      isDelivery ? 'Курьер' : 'Водитель',
                      ride.driverName,
                    ),
                    _row(Icons.directions_car, 'Авто', ride.carInfo),
                    const Divider(),
                    _row(
                      Icons.my_location,
                      isDelivery ? 'Откуда забрать' : 'Откуда',
                      ride.fromAddress,
                    ),
                    _row(
                      Icons.location_on,
                      isDelivery ? 'Куда доставить' : 'Куда',
                      ride.toAddress,
                    ),
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

            if (isDelivery) ...[
              const SizedBox(height: 12),
              _deliveryInfoCard(ride),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(RideModel ride) {
    final isDelivery = ride.isDelivery;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDelivery ? Colors.deepPurple[50] : Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDelivery ? Colors.deepPurple : Colors.amber,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDelivery ? Icons.local_shipping : Icons.local_taxi,
            color: isDelivery ? Colors.deepPurple : Colors.amber[800],
          ),
          const SizedBox(width: 8),
          Text(
            'Тип: ${RideType.label(ride.type)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDelivery ? Colors.deepPurple : Colors.amber[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deliveryInfoCard(RideModel ride) {
    return Card(
      color: Colors.deepPurple[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Информация о посылке',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _row(Icons.person_outline, 'Отправитель', ride.senderName),
            _row(Icons.person, 'Получатель', ride.receiverName),
            _row(Icons.phone, 'Телефон', ride.receiverPhone),
            _row(Icons.description, 'Описание', ride.packageDescription),
            if (ride.weight > 0)
              _row(
                Icons.scale,
                'Вес',
                '${ride.weight.toStringAsFixed(1)} кг',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
