import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/async_resource.dart';
import 'api_config.dart';

class SwapPostDTO {
  final String id;
  final String title;
  final String description;
  final int currentRent;
  final int targetRent;
  final String currentDistrict;
  final String targetDistrict;
  final String status;
  final String tenantId;
  final String tenantName;
  final String? roomId;
  final String createdAt;

  SwapPostDTO({
    required this.id,
    required this.title,
    required this.description,
    required this.currentRent,
    required this.targetRent,
    required this.currentDistrict,
    required this.targetDistrict,
    required this.status,
    required this.tenantId,
    required this.tenantName,
    this.roomId,
    required this.createdAt,
  });

  factory SwapPostDTO.fromJson(Map<String, dynamic> j) => SwapPostDTO(
    id: (j['id'] ?? '').toString(),
    title: (j['title'] ?? '').toString(),
    description: (j['description'] ?? '').toString(),
    currentRent: (j['currentRent'] as num?)?.toInt() ?? 0,
    targetRent: (j['targetRent'] as num?)?.toInt() ?? 0,
    currentDistrict: (j['currentDistrict'] ?? 'Quận 10').toString(),
    targetDistrict: (j['targetDistrict'] ?? 'Quận 10').toString(),
    status: (j['status'] ?? 'PENDING').toString(),
    tenantId: (j['tenantId'] ?? '').toString(),
    tenantName: (j['tenantName'] ?? '').toString(),
    roomId: j['roomId']?.toString(),
    createdAt: (j['createdAt'] ?? '').toString(),
  );
}

class SwapProposalDTO {
  final String id;
  final String swapPostId;
  final String candidateId;
  final String candidateName;
  final String? message;
  final String status;
  final String createdAt;

  SwapProposalDTO({
    required this.id,
    required this.swapPostId,
    required this.candidateId,
    required this.candidateName,
    this.message,
    required this.status,
    required this.createdAt,
  });

  factory SwapProposalDTO.fromJson(Map<String, dynamic> j) => SwapProposalDTO(
    id: (j['id'] ?? '').toString(),
    swapPostId: (j['swapPostId'] ?? j['postId'] ?? '').toString(),
    candidateId: (j['candidateId'] ?? '').toString(),
    candidateName: (j['candidateName'] ?? '').toString(),
    message: j['message']?.toString(),
    status: (j['status'] ?? 'PENDING').toString(),
    createdAt: (j['createdAt'] ?? '').toString(),
  );
}

/// HTTP Client for Module 5: Room Swaps & Subleasing
class HttpSwapRepository {
  final String baseUrl;
  final http.Client client;
  final String? Function() tokenProvider;

  HttpSwapRepository({
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

  /// API #48 / #46: Đăng tin yêu cầu hoán đổi phòng
  Future<SwapPostDTO> createSwapPost({
    required String title,
    required String description,
    required int currentRent,
    required int targetRent,
    required String currentDistrict,
    required String targetDistrict,
    String? roomId,
  }) async {
    final uri = Uri.parse('$baseUrl/swaps');
    final res = await client.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'currentRent': currentRent,
        'targetRent': targetRent,
        'currentDistrict': currentDistrict,
        'targetDistrict': targetDistrict,
        if (roomId != null) 'roomId': roomId,
      }),
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
      return SwapPostDTO.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw RepositoryFailure(RepositoryFault.server, body['message']?.toString() ?? 'Đăng tin hoán đổi thất bại');
  }

  /// API #49 / #45: Khám phá bảng tin hoán đổi phòng thuê công khai
  Future<List<SwapPostDTO>> searchSwaps({int? maxPrice, String? keyword}) async {
    final uri = Uri.parse('$baseUrl/swaps/feed').replace(queryParameters: {
      if (maxPrice != null) 'maxPrice': maxPrice.toString(),
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
    });
    try {
      final res = await client.get(uri, headers: _headers());
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        final content = data?['content'] as List<dynamic>? ?? [];
        return content.map((e) => SwapPostDTO.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// API #47 / #61: Xem danh sách tin swap cá nhân
  Future<List<SwapPostDTO>> getMySwaps() async {
    final uri = Uri.parse('$baseUrl/swaps/me');
    try {
      final res = await client.get(uri, headers: _headers());
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
        final list = body['data'] as List<dynamic>? ?? [];
        return list.map((e) => SwapPostDTO.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// API #50: Chi tiết tin hoán đổi phòng
  Future<SwapPostDTO?> getSwapDetail(String id) async {
    final uri = Uri.parse('$baseUrl/swaps/$id');
    try {
      final res = await client.get(uri, headers: _headers());
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
        return SwapPostDTO.fromJson(body['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  /// API #51 / #49: Gửi đề xuất / đăng ký nhận hoán đổi phòng
  Future<SwapProposalDTO> sendSwapProposal(String swapId, {required String message}) async {
    final uri = Uri.parse('$baseUrl/swaps/$swapId/request');
    final res = await client.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'message': message}),
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
      return SwapProposalDTO.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw RepositoryFailure(RepositoryFault.server, body['message']?.toString() ?? 'Gửi đề xuất thất bại');
  }

  /// API #52: Phê duyệt / Từ chối đề xuất hoán đổi phòng
  Future<void> updateRequestStatus(String requestId, {required bool approve}) async {
    final uri = Uri.parse('$baseUrl/swaps/requests/$requestId');
    try {
      await client.put(
        uri,
        headers: _headers(),
        body: jsonEncode({'status': approve ? 'APPROVED' : 'REJECTED'}),
      );
    } catch (_) {}
  }

  /// API #50 (Spec): Chủ trọ xem danh sách yêu cầu chuyển nhượng
  Future<List<SwapPostDTO>> getLandlordRequests() async {
    final uri = Uri.parse('$baseUrl/swaps/landlord/requests');
    try {
      final res = await client.get(uri, headers: _headers());
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
        final list = body['data'] as List<dynamic>? ?? [];
        return list.map((e) => SwapPostDTO.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// API #51 (Spec): Chủ trọ phê duyệt hoán đổi hợp đồng
  Future<void> approveLandlordSwap(String id) async {
    final uri = Uri.parse('$baseUrl/swaps/landlord/$id/approve');
    try {
      await client.put(uri, headers: _headers());
    } catch (_) {}
  }

  /// API #52 (Spec): Chủ trọ từ chối hoán đổi hợp đồng
  Future<void> declineLandlordSwap(String id) async {
    final uri = Uri.parse('$baseUrl/swaps/landlord/$id/decline');
    try {
      await client.put(uri, headers: _headers());
    } catch (_) {}
  }
}
