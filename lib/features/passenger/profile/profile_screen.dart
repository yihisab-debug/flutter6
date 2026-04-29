import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';
import '../../reviews/rating_stars.dart';
import '../../reviews/user_reviews_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _topUp(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.topUpBalance(5000);

    if (!context.mounted) return;

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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.amber,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              user.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: Chip(
              label: Text(user.isDriver ? 'Водитель' : 'Пассажир'),
              backgroundColor: Colors.amber[100],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: Row(
                children: [
                  Text(
                    user.ratingCount > 0
                        ? user.rating.toStringAsFixed(1)
                        : '—',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (user.ratingCount > 0)
                    RatingStars(value: user.rating, size: 18),
                ],
              ),
              subtitle: Text(
                user.ratingCount > 0
                    ? 'Отзывов: ${user.ratingCount}'
                    : 'Пока нет отзывов',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserReviewsScreen(
                      userId: user.id,
                      userName: user.name,
                      averageRating: user.rating,
                      reviewsCount: user.ratingCount,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(user.email),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.amber,
                  ),
                  title: const Text('Баланс'),
                  subtitle: Text(
                    '${user.balance.toStringAsFixed(0)} ₸',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: user.isPassenger
                      ? ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('5000'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: auth.loading
                              ? null
                              : () => _topUp(context),
                        )
                      : null,
                ),
                if (user.isDriver) ...[
                  ListTile(
                    leading: const Icon(Icons.directions_car),
                    title: const Text('Автомобиль'),
                    subtitle: Text(user.carInfo),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Выйти'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }
}
