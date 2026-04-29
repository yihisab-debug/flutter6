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

  final int passengerRating;
  final String passengerComment;
  final int passengerReviewAt;

  final int driverRating;
  final String driverComment;
  final int driverReviewAt;

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
    this.passengerRating = 0,
    this.passengerComment = '',
    this.passengerReviewAt = 0,
    this.driverRating = 0,
    this.driverComment = '',
    this.driverReviewAt = 0,
  });

  bool get hasPassengerReview => passengerRating > 0;
  bool get hasDriverReview => driverRating > 0;

  bool get isPassengerReviewEditable {
    if (passengerReviewAt == 0) return false;
    final created = DateTime.fromMillisecondsSinceEpoch(passengerReviewAt);
    return DateTime.now().difference(created).inMinutes < 10;
  }

  bool get isDriverReviewEditable {
    if (driverReviewAt == 0) return false;
    final created = DateTime.fromMillisecondsSinceEpoch(driverReviewAt);
    return DateTime.now().difference(created).inMinutes < 10;
  }

  DateTime? get passengerReviewDate => passengerReviewAt == 0
      ? null
      : DateTime.fromMillisecondsSinceEpoch(passengerReviewAt);

  DateTime? get driverReviewDate => driverReviewAt == 0
      ? null
      : DateTime.fromMillisecondsSinceEpoch(driverReviewAt);

  static int _intFrom(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

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
      passengerRating: _intFrom(json['passengerRating']),
      passengerComment: json['passengerComment']?.toString() ?? '',
      passengerReviewAt: _intFrom(json['passengerReviewAt']),
      driverRating: _intFrom(json['driverRating']),
      driverComment: json['driverComment']?.toString() ?? '',
      driverReviewAt: _intFrom(json['driverReviewAt']),
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
      'passengerRating': passengerRating,
      'passengerComment': passengerComment,
      'passengerReviewAt': passengerReviewAt,
      'driverRating': driverRating,
      'driverComment': driverComment,
      'driverReviewAt': driverReviewAt,
    };
  }
}
