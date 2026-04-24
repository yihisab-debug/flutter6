import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

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
          const SizedBox(height: 20),
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
                ),
                if (user.isDriver) ...[
                  ListTile(
                    leading: const Icon(Icons.directions_car),
                    title: const Text('Автомобиль'),
                    subtitle: Text(user.carInfo),
                  ),
                  ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: const Text('Рейтинг'),
                    subtitle: Text(user.rating.toStringAsFixed(1)),
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
