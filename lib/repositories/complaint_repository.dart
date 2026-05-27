import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/app_constants.dart';
import '../models/complaint_model.dart';

class ComplaintRepository {
  final _dio = ApiClient().dio;

  final _endpoint = AppConstants.usersEndpoint;

  static const _complaintRole = 'complaint';

  Future<ComplaintModel> createComplaint(ComplaintModel complaint) async {

    
    final payload = {

      'name': '[Жалоба] ${complaint.reason}',
      'email': '',
      'role': _complaintRole,
      'balance': 0,
      'firebaseUid': '',
      'carModel': '',
      'carNumber': '',
      'rating': 0,
      'ratingCount': 0,
      'isAvailable': false,
      'isBlocked': false,

      ...complaint.toJson(),
      'role': _complaintRole, 
    };

    final response = await _dio.post(_endpoint, data: payload);
    return ComplaintModel.fromJson(response.data);
  }

  Future<List<ComplaintModel>> getAllComplaints({String? status}) async {
    try {
      final response = await _dio.get(
        _endpoint,
        queryParameters: {
          'role': _complaintRole,
          if (status != null) 'status': status,
        },
      );
      final list = (response.data as List)
          .where((e) => e is Map && e['role'] == _complaintRole)
          .map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _sortByCreated(list);
      return list;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<List<ComplaintModel>> getComplaintsByUser(String userId) async {
    try {
      final response = await _dio.get(
        _endpoint,
        queryParameters: {
          'role': _complaintRole,
          'fromUserId': userId,
        },
      );
      final list = (response.data as List)
          .where((e) =>
              e is Map &&
              e['role'] == _complaintRole &&
              e['fromUserId']?.toString() == userId)
          .map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _sortByCreated(list);
      return list;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<List<ComplaintModel>> getComplaintsAgainstUser(String userId) async {
    try {
      final response = await _dio.get(
        _endpoint,
        queryParameters: {
          'role': _complaintRole,
          'againstUserId': userId,
        },
      );
      final list = (response.data as List)
          .where((e) =>
              e is Map &&
              e['role'] == _complaintRole &&
              e['againstUserId']?.toString() == userId)
          .map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _sortByCreated(list);
      return list;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<ComplaintModel> resolveComplaint({
    required String complaintId,
    required String adminResponse,
    required bool approved,
    double refundAmount = 0,
    bool refundProcessed = false,
  }) async {
    final response = await _dio.put(
      '$_endpoint/$complaintId',
      data: {
        'status': approved
            ? ComplaintStatus.resolved
            : ComplaintStatus.rejected,
        'adminResponse': adminResponse,
        'refundAmount': refundAmount,
        'refundProcessed': refundProcessed,
        'resolvedAt': DateTime.now().toIso8601String(),
      },
    );
    return ComplaintModel.fromJson(response.data);
  }

  Future<ComplaintModel?> getById(String id) async {
    try {
      final response = await _dio.get('$_endpoint/$id');
      return ComplaintModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  void _sortByCreated(List<ComplaintModel> list) {
    list.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(2000);
      final bDate = b.createdAt ?? DateTime(2000);
      return bDate.compareTo(aDate); 
    });
  }
}
