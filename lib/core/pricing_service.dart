import 'dart:math' as math;
import '../models/location_model.dart';
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

  static double price(double distanceKm) {
    return AppConstants.basePrice + distanceKm * AppConstants.pricePerKm;
  }

  static TripEstimate estimate(LocationModel from, LocationModel to) {
    final d = distanceKm(from, to);
    return TripEstimate(distanceKm: d, price: price(d));
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;
}

class TripEstimate {
  final double distanceKm;
  final double price;

  const TripEstimate({required this.distanceKm, required this.price});
}
