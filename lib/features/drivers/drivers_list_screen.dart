import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import '../reviews/rating_stars.dart';
import '../reviews/user_reviews_screen.dart';

class DriversListScreen extends StatefulWidget {
  const DriversListScreen({super.key});

  @override
  State<DriversListScreen> createState() => _DriversListScreenState();
}

class _DriversListScreenState extends State<DriversListScreen> {
  final _repo = UserRepository();

  double _minRating = 0;
  late Future<List<UserModel>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _repo.getDrivers(minRating: _minRating);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Водители')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Мин. рейтинг:'),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: 5,
                    divisions: 10,
                    value: _minRating,
                    label: _minRating.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _minRating = v),
                    onChangeEnd: (_) => setState(_reload),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    _minRating.toStringAsFixed(1),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _future,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Ошибка: ${snap.error}'));
                }
                final drivers = snap.data ?? [];
                if (drivers.isEmpty) {
                  return const Center(
                    child: Text(
                      'Нет водителей под этот фильтр',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(_reload);
                    await _future;
                  },
                  child: ListView.separated(
                    itemCount: drivers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final d = drivers[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Text(
                            d.name.isNotEmpty
                                ? d.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(d.name),
                        subtitle: Row(
                          children: [
                            RatingStars(value: d.rating, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              d.ratingCount > 0
                                  ? '${d.rating.toStringAsFixed(1)} '
                                      '(${d.ratingCount})'
                                  : 'нет оценок',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => UserReviewsScreen(
                                userId: d.id,
                                userName: d.name,
                                averageRating: d.rating,
                                reviewsCount: d.ratingCount,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
