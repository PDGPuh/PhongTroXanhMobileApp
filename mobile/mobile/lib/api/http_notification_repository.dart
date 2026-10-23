import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/async_resource.dart';
import '../domain/models.dart';
import 'api_config.dart';

class NotificationDTO {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String createdAt;

  const NotificationDTO({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationDTO.fromJson(Map<String, dynamic> j) => NotificationDTO(
    id: j['id']?.toString() ?? '',
    userId: j['userId']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    body: j['body']?.toString() ?? '',
    type: j['type']?.toString() ?? '',
    data: j['data'] is Map<String, dynamic> ? j['data'] as Map<String, dynamic> : null,
    isRead: j['isRead'] == true,
    createdAt: j['createdAt']?.toString() ?? '',
  );

  AppNotification toAppNotification() {
    ResourceRef? ref;
    bool isVerif = false;
    if (data != null) {
      if (data!['roomId'] != null) {
        ref = ResourceRef(ResourceKind.room, data!['roomId'].toString());
      } else if (data!['conversationId'] != null) {
        ref = ResourceRef(ResourceKind.conversation, data!['conversationId'].toString());
      } else if (data!['rentalId'] != null) {
        ref = ResourceRef(ResourceKind.rental, data!['rentalId'].toString());
      } else if (data!['orderId'] != null) {
        ref = ResourceRef(ResourceKind.order, data!['orderId'].toString());
      }
    }
    final upperType = type.toUpperCase();
    if (upperType.contains('KYC') || upperType.contains('VERIF')) {
      isVerif = true;
    }
    return AppNotification(
      id: id,
      title: title,
      description: body,
      target: ref,
      verification: isVerif,
      read: isRead,
    );
  }
}

class HttpNotificationRepository {
  final String baseUrl;
  final http.Client client;
  final String? Function() tokenProvider;

  HttpNotificationRepository({
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
    final msg = body['message']?.toString() ?? 'Loi ${res.statusCode}';
    throw RepositoryFailure(RepositoryFault.server, msg);
  }

  dynamic _parseData(http.Response res) {
    _checkStatus(res);
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return body['data'];
  }

  /// API #73: Lay danh sach thong bao ca nhan (co phan trang)
  Future<List<NotificationDTO>> getNotifications({int page = 0, int limit = 30}) async {
    final res = await client.get(
      Uri.parse('$baseUrl/notifications?page=$page&limit=$limit'),
      headers: _headers,
    );
    final data = _parseData(res);
    List<dynamic> items = [];
    if (data is Map<String, dynamic> && data['content'] is List) {
      items = data['content'] as List<dynamic>;
    } else if (data is List) {
      items = data;
    }
    return items
        .map((e) => NotificationDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// API #74: Danh dau 1 thong bao da doc
  Future<void> markAsRead(String id) async {
    final res = await client.put(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: _headers,
    );
    _checkStatus(res);
  }

  /// API #75: Danh dau tat ca thong bao da doc
  Future<void> markAllAsRead() async {
    final res = await client.put(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: _headers,
    );
    _checkStatus(res);
  }

  /// API #76: Dang ky FCM Device Token
  Future<void> registerDeviceToken(String token, {String deviceType = 'ANDROID'}) async {
    final res = await client.post(
      Uri.parse('$baseUrl/notifications/device-token'),
      headers: _headers,
      body: jsonEncode({'token': token, 'deviceType': deviceType}),
    );
    _checkStatus(res);
  }
}
