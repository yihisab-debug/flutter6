import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/app_constants.dart';
import 'core/auth_provider.dart';
import 'core/notification_service.dart';
import 'features/auth/login_screen.dart';
import 'features/passenger/passenger_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(expectedRole: 'passenger')..restore(),
      child: const PassengerApp(),
    ),
  );
}

class PassengerApp extends StatelessWidget {
  const PassengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxi — Пассажир',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
        ),
      ),
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return const LoginScreen(
        appTitle: 'Taxi — Пассажир',
        subtitle: 'Закажите такси за пару тапов',
        icon: Icons.person_pin_circle,
        accentColor: Colors.amber,
        testAccounts: TestAccounts.passengers,
        testAccountsTitle: 'Тестовые пассажиры',
      );
    }
    return const PassengerHomeScreen();
  }
}
