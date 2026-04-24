import '../core/api_client.dart';
import '../core/app_constants.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

class RideRepository {
  final _dio = ApiClient().dio;
  final _userRepo = UserRepository();
  final _endpoint = AppConstants.ridesEndpoint;

  Future<RideModel> createRide(RideModel ride) async {
    final response = await _dio.post(_endpoint, data: ride.toJson());
    return RideModel.fromJson(response.data);
  }

  Future<RideModel> getRide(String id) async {
    final response = await _dio.get('$_endpoint/$id');
    return RideModel.fromJson(response.data);
  }

  Future<List<RideModel>> getAvailableRides() async {
    final response = await _dio.get(
      _endpoint,
      queryParameters: {
        'status': RideStatus.searching,
        'sortBy': 'createdAt',
        'order': 'desc',
      },
    );

    final list = response.data as List;
    return list.map((e) => RideModel.fromJson(e)).toList();
  }

  Future<List<RideModel>> getPassengerHistory(String passengerId) async {
    final response = await _dio.get(
      _endpoint,
      queryParameters: {
        'passengerId': passengerId,
        'sortBy': 'createdAt',
        'order': 'desc',
      },
    );

    final list = response.data as List;
    return list.map((e) => RideModel.fromJson(e)).toList();
  }

  Future<List<RideModel>> getDriverHistory(String driverId) async {
    final response = await _dio.get(
      _endpoint,
      queryParameters: {
        'driverId': driverId,
        'sortBy': 'createdAt',
        'order': 'desc',
      },
    );

    final list = response.data as List;
    return list.map((e) => RideModel.fromJson(e)).toList();
  }

  Future<RideModel?> getActiveRideForPassenger(String passengerId) async {
    final response = await _dio.get(
      _endpoint,
      queryParameters: {'passengerId': passengerId},
    );

    final list = response.data as List;
    for (final item in list) {
      final ride = RideModel.fromJson(item);
      if (ride.status != RideStatus.completed &&
          ride.status != RideStatus.cancelled) {
        return ride;
      }
    }
    return null;
  }

  Future<RideModel?> getActiveRideForDriver(String driverId) async {
    final response = await _dio.get(
      _endpoint,
      queryParameters: {'driverId': driverId},
    );

    final list = response.data as List;
    for (final item in list) {
      final ride = RideModel.fromJson(item);
      if (ride.status == RideStatus.accepted ||
          ride.status == RideStatus.inProgress) {
        return ride;
      }
    }
    return null;
  }

  Future<RideModel> acceptRide(String rideId, UserModel driver) async {
    final response = await _dio.put(
      '$_endpoint/$rideId',
      data: {
        'driverId': driver.id,
        'driverName': driver.name,
        'carInfo': driver.carInfo,
        'status': RideStatus.accepted,
      },
    );
    return RideModel.fromJson(response.data);
  }

  Future<RideModel> startRide(String rideId) async {
    final response = await _dio.put(
      '$_endpoint/$rideId',
      data: {'status': RideStatus.inProgress},
    );
    return RideModel.fromJson(response.data);
  }

  Future<RideModel> completeRide(RideModel ride) async {
    final passenger = await _userRepo.getUserById(ride.passengerId);
    await _userRepo.updateBalance(
      passenger.id,
      passenger.balance - ride.price,
    );

    final driver = await _userRepo.getUserById(ride.driverId);
    await _userRepo.updateBalance(
      driver.id,
      driver.balance + ride.price,
    );

    final response = await _dio.put(
      '$_endpoint/${ride.id}',
      data: {'status': RideStatus.completed},
    );
    return RideModel.fromJson(response.data);
  }

  Future<RideModel> cancelRide(String rideId) async {
    final response = await _dio.put(
      '$_endpoint/$rideId',
      data: {'status': RideStatus.cancelled},
    );
    return RideModel.fromJson(response.data);
  }
}
