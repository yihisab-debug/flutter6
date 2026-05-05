class RideType {
  static const String taxi = 'taxi';
  static const String delivery = 'delivery';

  static String label(String type) {
    switch (type) {
      case taxi:
        return 'Такси';
      case delivery:
        return 'Доставка';
      default:
        return type;
    }
  }
}

class RideStatus {
  static const String searching = 'searching';
  static const String accepted = 'accepted';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const String pickedUp = 'picked_up';
  static const String delivered = 'delivered';

  static String label(String status) {
    switch (status) {
      case searching:
        return 'Поиск водителя';
      case accepted:
        return 'Водитель в пути';
      case inProgress:
        return 'В пути';
      case pickedUp:
        return 'Посылка забрана';
      case delivered:
        return 'Доставлена';
      case completed:
        return 'Завершена';
      case cancelled:
        return 'Отменена';
      default:
        return status;
    }
  }

  static String labelForType(String status, String type) {
    if (type == RideType.delivery) {
      switch (status) {
        case accepted:
          return 'Курьер едет за посылкой';
        case inProgress:
          return 'Курьер забирает посылку';
        case pickedUp:
          return 'Посылка в пути';
        case delivered:
          return 'Посылка доставлена';
      }
    } else {
      switch (status) {
        case accepted:
          return 'Водитель едет к вам';
        case inProgress:
          return 'В пути';
      }
    }
    return label(status);
  }
}

class RideModel {
  final String id;
  final String type;
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

  final String senderName;
  final String receiverName;
  final String receiverPhone;
  final String packageDescription;
  final double weight;
  final double deliveryFee;

  final int passengerRating;
  final String passengerComment;
  final int passengerReviewAt;

  final int driverRating;
  final String driverComment;
  final int driverReviewAt;

  RideModel({
    required this.id,
    this.type = RideType.taxi,
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
    this.senderName = '',
    this.receiverName = '',
    this.receiverPhone = '',
    this.packageDescription = '',
    this.weight = 0,
    this.deliveryFee = 0,
    this.passengerRating = 0,
    this.passengerComment = '',
    this.passengerReviewAt = 0,
    this.driverRating = 0,
    this.driverComment = '',
    this.driverReviewAt = 0,
  });

  bool get isDelivery => type == RideType.delivery;
  bool get isTaxi => type == RideType.taxi;

  bool get isFinished {
    if (isDelivery) {
      return status == RideStatus.delivered ||
          status == RideStatus.completed ||
          status == RideStatus.cancelled;
    }
    return status == RideStatus.completed || status == RideStatus.cancelled;
  }

  bool get isSuccessfullyCompleted {
    if (isDelivery) {
      return status == RideStatus.delivered || status == RideStatus.completed;
    }
    return status == RideStatus.completed;
  }

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

  static double _doubleFrom(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id']?.toString() ?? '',
      type: (json['type']?.toString().isNotEmpty ?? false)
          ? json['type'].toString()
          : RideType.taxi,
      passengerId: json['passengerId'] ?? '',
      passengerName: json['passengerName'] ?? '',
      driverId: json['driverId'] ?? '',
      driverName: json['driverName'] ?? '',
      carInfo: json['carInfo'] ?? '',
      fromAddress: json['fromAddress'] ?? '',
      toAddress: json['toAddress'] ?? '',
      price: _doubleFrom(json['price']),
      status: json['status'] ?? RideStatus.searching,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      senderName: json['senderName']?.toString() ?? '',
      receiverName: json['receiverName']?.toString() ?? '',
      receiverPhone: json['receiverPhone']?.toString() ?? '',
      packageDescription: json['packageDescription']?.toString() ?? '',
      weight: _doubleFrom(json['weight']),
      deliveryFee: _doubleFrom(json['deliveryFee']),
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
      'type': type,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'driverId': driverId,
      'driverName': driverName,
      'carInfo': carInfo,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'price': price,
      'status': status,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'senderName': senderName,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'packageDescription': packageDescription,
      'weight': weight,
      'deliveryFee': deliveryFee,
      'passengerRating': passengerRating,
      'passengerComment': passengerComment,
      'passengerReviewAt': passengerReviewAt,
      'driverRating': driverRating,
      'driverComment': driverComment,
      'driverReviewAt': driverReviewAt,
    };
  }
}
