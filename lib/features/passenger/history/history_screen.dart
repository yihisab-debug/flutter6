import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';
import '../../../models/ride_model.dart';
import '../../../repositories/ride_repository.dart';
import '../../reviews/ride_reviews_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _rideRepo = RideRepository();
  late Future<List<RideModel>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final user = context.read<AuthProvider>().user!;

    _future = user.isDriver
        ? _rideRepo.getDriverHistory(user.id)
        : _rideRepo.getPassengerHistory(user.id);
  }

  void _openRideReviews(RideModel ride) {
    if (ride.status != RideStatus.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Отзывы доступны только для завершённых поездок'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RideReviewsScreen(ride: ride),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('История поездок')),
      body: FutureBuilder<List<RideModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text('Ошибка: ${snap.error}'));
          }

          final rides = snap.data ?? [];

          if (rides.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                setState(_load);
                await _future;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Пусто',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'У вас пока нет поездок',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_load);
              await _future;
            },
            child: ListView.separated(
              itemCount: rides.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final r = rides[i];
                final completed = r.status == RideStatus.completed;
                return ListTile(
                  leading: Icon(
                    completed ? Icons.check_circle : Icons.cancel,
                    color: completed ? Colors.green : Colors.redAccent,
                  ),
                  title: Text('${r.fromAddress} → ${r.toAddress}'),
                  subtitle: Text(
                    r.createdAt != null
                        ? DateFormat('dd.MM.yyyy HH:mm').format(r.createdAt!)
                        : '',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${r.price.toStringAsFixed(0)} ₸'),
                      if (completed) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ],
                  ),
                  onTap: completed ? () => _openRideReviews(r) : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
