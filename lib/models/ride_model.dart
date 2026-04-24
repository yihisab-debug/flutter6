class RideStatus {
  static const String searching = 'searching';
  static const String accepted = 'accepted';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static String label(String status) {
    switch (status) {
      case searching:
        return 'Поиск водителя';
      case accepted:
        return 'Водитель едет к вам';
      case inProgress:
        return 'В пути';
      case completed:
        return 'Завершена';
      case cancelled:
        return 'Отменена';
      default:
        return status;
    }
  }
}

class RideModel {
  final String id;
  final String passengerId;
  final String passengerName;
  final String driverId;
  final String driverName;
  final String carInfo;
  final String fromAddress;
  final String toAddress;
  final double price;
  final String status;
  final DateTime? createdAt;

  RideModel({
    required this.id,
    required this.passengerId,
    required this.passengerName,
    this.driverId = '',
    this.driverName = '',
    this.carInfo = '',
    required this.fromAddress,
    required this.toAddress,
    required this.price,
    required this.status,
    this.createdAt,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id']?.toString() ?? '',
      passengerId: json['passengerId'] ?? '',
      passengerName: json['passengerName'] ?? '',
      driverId: json['driverId'] ?? '',
      driverName: json['driverName'] ?? '',
      carInfo: json['carInfo'] ?? '',
      fromAddress: json['fromAddress'] ?? '',
      toAddress: json['toAddress'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      status: json['status'] ?? RideStatus.searching,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'passengerId': passengerId,
      'passengerName': passengerName,
      'driverId': driverId,
      'driverName': driverName,
      'carInfo': carInfo,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'price': price,
      'status': status,
    };
  }
}
