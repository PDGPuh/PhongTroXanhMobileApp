import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/async_resource.dart';
import '../core/reference_photo.dart';
import '../domain/models.dart';
import 'api_config.dart';

class SwipeResult {
  final bool isMatch;
  final String? conversationId;
  final int remainingSwipes;

  SwipeResult({
    required this.isMatch,
    this.conversationId,
    required this.remainingSwipes,
  });

  factory SwipeResult.fromJson(Map<String, dynamic> json) {
    return SwipeResult(
      isMatch: json['isMatch'] == true,
      conversationId: json['conversationId']?.toString(),
      remainingSwipes: (json['remainingSwipes'] as num?)?.toInt() ?? 0,
    );
  }
}

class MatchItem {
  final String matchId;
  final String targetUserId;
  final String targetUserName;
  final String targetAvatarUrl;
  final int compatibilityScore;
  final String? conversationId;
  final String matchedAt;

  MatchItem({
    required this.matchId,
    required this.targetUserId,
    required this.targetUserName,
    required this.targetAvatarUrl,
    required this.compatibilityScore,
    this.conversationId,
    required this.matchedAt,
  });

  factory MatchItem.fromJson(Map<String, dynamic> json) {
    return MatchItem(
      matchId: (json['matchId'] ?? '').toString(),
      targetUserId: (json['targetUserId'] ?? '').toString(),
      targetUserName: (json['targetUserName'] ?? 'Người dùng').toString(),
      targetAvatarUrl: (json['targetAvatarUrl'] ?? '').toString(),
      compatibilityScore: (json['compatibilityScore'] as num?)?.toInt() ?? 90,
      conversationId: json['conversationId']?.toString(),
      matchedAt: (json['matchedAt'] ?? '').toString(),
    );
  }
}

/// HTTP implementation of Roommate Matching Engine (/api/v1/matching/*).
class HttpMatchingRepository {
  final String baseUrl;
  final http.Client client;
  final String? Function() tokenProvider;

  HttpMatchingRepository({
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

  /// API #40: GET /api/v1/matching/feed (Discovery Feed)
  Future<List<Person>> getFeed() async {
    final uri = Uri.parse('$baseUrl/matching/feed');
    try {
      final response = await client.get(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final List<dynamic> list = body['data'] as List<dynamic>? ?? [];
        return list.map((e) => _personFromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// API #41: POST /api/v1/matching/swipe (LIKE / DISLIKE)
  Future<SwipeResult?> swipe(String targetUserId, bool like) async {
    final uri = Uri.parse('$baseUrl/matching/swipe');
    try {
      final response = await client.post(
        uri,
        headers: _headers(),
        body: jsonEncode({
          'targetUserId': targetUserId,
          'action': like ? 'LIKE' : 'DISLIKE',
        }),
      );
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>? ?? {};
        return SwipeResult.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// API #42: GET /api/v1/matching/matches
  Future<List<MatchItem>> getMatches() async {
    final uri = Uri.parse('$baseUrl/matching/matches');
    try {
      final response = await client.get(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final List<dynamic> list = body['data'] as List<dynamic>? ?? [];
        return list.map((e) => MatchItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// API #43: DELETE /api/v1/matching/matches/{matchId}
  Future<void> unmatch(String matchId) async {
    final uri = Uri.parse('$baseUrl/matching/matches/$matchId');
    try {
      await client.delete(uri, headers: _headers());
    } catch (_) {}
  }

  /// API #44: POST /api/v1/matching/boost
  Future<void> boostProfile() async {
    final uri = Uri.parse('$baseUrl/matching/boost');
    try {
      final response = await client.post(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return;
      }
      throw RepositoryFailure(RepositoryFault.denied, body['message']?.toString() ?? 'Đẩy hồ sơ thất bại');
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }

  /// API #45: GET /api/v1/matching/compatibility/{targetUserId} (Chi tiết tương thích 8 trụ cột)
  Future<Map<String, dynamic>?> getCompatibility(String targetUserId) async {
    final uri = Uri.parse('$baseUrl/matching/compatibility/$targetUserId');
    try {
      final response = await client.get(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return body['data'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  /// API #46: GET /api/v1/matching/preferences
  Future<Map<String, dynamic>?> getPreferences() async {
    final uri = Uri.parse('$baseUrl/matching/preferences');
    try {
      final response = await client.get(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return body['data'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  /// API #47: PUT /api/v1/matching/preferences
  Future<void> updatePreferences(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/matching/preferences');
    try {
      await client.put(uri, headers: _headers(), body: jsonEncode(payload));
    } catch (_) {}
  }

  Person _personFromJson(Map<String, dynamic> e) {
    final rawGender = (e['gender'] ?? 'FEMALE').toString().toUpperCase();
    final isFemale = rawGender == 'FEMALE' || rawGender == 'NỮ';
    final districts = (e['preferredDistricts'] as List<dynamic>? ?? []).map((d) => d.toString()).toList();
    final district = districts.isNotEmpty ? districts.first : 'Quận 10';
    final habits = <String>[];
    if (e['nonSmoking'] == true) habits.add('Không hút thuốc');
    if (e['earlySleeper'] == true) habits.add('Ngủ trước 23h');
    if (e['isNeat'] == true) habits.add('Gọn gàng, sạch sẽ');
    if (e['allowGuests'] == true) habits.add('Cho bạn bè tới chơi');
    if (habits.isEmpty) habits.addAll(['Không hút thuốc', 'Gọn gàng, sạch sẽ']);

    final budget = (e['budgetMax'] as num?)?.toInt() ?? 2500000;
    final match = (e['compatibilityScore'] as num?)?.toInt() ?? 90;
    final interests = (e['interests'] as List<dynamic>? ?? []).map((i) => i.toString()).toList();

    return Person(
      id: (e['userId'] ?? e['id'] ?? '').toString(),
      name: (e['fullName'] ?? 'Người dùng').toString(),
      school: (e['schoolOrCompany'] ?? 'Đại học Bách Khoa').toString(),
      bio: (e['bio'] ?? 'Tìm bạn ở ghép lịch sự, sạch sẽ.').toString(),
      gender: isFemale ? 'Nữ' : 'Nam',
      district: district,
      budget: budget,
      habits: habits,
      age: 21,
      match: match,
      photo: isFemale ? PhotoKind.woman : PhotoKind.man,
      interests: interests.isNotEmpty ? interests : const ['Nấu ăn', 'Đọc sách'],
    );
  }
}
