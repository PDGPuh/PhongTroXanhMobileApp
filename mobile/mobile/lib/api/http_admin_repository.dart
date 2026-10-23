import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/async_resource.dart';
import 'api_config.dart';

class AdminDashboardData {
  final int totalUsers;
  final int totalLandlords;
  final int totalTenants;
  final int totalRooms;
  final int activeRooms;
  final int pendingKycCount;
  final int pendingDisputesCount;
  final double totalRevenue;
  final int totalMatches;

  AdminDashboardData({
    required this.totalUsers,
    required this.totalLandlords,
    required this.totalTenants,
    required this.totalRooms,
    required this.activeRooms,
    required this.pendingKycCount,
    required this.pendingDisputesCount,
    required this.totalRevenue,
    required this.totalMatches,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    return AdminDashboardData(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalLandlords: (json['totalLandlords'] as num?)?.toInt() ?? 0,
      totalTenants: (json['totalTenants'] as num?)?.toInt() ?? 0,
      totalRooms: (json['totalRooms'] as num?)?.toInt() ?? 0,
      activeRooms: (json['activeRooms'] as num?)?.toInt() ?? 0,
      pendingKycCount: (json['pendingKycCount'] as num?)?.toInt() ?? 0,
      pendingDisputesCount: (json['pendingDisputesCount'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalMatches: (json['totalMatches'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminKycItem {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String idCardNumber;
  final String frontUrl;
  final String backUrl;
  final String status;
  final String? createdAt;

  AdminKycItem({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.idCardNumber,
    required this.frontUrl,
    required this.backUrl,
    required this.status,
    this.createdAt,
  });

  factory AdminKycItem.fromJson(Map<String, dynamic> json) {
    return AdminKycItem(
      id: (json['verificationId'] ?? json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      fullName: (json['userFullName'] ?? json['fullName'] ?? 'Người dùng').toString(),
      email: (json['userEmail'] ?? json['email'] ?? '').toString(),
      phone: (json['userPhone'] ?? json['phoneNumber'] ?? '').toString(),
      role: (json['userRole'] ?? 'TENANT').toString(),
      idCardNumber: (json['idCardNumberDecrypted'] ?? json['idCardNumber'] ?? '***').toString(),
      frontUrl: (json['idCardFrontUrl'] ?? '').toString(),
      backUrl: (json['idCardBackUrl'] ?? '').toString(),
      status: switch ((json['status'] ?? 'PENDING').toString().toUpperCase()) {
        'APPROVED' => 'Đã xác minh',
        'REJECTED' => 'Đã từ chối',
        _ => 'Chờ duyệt',
      },
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class AdminReportItem {
  final String id;
  final String reporterId;
  final String targetType;
  final String targetId;
  final String reason;
  final String details;
  final List<String> evidenceImages;
  final String status;
  final String severity;
  final String? createdAt;

  AdminReportItem({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.details,
    required this.evidenceImages,
    required this.status,
    required this.severity,
    this.createdAt,
  });

  factory AdminReportItem.fromJson(Map<String, dynamic> json) {
    final images = (json['evidenceImages'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final rawStatus = (json['status'] ?? 'PENDING').toString().toUpperCase();
    return AdminReportItem(
      id: (json['id'] ?? '').toString(),
      reporterId: (json['reporterId'] ?? '').toString(),
      targetType: (json['targetType'] ?? 'ROOM').toString(),
      targetId: (json['targetId'] ?? '').toString(),
      reason: (json['reportType'] ?? json['reason'] ?? 'Báo cáo vi phạm').toString(),
      details: (json['detail'] ?? json['details'] ?? '').toString(),
      evidenceImages: images,
      status: switch (rawStatus) {
        'RESOLVED' => 'Đã xử lý',
        'DISMISSED' => 'Đã bỏ qua',
        _ => 'Chờ xử lý',
      },
      severity: (json['severity'] ?? 'NORMAL').toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class AdminUserItem {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final String? avatarUrl;
  final String role;
  final String status;
  final int trustScore;
  final bool isVerified;
  final String? createdAt;

  AdminUserItem({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    required this.status,
    required this.trustScore,
    required this.isVerified,
    this.createdAt,
  });

  factory AdminUserItem.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? 'ACTIVE').toString().toUpperCase();
    return AdminUserItem(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phoneNumber'] ?? json['phone'] ?? '').toString(),
      fullName: (json['fullName'] ?? 'Người dùng').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      role: (json['role'] ?? 'TENANT').toString(),
      status: rawStatus == 'LOCKED' ? 'Đã khóa' : 'Hoạt động',
      trustScore: (json['trustScore'] as num?)?.toInt() ?? 50,
      isVerified: json['isVerified'] == true,
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class AdminRoomItem {
  final String id;
  final String landlordId;
  final String title;
  final String description;
  final String roomType;
  final int price;
  final int area;
  final String address;
  final String district;
  final String status;
  final bool isVerified;
  final bool isBoosted;
  final String? createdAt;

  AdminRoomItem({
    required this.id,
    required this.landlordId,
    required this.title,
    required this.description,
    required this.roomType,
    required this.price,
    required this.area,
    required this.address,
    required this.district,
    required this.status,
    required this.isVerified,
    required this.isBoosted,
    this.createdAt,
  });

  factory AdminRoomItem.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? 'AVAILABLE').toString().toUpperCase();
    return AdminRoomItem(
      id: (json['id'] ?? '').toString(),
      landlordId: (json['landlordId'] ?? '').toString(),
      title: (json['title'] ?? 'Phòng trọ').toString(),
      description: (json['description'] ?? '').toString(),
      roomType: (json['roomType'] ?? 'Studio').toString(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      area: (json['areaSqm'] as num?)?.toInt() ?? 20,
      address: (json['addressStreet'] ?? json['address'] ?? '').toString(),
      district: (json['district'] ?? 'Quận 10').toString(),
      status: switch (rawStatus) {
        'PENDING' => 'Chờ duyệt',
        'AVAILABLE' => 'Đang hiển thị',
        'HIDDEN' => 'Đã ẩn',
        'RENTED' => 'Đã thuê',
        _ => rawStatus,
      },
      isVerified: json['isVerified'] == true,
      isBoosted: json['isBoosted'] == true,
      createdAt: json['createdAt']?.toString(),
    );
  }
}

/// HTTP implementation of Admin backend endpoints (/api/v1/admin/*).
class HttpAdminRepository {
  final String baseUrl;
  final http.Client client;
  final String? Function() tokenProvider;

  HttpAdminRepository({
    String? baseUrl,
    http.Client? client,
    required this.tokenProvider,
  })  : baseUrl = baseUrl ?? _resolveBaseUrl(),
        client = client ?? http.Client();

  static String _resolveBaseUrl() => ApiConfig.baseUrl;

  Map<String, String> _headers() {
    final token = tokenProvider();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// API #77 / #80: GET /api/v1/admin/dashboard
  Future<AdminDashboardData> getDashboard() async {
    final uri = Uri.parse('$baseUrl/admin/dashboard');
    try {
      final response = await client.get(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>? ?? {};
        return AdminDashboardData.fromJson(data);
      }
      throw RepositoryFailure(RepositoryFault.server, body['message']?.toString() ?? 'Lỗi tải dashboard');
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }

  /// API #79 / #81: GET /api/v1/admin/kyc/pending
  Future<List<AdminKycItem>> getPendingKyc({String? search, int page = 0, int limit = 50}) async {
    final uri = Uri.parse('$baseUrl/admin/kyc/pending').replace(queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page.toString(),
      'limit': limit.toString(),
    });
    try {
      final response = await client.get(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final data = body['data'];
        List<dynamic> content = [];
        if (data is Map && data['content'] is List) {
          content = data['content'] as List<dynamic>;
        } else if (data is List) {
          content = data;
        }
        return content.map((e) => AdminKycItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw RepositoryFailure(RepositoryFault.server, body['message']?.toString() ?? 'Lỗi tải danh sách KYC');
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }

  /// API #80 / #82: PUT /api/v1/admin/kyc/{id}/approve
  Future<void> approveKyc(String id) async {
    final uri = Uri.parse('$baseUrl/admin/kyc/$id/approve');
    try {
      final response = await client.put(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return;
      }
      throw RepositoryFailure(RepositoryFault.denied, body['message']?.toString() ?? 'Phê duyệt thất bại');
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }

  /// API #81 / #83: PUT /api/v1/admin/kyc/{id}/reject
  Future<void> rejectKyc(String id, String reason) async {
    final uri = Uri.parse('$baseUrl/admin/kyc/$id/reject');
    try {
      final response = await client.put(
        uri,
        headers: _headers(),
        body: jsonEncode({'reason': reason.trim()}),
      );
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return;
      }
      throw RepositoryFailure(RepositoryFault.denied, body['message']?.toString() ?? 'Từ chối thất bại');
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }

  /// API #82 / #84: GET /api/v1/admin/users
  Future<List<AdminUserItem>> getUsers({int page = 0, int limit = 50}) async {
    final uri = Uri.parse('$baseUrl/admin/users').replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    try {
      final response = await client.get(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final data = body['data'];
        List<dynamic> content = [];
        if (data is Map && data['content'] is List) {
          content = data['content'] as List<dynamic>;
        } else if (data is List) {
          content = data;
        }
        return content.map((e) => AdminUserItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw RepositoryFailure(RepositoryFault.server, body['message']?.toString() ?? 'Lỗi tải danh sách người dùng');
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }

  /// API #83 / #85: PUT /api/v1/admin/users/{id}/status
  Future<void> updateUserStatus(String id, String status) async {
    final uri = Uri.parse('$baseUrl/admin/users/$id/status');
    final backendStatus = status == 'Đã khóa' || status == 'LOCKED' ? 'LOCKED' : 'ACTIVE';
    try {
      final response = await client.put(
        uri,
        headers: _headers(),
        body: jsonEncode({'status': backendStatus}),
      );
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return;
      }
      throw RepositoryFailure(RepositoryFault.denied, body['message']?.toString() ?? 'Cập nhật trạng thái thất bại');
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }

  /// PUT /api/v1/admin/users/{id}/verify
  Future<void> verifyUser(String id, bool verified) async {
    final uri = Uri.parse('$baseUrl/admin/users/$id/verify').replace(queryParameters: {
      'verified': verified.toString(),
    });
    try {
      final response = await client.put(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return;
      }
      throw RepositoryFailure(RepositoryFault.denied, body['message']?.toString() ?? 'Xác minh thất bại');
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }

  /// API #86: GET /api/v1/admin/rooms
  Future<List<AdminRoomItem>> getRooms({int page = 0, int limit = 50}) async {
    final uri = Uri.parse('$baseUrl/admin/rooms').replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    try {
      final response = await client.get(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final data = body['data'];
        List<dynamic> content = [];
        if (data is Map && data['content'] is List) {
          content = data['content'] as List<dynamic>;
        } else if (data is List) {
          content = data;
        }
        return content.map((e) => AdminRoomItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw RepositoryFailure(RepositoryFault.server, body['message']?.toString() ?? 'Lỗi tải danh sách phòng');
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }

  /// API #87: PUT /api/v1/admin/rooms/{id}/verify
  Future<void> verifyRoom(String id) async {
    final uri = Uri.parse('$baseUrl/admin/rooms/$id/verify');
    try {
      final response = await client.put(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return;
      }
      throw RepositoryFailure(RepositoryFault.denied, body['message']?.toString() ?? 'Xác thực phòng thất bại');
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }

  /// API #88: DELETE /api/v1/admin/rooms/{id}
  Future<void> takeDownRoom(String id) async {
    final uri = Uri.parse('$baseUrl/admin/rooms/$id');
    try {
      final response = await client.delete(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return;
      }
      throw RepositoryFailure(RepositoryFault.denied, body['message']?.toString() ?? 'Gỡ phòng thất bại');
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }

  /// API #86 (Spec): GET /api/v1/admin/reports
  Future<List<AdminReportItem>> getReports({int page = 0, int limit = 50}) async {
    final uri = Uri.parse('$baseUrl/admin/reports').replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    try {
      final response = await client.get(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final data = body['data'];
        List<dynamic> content = [];
        if (data is Map && data['content'] is List) {
          content = data['content'] as List<dynamic>;
        } else if (data is List) {
          content = data;
        }
        return content.map((e) => AdminReportItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw RepositoryFailure(RepositoryFault.server, body['message']?.toString() ?? 'Lỗi tải danh sách báo cáo');
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }

  /// API #88 (Spec): POST /api/v1/admin/reports/{id}/action
  Future<void> handleReportAction(String id, String action, String note) async {
    final uri = Uri.parse('$baseUrl/admin/reports/$id/action');
    try {
      final response = await client.post(
        uri,
        headers: _headers(),
        body: jsonEncode({
          'action': action, // resolve, warn, remove_content, ban, dismiss
          'note': note.trim(),
        }),
      );
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return;
      }
      throw RepositoryFailure(RepositoryFault.denied, body['message']?.toString() ?? 'Xử lý báo cáo thất bại');
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }
}
