import 'package:dio/dio.dart';
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
  final String fromUserId;
  final String toUserId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String fromRole;

  ReviewItem({
    required this.rideId,
    required this.fromUserId,
    required this.toUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.fromRole,
  });

  bool get isPositive => rating >= 4;
  bool get isNegative => rating <= 2;
}

class ReviewRepository {
  final _dio = ApiClient().dio;
  final _userRepo = UserRepository();
  final _ridesEndpoint = AppConstants.ridesEndpoint;

  Never _friendly(DioException e, String action) {
    final code = e.response?.statusCode;
    if (code == 400) {
      throw Exception(
        'Сервер отклонил запрос ($action). В ресурсе image должны быть '
        'поля: passengerRating, passengerComment, passengerReviewAt, '
        'driverRating, driverComment, driverReviewAt.',
      );
    }
    if (code == 404) {
      throw Exception('Поездка не найдена');
    }
    throw Exception('Ошибка сервера ($action): ${e.message}');
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

    final ts = ride.hasPassengerReview
        ? ride.passengerReviewAt
        : DateTime.now().millisecondsSinceEpoch;

    try {
      final response = await _dio.put(
        '$_ridesEndpoint/${ride.id}',
        data: {
          'passengerRating': rating,
          'passengerComment': comment,
          'passengerReviewAt': ts,
        },
      );
      final updated = RideModel.fromJson(response.data);
      await _recalculateUserRating(ride.driverId);
      return updated;
    } on DioException catch (e) {
      _friendly(e, 'отправке отзыва');
    }
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

    final ts = ride.hasDriverReview
        ? ride.driverReviewAt
        : DateTime.now().millisecondsSinceEpoch;

    try {
      final response = await _dio.put(
        '$_ridesEndpoint/${ride.id}',
        data: {
          'driverRating': rating,
          'driverComment': comment,
          'driverReviewAt': ts,
        },
      );
      final updated = RideModel.fromJson(response.data);
      await _recalculateUserRating(ride.passengerId);
      return updated;
    } on DioException catch (e) {
      _friendly(e, 'отправке отзыва');
    }
  }

  Future<RideModel> reloadRide(String rideId) async {
    try {
      final response = await _dio.get('$_ridesEndpoint/$rideId');
      return RideModel.fromJson(response.data);
    } on DioException catch (e) {
      _friendly(e, 'загрузке поездки');
    }
  }

  Future<List<ReviewItem>> getReviewsForUser(
    String userId, {
    String sort = ReviewSortMode.dateDesc,
    String filter = ReviewFilter.all,
  }) async {
    List asDriver = [];
    List asPassenger = [];

    try {
      final r = await _dio.get(
        _ridesEndpoint,
        queryParameters: {'driverId': userId},
      );
      asDriver = r.data as List;
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
    }

    try {
      final r = await _dio.get(
        _ridesEndpoint,
        queryParameters: {'passengerId': userId},
      );
      asPassenger = r.data as List;
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
    }

    final result = <ReviewItem>[];

    for (final item in asDriver) {
      final ride = RideModel.fromJson(item);
      if (ride.hasPassengerReview && ride.driverId == userId) {
        result.add(ReviewItem(
          rideId: ride.id,
          fromUserId: ride.passengerId,
          toUserId: ride.driverId,
          rating: ride.passengerRating,
          comment: ride.passengerComment,
          createdAt: ride.passengerReviewDate!,
          fromRole: 'passenger',
        ));
      }
    }

    for (final item in asPassenger) {
      final ride = RideModel.fromJson(item);
      if (ride.hasDriverReview && ride.passengerId == userId) {
        result.add(ReviewItem(
          rideId: ride.id,
          fromUserId: ride.driverId,
          toUserId: ride.passengerId,
          rating: ride.driverRating,
          comment: ride.driverComment,
          createdAt: ride.driverReviewDate!,
          fromRole: 'driver',
        ));
      }
    }

    var filtered = result.where((r) => !_looksToxic(r.comment)).toList();

    switch (filter) {
      case ReviewFilter.positive:
        filtered = filtered.where((r) => r.isPositive).toList();
        break;
      case ReviewFilter.negative:
        filtered = filtered.where((r) => r.isNegative).toList();
        break;
    }

    switch (sort) {
      case ReviewSortMode.dateAsc:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case ReviewSortMode.ratingDesc:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ReviewSortMode.ratingAsc:
        filtered.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case ReviewSortMode.dateDesc:
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filtered;
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

  bool _looksToxic(String text) {
    final t = text.toLowerCase();
    return _toxicWords.any((w) => t.contains(w));
  }
}
