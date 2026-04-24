import '../core/api_client.dart';
import '../core/app_constants.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';

class SeedRepository {
  final _dio = ApiClient().dio;
  final _usersEndpoint = AppConstants.usersEndpoint;
  final _ridesEndpoint = AppConstants.ridesEndpoint;

  Future<SeedResult> seedAll() async {
    int driversCreated = 0;
    int passengersCreated = 0;
    int ridesCreated = 0;

    final driversData = [
      UserModel(
        id: '',
        name: 'Иван Петров',
        email: 'driver1@test.com',
        role: 'driver',
        balance: 0,
        firebaseUid: 'seed_driver_1',
        carModel: 'Toyota Camry',
        carNumber: '123 ABC 01',
        rating: 4.8,
        isAvailable: true,
      ),
      UserModel(
        id: '',
        name: 'Марат Алиев',
        email: 'driver2@test.com',
        role: 'driver',
        balance: 0,
        firebaseUid: 'seed_driver_2',
        carModel: 'Hyundai Accent',
        carNumber: '456 XYZ 02',
        rating: 5.0,
        isAvailable: true,
      ),
    ];

    for (final driver in driversData) {
      try {
        await _dio.post(_usersEndpoint, data: driver.toJson());
        driversCreated++;
      } catch (_) {}
    }

    final passengersData = [
      UserModel(
        id: '',
        name: 'Айгуль',
        email: 'passenger1@test.com',
        role: 'passenger',
        balance: 5000,
        firebaseUid: 'seed_passenger_1',
        rating: 0,
        isAvailable: true,
      ),
      UserModel(
        id: '',
        name: 'Данияр',
        email: 'passenger2@test.com',
        role: 'passenger',
        balance: 5000,
        firebaseUid: 'seed_passenger_2',
        rating: 0,
        isAvailable: true,
      ),
    ];

    final createdPassengers = <UserModel>[];
    for (final passenger in passengersData) {
      try {
        final response = await _dio.post(
          _usersEndpoint,
          data: passenger.toJson(),
        );
        createdPassengers.add(UserModel.fromJson(response.data));
        passengersCreated++;
      } catch (_) {}
    }

    if (createdPassengers.length >= 2) {
      final ridesData = [
        RideModel(
          id: '',
          passengerId: createdPassengers[0].id,
          passengerName: createdPassengers[0].name,
          fromAddress: 'ул. Абая, 150',
          toAddress: 'ул. Достык, 200',
          price: 1500,
          status: RideStatus.searching,
        ),
        RideModel(
          id: '',
          passengerId: createdPassengers[1].id,
          passengerName: createdPassengers[1].name,
          fromAddress: 'ТРЦ Мега',
          toAddress: 'Аэропорт Алматы',
          price: 2500,
          status: RideStatus.searching,
        ),
      ];

      for (final ride in ridesData) {
        try {
          await _dio.post(_ridesEndpoint, data: ride.toJson());
          ridesCreated++;
        } catch (_) {}
      }
    }

    return SeedResult(
      driversCreated: driversCreated,
      passengersCreated: passengersCreated,
      ridesCreated: ridesCreated,
    );
  }
}

class SeedResult {
  final int driversCreated;
  final int passengersCreated;
  final int ridesCreated;

  SeedResult({
    required this.driversCreated,
    required this.passengersCreated,
    required this.ridesCreated,
  });

  @override
  String toString() {
    return 'Создано: $driversCreated водителей, $passengersCreated пассажиров, $ridesCreated заказов';
  }
}
