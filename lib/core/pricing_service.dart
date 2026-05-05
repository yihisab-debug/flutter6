import 'dart:math' as math;
import '../models/location_model.dart';
import '../models/ride_model.dart';
import 'app_constants.dart';

class PricingService {
  PricingService._();

  static const double _earthRadiusKm = 6371.0;

  static double distanceKm(LocationModel from, LocationModel to) {
    final lat1 = _toRad(from.latitude);
    final lat2 = _toRad(to.latitude);
    final dLat = _toRad(to.latitude - from.latitude);
    final dLon = _toRad(to.longitude - from.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  static double _basicPrice(double distanceKm) {
    final calculated =
        AppConstants.boardingFee + distanceKm * AppConstants.pricePerKm;
    return calculated < AppConstants.minPrice
        ? AppConstants.minPrice
        : calculated;
  }

  static double price(double distanceKm, {String type = RideType.taxi}) {
    final base = _basicPrice(distanceKm);
    if (type == RideType.delivery) {
      return base + AppConstants.deliveryFee;
    }
    return base;
  }

  static TripEstimate estimate(
    LocationModel from,
    LocationModel to, {
    String type = RideType.taxi,
  }) {
    final d = distanceKm(from, to);
    final basic = _basicPrice(d);
    final isDelivery = type == RideType.delivery;
    return TripEstimate(
      type: type,
      distanceKm: d,
      price: isDelivery ? basic + AppConstants.deliveryFee : basic,
      boardingFee: AppConstants.boardingFee,
      perKm: AppConstants.pricePerKm,
      deliveryFee: isDelivery ? AppConstants.deliveryFee : 0,
    );
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;
}

class TripEstimate {
  final String type;
  final double distanceKm;
  final double price;
  final double boardingFee;
  final double perKm;
  final double deliveryFee;

  const TripEstimate({
    required this.type,
    required this.distanceKm,
    required this.price,
    required this.boardingFee,
    required this.perKm,
    this.deliveryFee = 0,
  });

  bool get isDelivery => type == RideType.delivery;
}
