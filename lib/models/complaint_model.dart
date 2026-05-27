class ComplaintStatus {
  static const String pending = 'pending'; 
  static const String resolved = 'resolved'; 
  static const String rejected = 'rejected'; 

  static String label(String status) {
    switch (status) {
      case pending:
        return 'Новая';
      case resolved:
        return 'Решена';
      case rejected:
        return 'Отклонена';
      default:
        return status;
    }
  }
}

class ComplaintModel {
  final String id;
  final String rideId;
  final String fromUserId; 
  final String fromUserName;
  final String fromUserRole; 
  final String againstUserId; 
  final String againstUserName;
  final String reason; 
  final String description; 
  final String status; 
  final String adminResponse; 
  final double refundAmount; 
  final bool refundProcessed; 
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  ComplaintModel({
    required this.id,
    required this.rideId,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserRole,
    this.againstUserId = '',
    this.againstUserName = '',
    required this.reason,
    required this.description,
    this.status = ComplaintStatus.pending,
    this.adminResponse = '',
    this.refundAmount = 0,
    this.refundProcessed = false,
    this.createdAt,
    this.resolvedAt,
  });

  bool get isPending => status == ComplaintStatus.pending;
  bool get isResolved => status == ComplaintStatus.resolved;
  bool get isRejected => status == ComplaintStatus.rejected;

  static double _doubleFrom(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id']?.toString() ?? '',
      rideId: json['rideId']?.toString() ?? '',
      fromUserId: json['fromUserId']?.toString() ?? '',
      fromUserName: json['fromUserName']?.toString() ?? '',
      fromUserRole: json['fromUserRole']?.toString() ?? 'passenger',
      againstUserId: json['againstUserId']?.toString() ?? '',
      againstUserName: json['againstUserName']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? ComplaintStatus.pending,
      adminResponse: json['adminResponse']?.toString() ?? '',
      refundAmount: _doubleFrom(json['refundAmount']),
      refundProcessed: json['refundProcessed'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rideId': rideId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserRole': fromUserRole,
      'againstUserId': againstUserId,
      'againstUserName': againstUserName,
      'reason': reason,
      'description': description,
      'status': status,
      'adminResponse': adminResponse,
      'refundAmount': refundAmount,
      'refundProcessed': refundProcessed,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
    };
  }
}
