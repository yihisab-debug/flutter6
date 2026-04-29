import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/app_constants.dart';
import '../models/user_model.dart';

class UserRepository {
  final _dio = ApiClient().dio;
  final _endpoint = AppConstants.usersEndpoint;

  Future<UserModel> createUser(UserModel user) async {
    final response = await _dio.post(_endpoint, data: user.toJson());
    return UserModel.fromJson(response.data);
  }

  Future<UserModel?> getUserByFirebaseUid(String firebaseUid) async {
    try {
      final response = await _dio.get(
        _endpoint,
        queryParameters: {'firebaseUid': firebaseUid},
      );

      final list = response.data as List;
      if (list.isEmpty) return null;
      return UserModel.fromJson(list.first);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<UserModel> getUserById(String id) async {
    final response = await _dio.get('$_endpoint/$id');
    return UserModel.fromJson(response.data);
  }

  Future<UserModel> updateBalance(String id, double newBalance) async {
    final response = await _dio.put(
      '$_endpoint/$id',
      data: {'balance': newBalance},
    );
    return UserModel.fromJson(response.data);
  }

  Future<UserModel> updateAvailability(String id, bool isAvailable) async {
    final response = await _dio.put(
      '$_endpoint/$id',
      data: {'isAvailable': isAvailable},
    );
    return UserModel.fromJson(response.data);
  }

  Future<UserModel> updateRating(
    String id, {
    required double rating,
    required int ratingCount,
  }) async {
    final response = await _dio.put(
      '$_endpoint/$id',
      data: {
        'rating': rating,
        'ratingCount': ratingCount,
      },
    );
    return UserModel.fromJson(response.data);
  }

  Future<List<UserModel>> getDrivers({double minRating = 0}) async {
    final response = await _dio.get(
      _endpoint,
      queryParameters: {'role': 'driver'},
    );
    final list = (response.data as List)
        .map((e) => UserModel.fromJson(e))
        .where((u) => u.rating >= minRating)
        .toList();
    list.sort((a, b) => b.rating.compareTo(a.rating));
    return list;
  }
}
