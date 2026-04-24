class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final double balance;
  final String firebaseUid;
  final String carModel;
  final String carNumber;
  final double rating;
  final bool isAvailable;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.balance,
    required this.firebaseUid,
    this.carModel = '',
    this.carNumber = '',
    this.rating = 0,
    this.isAvailable = true,
    this.createdAt,
  });

  bool get isDriver => role == 'driver';
  bool get isPassenger => role == 'passenger';

  String get carInfo {
    if (!isDriver) return '';
    return '$carModel, $carNumber';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'passenger',
      balance: (json['balance'] ?? 0).toDouble(),
      firebaseUid: json['firebaseUid'] ?? '',
      carModel: json['carModel'] ?? '',
      carNumber: json['carNumber'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      isAvailable: json['isAvailable'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'balance': balance,
      'firebaseUid': firebaseUid,
      'carModel': carModel,
      'carNumber': carNumber,
      'rating': rating,
      'isAvailable': isAvailable,
    };
  }

  UserModel copyWith({
    double? balance,
    String? carModel,
    String? carNumber,
    bool? isAvailable,
  }) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      role: role,
      balance: balance ?? this.balance,
      firebaseUid: firebaseUid,
      carModel: carModel ?? this.carModel,
      carNumber: carNumber ?? this.carNumber,
      rating: rating,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
    );
  }
}
