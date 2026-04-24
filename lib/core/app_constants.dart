class AppConstants {
  static const String mockApiBaseUrl =
      'https://6939834cc8d59937aa082275.mockapi.io';

  static const String usersEndpoint = '/project';
  static const String ridesEndpoint = '/image';

  static const double basePrice = 500.0;
  static const double pricePerKm = 150.0;
  static const double minDistance = 2.0;
  static const double maxDistance = 20.0;

  static const Duration pollingInterval = Duration(seconds: 3);

  static const String keyUserId = 'user_id';
  static const String keyFirebaseUid = 'firebase_uid';
}
