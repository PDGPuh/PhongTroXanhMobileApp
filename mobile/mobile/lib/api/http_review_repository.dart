import 'dart:convert';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:http/http.dart' as http;

import '../core/async_resource.dart';
import 'api_config.dart';

class ReviewResponseDTO {
  final String id;
  final String? rentalId;
  final String? roomId;
  final String? reviewerId;
  final String? reviewerName;
  final String? reviewerAvatar;
  final String? revieweeId;
  final int rating;
  final int cleanlinessRating;
  final int accuracyRating;
  final int communicationRating;
  final String comment;
  final List<String> tags;
  final List<String> images;
  final String? disputeStatus;
  final String? disputeReason;
  final String? replyComment;
  final String? repliedAt;
  final List<String> evidenceImages;
  final bool isVerifiedStay;
  final String createdAt;

  const ReviewResponseDTO({
    required this.id,
    this.rentalId,
    this.roomId,
    this.reviewerId,
    this.reviewerName,
    this.reviewerAvatar,
    this.revieweeId,
    required this.rating,
    this.cleanlinessRating = 5,
    this.accuracyRating = 5,
    this.communicationRating = 5,
    required this.comment,
    required this.tags,
    this.images = const [],
    this.disputeStatus,
    this.disputeReason,
    this.replyComment,
    this.repliedAt,
    this.evidenceImages = const [],
    this.isVerifiedStay = false,
    required this.createdAt,
  });

  factory ReviewResponseDTO.fromJson(Map<String, dynamic> j) => ReviewResponseDTO(
    id: j['id']?.toString() ?? '',
    rentalId: j['rentalId']?.toString(),
    roomId: j['roomId']?.toString(),
    reviewerId: j['reviewerId']?.toString(),
    reviewerName: j['reviewerName']?.toString(),
    reviewerAvatar: j['reviewerAvatar']?.toString(),
    revieweeId: j['revieweeId']?.toString(),
    rating: (j['rating'] as num?)?.toInt() ?? 5,
    cleanlinessRating: (j['cleanlinessRating'] as num?)?.toInt() ?? 5,
    accuracyRating: (j['accuracyRating'] as num?)?.toInt() ?? 5,
    communicationRating: (j['communicationRating'] as num?)?.toInt() ?? 5,
    comment: j['comment']?.toString() ?? '',
    tags: (j['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    images: (j['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    disputeStatus: j['disputeStatus']?.toString(),
    disputeReason: j['disputeReason']?.toString(),
    replyComment: j['replyComment']?.toString(),
    repliedAt: j['repliedAt']?.toString(),
    evidenceImages: (j['evidenceImages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    isVerifiedStay: j['isVerifiedStay'] == true,
    createdAt: j['createdAt']?.toString() ?? '',
  );
}

class SystemFeedbackDTO {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final int rating;
  final String category;
  final String comment;
  final String createdAt;

  const SystemFeedbackDTO({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.rating,
    required this.category,
    required this.comment,
    required this.createdAt,
  });

  factory SystemFeedbackDTO.fromJson(Map<String, dynamic> j) => SystemFeedbackDTO(
    id: j['id']?.toString() ?? '',
    userId: j['userId']?.toString() ?? '',
    userName: j['userName']?.toString() ?? 'Người dùng',
    userRole: j['userRole']?.toString() ?? 'TENANT',
    rating: (j['rating'] as num?)?.toInt() ?? 5,
    category: j['category']?.toString() ?? 'SYSTEM',
    comment: j['comment']?.toString() ?? '',
    createdAt: j['createdAt']?.toString() ?? '',
  );
}

class HttpReviewRepository {
  final String baseUrl;
  final http.Client client;
  final String? Function() tokenProvider;

  HttpReviewRepository({
    String? baseUrl,
    http.Client? client,
    required this.tokenProvider,
  }) : baseUrl = baseUrl ?? _resolveBaseUrl(),
       client = client ?? http.Client();

  static String _resolveBaseUrl() => ApiConfig.baseUrl;

  Map<String, String> get _headers {
    final token = tokenProvider();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {}
    final msg = body['message']?.toString() ?? 'Lỗi máy chủ (${res.statusCode})';
    throw RepositoryFailure(RepositoryFault.server, msg);
  }

  dynamic _parseData(http.Response res) {
    _checkStatus(res);
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return body['data'];
  }

  /// API #60: Đăng đánh giá 2 chiều
  Future<ReviewResponseDTO> createReview({
    required String rentalId,
    required String roomId,
    required int rating,
    required String comment,
    List<String>? tags,
    List<String>? images,
    int? cleanlinessRating,
    int? accuracyRating,
    int? communicationRating,
  }) async {
    final res = await client.post(
      Uri.parse('$baseUrl/reviews'),
      headers: _headers,
      body: jsonEncode({
        'rentalId': rentalId,
        'roomId': roomId,
        'rating': rating,
        'cleanlinessRating': cleanlinessRating ?? rating,
        'accuracyRating': accuracyRating ?? rating,
        'communicationRating': communicationRating ?? rating,
        'comment': comment,
        'tags': tags ?? [],
        'images': images ?? [],
      }),
    );
    return ReviewResponseDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #61: Danh sách đánh giá phòng
  Future<List<ReviewResponseDTO>> getReviewsForRoom(String roomId) async {
    final res = await client.get(
      Uri.parse('$baseUrl/reviews/rooms/$roomId'),
      headers: _headers,
    );
    final list = _parseData(res) as List<dynamic>;
    return list
        .map((e) => ReviewResponseDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// API #62: Danh sách đánh giá người dùng
  Future<List<ReviewResponseDTO>> getReviewsForUser(String userId) async {
    final res = await client.get(
      Uri.parse('$baseUrl/reviews/users/$userId'),
      headers: _headers,
    );
    final list = _parseData(res) as List<dynamic>;
    return list
        .map((e) => ReviewResponseDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// API #63: Gửi khiếu nại đánh giá (Dispute)
  Future<ReviewResponseDTO> submitDispute(String reviewId, String reason) async {
    final res = await client.post(
      Uri.parse('$baseUrl/reviews/$reviewId/dispute'),
      headers: _headers,
      body: jsonEncode({'reason': reason}),
    );
    return ReviewResponseDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #64: Tải lên bằng chứng khiếu nại/đánh giá (Multipart)
  Future<List<String>> uploadEvidence(
    String reviewId, {
    required List<Uint8List> fileBytes,
    required List<String> fileNames,
  }) async {
    final uri = Uri.parse('$baseUrl/reviews/$reviewId/evidences');
    final req = http.MultipartRequest('POST', uri);
    final token = tokenProvider();
    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }
    for (int i = 0; i < fileBytes.length; i++) {
      req.files.add(
        http.MultipartFile.fromBytes('files', fileBytes[i], filename: fileNames[i]),
      );
    }
    final streamed = await client.send(req);
    final res = await http.Response.fromStream(streamed);
    final list = _parseData(res) as List<dynamic>;
    return list.map((e) => e.toString()).toList();
  }

  /// API #65: Chi tiết đánh giá & bằng chứng
  Future<ReviewResponseDTO> getReviewDetail(String id) async {
    final res = await client.get(
      Uri.parse('$baseUrl/reviews/$id'),
      headers: _headers,
    );
    return ReviewResponseDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #66: Phản hồi công khai đánh giá
  Future<ReviewResponseDTO> replyReview(String reviewId, String replyComment) async {
    final res = await client.post(
      Uri.parse('$baseUrl/reviews/$reviewId/reply'),
      headers: _headers,
      body: jsonEncode({'replyComment': replyComment}),
    );
    return ReviewResponseDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #67: Danh sách khiếu nại chờ Admin duyệt
  Future<List<ReviewResponseDTO>> getPendingDisputes({
    int page = 0,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/reviews/disputes/pending').replace(
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    final res = await client.get(uri, headers: _headers);
    final data = _parseData(res);
    List<dynamic> content = [];
    if (data is Map && data['content'] is List) {
      content = data['content'] as List<dynamic>;
    } else if (data is List) {
      content = data;
    }
    return content
        .map((e) => ReviewResponseDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// API #68: Admin giải quyết khiếu nại đánh giá
  Future<ReviewResponseDTO> resolveDispute(
    String disputeId, {
    required bool approved,
    String? adminNotes,
  }) async {
    final res = await client.post(
      Uri.parse('$baseUrl/reviews/disputes/$disputeId/resolve'),
      headers: _headers,
      body: jsonEncode({
        'approved': approved,
        if (adminNotes != null) 'adminNotes': adminNotes,
      }),
    );
    return ReviewResponseDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #69: Gửi hoặc cập nhật góp ý & đánh giá hệ thống
  Future<SystemFeedbackDTO> createSystemFeedback({
    required int rating,
    String? category,
    required String comment,
  }) async {
    final res = await client.post(
      Uri.parse('$baseUrl/reviews/system-feedback'),
      headers: _headers,
      body: jsonEncode({
        'rating': rating,
        if (category != null) 'category': category,
        'comment': comment,
      }),
    );
    return SystemFeedbackDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #70: Lấy danh sách đánh giá hệ thống có phân trang
  Future<List<SystemFeedbackDTO>> getSystemFeedbacks({
    int page = 0,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/reviews/system-feedbacks').replace(
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    final res = await client.get(uri, headers: _headers);
    final data = _parseData(res);
    List<dynamic> content = [];
    if (data is Map && data['content'] is List) {
      content = data['content'] as List<dynamic>;
    } else if (data is List) {
      content = data;
    }
    return content
        .map((e) => SystemFeedbackDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// API #71: Chỉnh sửa đánh giá
  Future<ReviewResponseDTO> updateReview(
    String id, {
    required int rating,
    required String comment,
    List<String>? tags,
    List<String>? images,
  }) async {
    final res = await client.put(
      Uri.parse('$baseUrl/reviews/$id'),
      headers: _headers,
      body: jsonEncode({
        'rating': rating,
        'comment': comment,
        'tags': tags ?? [],
        'images': images ?? [],
      }),
    );
    return ReviewResponseDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #72: Lấy góp ý hệ thống của tài khoản hiện tại
  Future<SystemFeedbackDTO?> getMySystemFeedback() async {
    final res = await client.get(
      Uri.parse('$baseUrl/reviews/system-feedback/me'),
      headers: _headers,
    );
    final data = _parseData(res);
    if (data == null) return null;
    return SystemFeedbackDTO.fromJson(data as Map<String, dynamic>);
  }

  /// API #73: Admin xóa góp ý hệ thống sai lệch
  Future<void> deleteSystemFeedback(String id) async {
    final res = await client.delete(
      Uri.parse('$baseUrl/reviews/system-feedback/$id'),
      headers: _headers,
    );
    _checkStatus(res);
  }
}
