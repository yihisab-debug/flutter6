import 'package:dio/dio.dart';
import 'app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.mockApiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('[API] $obj'),
      ),
    );
  }
}
