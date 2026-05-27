class AppConstants {
  static const String mockApiBaseUrl =
      'https://6939834cc8d59937aa082275.mockapi.io';

  static const String usersEndpoint = '/project';
  static const String ridesEndpoint = '/image';
  static const String reviewsEndpoint = '/reviews';
  static const String complaintsEndpoint = '/complaints';

  static const double boardingFee = 500.0;
  static const double pricePerKm = 150.0;
  static const double minPrice = 700.0;

  static const double deliveryFee = 400.0;

  static const Duration pollingInterval = Duration(seconds: 3);

  static const String keyUserId = 'user_id';
  static const String keyFirebaseUid = 'firebase_uid';

  static const Duration reviewEditWindow = Duration(minutes: 10);
}

class TestAccounts {

  static const passenger1 = TestAccount(
    email: 'passenger1@taxi.test',
    password: 'test123456',
    name: 'Айгуль (тест)',
    role: 'passenger',
  );

  static const passenger2 = TestAccount(
    email: 'passenger2@taxi.test',
    password: 'test123456',
    name: 'Данияр (тест)',
    role: 'passenger',
  );

  static const driver1 = TestAccount(
    email: 'driver1@taxi.test',
    password: 'test123456',
    name: 'Иван Петров (тест)',
    role: 'driver',
    carModel: 'Toyota Camry',
    carNumber: '123 ABC 01',
  );

  static const driver2 = TestAccount(
    email: 'driver2@taxi.test',
    password: 'test123456',
    name: 'Марат Алиев (тест)',
    role: 'driver',
    carModel: 'Hyundai Accent',
    carNumber: '456 XYZ 02',
  );

  static const admin = TestAccount(
    email: 'admin@taxi.test',
    password: 'admin123456',
    name: 'Администратор',
    role: 'admin',
  );

  static const List<TestAccount> passengers = [passenger1, passenger2];
  static const List<TestAccount> drivers = [driver1, driver2];
  static const List<TestAccount> admins = [admin];
}

class TestAccount {
  final String email;
  final String password;
  final String name;
  final String role;
  final String carModel;
  final String carNumber;

  const TestAccount({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.carModel = '',
    this.carNumber = '',
  });
}
