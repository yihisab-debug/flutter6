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

  Future<void> _markPickedUp() async {
    setState(() => _busy = true);

    try {
      final r = await _rideRepo.markPickedUp(widget.rideId);
      setState(() => _ride = r);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Посылка забрана'),
          backgroundColor: Colors.blue,
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

  Future<void> _markDelivered() async {
    setState(() => _busy = true);

    try {
      final delivered = await _rideRepo.markDelivered(_ride!);
      await context.read<AuthProvider>().refreshUser();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Посылка доставлена. +${delivered.price.toStringAsFixed(0)} ₸',
          ),
          backgroundColor: Colors.green,
        ),
      );

      final driver = context.read<AuthProvider>().user!;

      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => SubmitReviewScreen(
            ride: delivered,
            fromUserId: driver.id,
            toUserId: delivered.passengerId,
            toUserName: delivered.passengerName,
            role: ReviewRole.driverToPassenger,
          ),
        ),
      );

      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RideReviewsScreen(ride: delivered),
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
    final isDelivery = ride.isDelivery;

    return Scaffold(
      appBar: AppBar(
        title: Text(isDelivery ? 'Текущая доставка' : 'Текущая поездка'),
      ),
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
                      isDelivery ? 'Клиент' : 'Пассажир',
                      ride.passengerName,
                    ),
                    _row(
                      Icons.my_location,
                      isDelivery ? 'Забрать' : 'Откуда',
                      ride.fromAddress,
                    ),
                    _row(
                      Icons.location_on,
                      isDelivery ? 'Доставить' : 'Куда',
                      ride.toAddress,
                    ),
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
            if (isDelivery) ...[
              const SizedBox(height: 12),
              _deliveryInfoCard(ride),
            ],
            const SizedBox(height: 20),
            ..._actionButtons(ride),
          ],
        ),
      ),
    );
  }

  List<Widget> _actionButtons(RideModel ride) {
    if (ride.isDelivery) {
      switch (ride.status) {
        case RideStatus.accepted:
          return [
            _bigButton(
              label: 'Прибыл за посылкой',
              color: Colors.blue,
              icon: Icons.location_on,
              onPressed: _busy ? null : _startRide,
            ),
          ];
        case RideStatus.inProgress:
          return [
            _bigButton(
              label: 'Подтвердить забор посылки',
              color: Colors.orange,
              icon: Icons.inventory,
              onPressed: _busy ? null : _markPickedUp,
            ),
          ];
        case RideStatus.pickedUp:
          return [
            _bigButton(
              label: 'Подтвердить доставку',
              color: Colors.green,
              icon: Icons.check_circle,
              onPressed: _busy ? null : _markDelivered,
            ),
          ];
        default:
          return const [];
      }
    } else {

      switch (ride.status) {
        case RideStatus.accepted:
          return [
            _bigButton(
              label: 'Начать поездку',
              color: Colors.blue,
              icon: Icons.play_arrow,
              onPressed: _busy ? null : _startRide,
            ),
          ];
        case RideStatus.inProgress:
          return [
            _bigButton(
              label: 'Завершить поездку',
              color: Colors.green,
              icon: Icons.check_circle,
              onPressed: _busy ? null : _completeRide,
            ),
          ];
        default:
          return const [];
      }
    }
  }

  Widget _bigButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 18)),
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
