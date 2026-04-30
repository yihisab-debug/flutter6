import '../core/api_client.dart';
import '../core/app_constants.dart';
import '../models/ride_model.dart';
import 'user_repository.dart';

class ReviewSortMode {
  static const String dateDesc = 'date_desc';
  static const String dateAsc = 'date_asc';
  static const String ratingDesc = 'rating_desc';
  static const String ratingAsc = 'rating_asc';
}

class ReviewFilter {
  static const String all = 'all';
  static const String positive = 'positive';
  static const String negative = 'negative';
}

class ReviewItem {
  final String rideId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;

  const ReviewItem({
    required this.rideId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
  });

  bool get isPositive => rating >= 4;
  bool get isNegative => rating <= 2;
}

class ReviewRepository {
  final _dio = ApiClient().dio;
  final _userRepo = UserRepository();
  final _endpoint = AppConstants.ridesEndpoint;

  Future<RideModel> reloadRide(String rideId) async {
    final response = await _dio.get('$_endpoint/$rideId');
    return RideModel.fromJson(response.data);
  }

  Future<RideModel> savePassengerReview({
    required RideModel ride,
    required int rating,
    required String comment,
  }) async {
    if (ride.status != RideStatus.completed) {
      throw Exception('Отзыв доступен только после завершения поездки');
    }
    if (ride.hasPassengerReview && !ride.isPassengerReviewEditable) {
      throw Exception(
        'Отзыв можно редактировать только в течение 10 минут после создания',
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final reviewAt = ride.hasPassengerReview ? ride.passengerReviewAt : now;

    final response = await _dio.put(
      '$_endpoint/${ride.id}',
      data: {
        'passengerRating': rating,
        'passengerComment': comment,
        'passengerReviewAt': reviewAt,
      },
    );

    final updated = RideModel.fromJson(response.data);
    await _recalculateUserRating(ride.driverId);
    return updated;
  }

  Future<RideModel> saveDriverReview({
    required RideModel ride,
    required int rating,
    required String comment,
  }) async {
    if (ride.status != RideStatus.completed) {
      throw Exception('Отзыв доступен только после завершения поездки');
    }
    if (ride.hasDriverReview && !ride.isDriverReviewEditable) {
      throw Exception(
        'Отзыв можно редактировать только в течение 10 минут после создания',
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final reviewAt = ride.hasDriverReview ? ride.driverReviewAt : now;

    final response = await _dio.put(
      '$_endpoint/${ride.id}',
      data: {
        'driverRating': rating,
        'driverComment': comment,
        'driverReviewAt': reviewAt,
      },
    );

    final updated = RideModel.fromJson(response.data);
    await _recalculateUserRating(ride.passengerId);
    return updated;
  }

  Future<List<ReviewItem>> getReviewsForUser(
    String userId, {
    String sort = ReviewSortMode.dateDesc,
    String filter = ReviewFilter.all,
  }) async {
    final items = <ReviewItem>[];

    final asPassenger = await _dio.get(
      _endpoint,
      queryParameters: {'passengerId': userId},
    );
    for (final raw in (asPassenger.data as List)) {
      final ride = RideModel.fromJson(raw);
      if (ride.hasDriverReview) {
        items.add(ReviewItem(
          rideId: ride.id,
          rating: ride.driverRating,
          comment: ride.driverComment,
          createdAt: ride.driverReviewDate ?? DateTime.now(),
          fromUserId: ride.driverId,
          fromUserName: ride.driverName,
          toUserId: ride.passengerId,
        ));
      }
    }

    final asDriver = await _dio.get(
      _endpoint,
      queryParameters: {'driverId': userId},
    );
    for (final raw in (asDriver.data as List)) {
      final ride = RideModel.fromJson(raw);
      if (ride.hasPassengerReview) {
        items.add(ReviewItem(
          rideId: ride.id,
          rating: ride.passengerRating,
          comment: ride.passengerComment,
          createdAt: ride.passengerReviewDate ?? DateTime.now(),
          fromUserId: ride.passengerId,
          fromUserName: ride.passengerName,
          toUserId: ride.driverId,
        ));
      }
    }

    var result = _applyFilter(items, filter);
    _applySort(result, sort);
    return result;
  }

  Future<void> _recalculateUserRating(String userId) async {
    if (userId.isEmpty) return;
    try {
      final reviews = await getReviewsForUser(userId);
      if (reviews.isEmpty) {
        await _userRepo.updateRating(userId, rating: 0, ratingCount: 0);
        return;
      }
      final sum = reviews.fold<int>(0, (acc, r) => acc + r.rating);
      final avg = sum / reviews.length;
      final rounded = double.parse(avg.toStringAsFixed(2));
      await _userRepo.updateRating(
        userId,
        rating: rounded,
        ratingCount: reviews.length,
      );
    } catch (_) {}
  }

  static const _toxicWords = [
    'дурак', 'идиот', 'тупой', 'мразь', 'fuck', 'shit',
  ];

  bool _looksToxic(ReviewItem r) {
    final text = r.comment.toLowerCase();
    return _toxicWords.any((w) => text.contains(w));
  }

  List<ReviewItem> _applyFilter(List<ReviewItem> reviews, String filter) {
    var result = reviews.where((r) => !_looksToxic(r)).toList();

    switch (filter) {
      case ReviewFilter.positive:
        return result.where((r) => r.isPositive).toList();
      case ReviewFilter.negative:
        return result.where((r) => r.isNegative).toList();
      case ReviewFilter.all:
      default:
        return result;
    }
  }

  void _applySort(List<ReviewItem> reviews, String sort) {
    int cmpDate(ReviewItem a, ReviewItem b) =>
        a.createdAt.compareTo(b.createdAt);

    switch (sort) {
      case ReviewSortMode.dateAsc:
        reviews.sort(cmpDate);
        break;
      case ReviewSortMode.ratingDesc:
        reviews.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ReviewSortMode.ratingAsc:
        reviews.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case ReviewSortMode.dateDesc:
      default:
        reviews.sort((a, b) => cmpDate(b, a));
    }
  }
}
