import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/auth_provider.dart';
import 'core/notification_service.dart';
import 'features/auth/login_screen.dart';
import 'features/passenger/home/passenger_home_screen.dart';
import 'features/driver/available_rides/available_rides_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService().init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..restore(),
      child: const TaxiApp(),
    ),
  );
}

class TaxiApp extends StatelessWidget {
  const TaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxi App',
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
      return const LoginScreen();
    }

    if (auth.user!.isDriver) {
      return const AvailableRidesScreen();
    }

    return const PassengerHomeScreen();
  }
}
