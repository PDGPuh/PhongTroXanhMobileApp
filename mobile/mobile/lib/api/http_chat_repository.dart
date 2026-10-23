import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/async_resource.dart';
import '../domain/models.dart';
import 'api_config.dart';

/// DTO cho ConversationResponse
class ConversationDTO {
  final String id;
  final String partnerId;
  final String partnerName;
  final String? partnerAvatar;
  final String type;
  final String? roomId;
  final String? roomTitle;
  final String? lastMessageContent;
  final String? lastMessageAt;
  final int unreadCount;

  const ConversationDTO({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatar,
    required this.type,
    this.roomId,
    this.roomTitle,
    this.lastMessageContent,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationDTO.fromJson(Map<String, dynamic> j) => ConversationDTO(
    id: j['id']?.toString() ?? '',
    partnerId: j['partnerId']?.toString() ?? '',
    partnerName: j['partnerName']?.toString() ?? 'Nguoi dung',
    partnerAvatar: j['partnerAvatar']?.toString(),
    type: j['type']?.toString() ?? 'ROOM',
    roomId: j['roomId']?.toString(),
    roomTitle: j['roomTitle']?.toString(),
    lastMessageContent: j['lastMessageContent']?.toString(),
    lastMessageAt: j['lastMessageAt']?.toString(),
    unreadCount: (j['unreadCount'] as num?)?.toInt() ?? 0,
  );

  /// Chuyen thanh domain Conversation
  Conversation toConversation() => Conversation(
    id: id,
    name: partnerName,
    participantId: partnerId,
    participantName: partnerName,
    roomId: roomId,
    subtitle: lastMessageContent ?? roomTitle ?? '',
    unread: unreadCount,
    host: type == 'ROOM',
    messages: [],
  );
}

/// DTO cho MessageResponse
class MessageDTO {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String? attachmentUrl;
  final bool isRead;
  final String createdAt;

  const MessageDTO({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.attachmentUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageDTO.fromJson(Map<String, dynamic> j) => MessageDTO(
    id: j['id']?.toString() ?? '',
    conversationId: j['conversationId']?.toString() ?? '',
    senderId: j['senderId']?.toString() ?? '',
    senderName: j['senderName']?.toString() ?? '',
    senderAvatar: j['senderAvatar']?.toString(),
    content: j['content']?.toString() ?? '',
    attachmentUrl: j['attachmentUrl']?.toString(),
    isRead: j['isRead'] as bool? ?? false,
    createdAt: j['createdAt']?.toString() ?? '',
  );

  /// Chuyen thanh domain ChatMessage
  ChatMessage toChatMessage(String myUserId) {
    final dt = DateTime.tryParse(createdAt) ?? DateTime.now();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return ChatMessage(
      content,
      mine: senderId == myUserId,
      time: '$hh:$mm',
      id: id,
    );
  }
}

class HttpChatRepository {
  final String baseUrl;
  final http.Client client;
  final String? Function() tokenProvider;

  HttpChatRepository({
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

  /// API #68: Danh sach hoi thoai
  Future<List<ConversationDTO>> getConversations() async {
    final res = await client.get(
      Uri.parse('$baseUrl/chat/conversations'),
      headers: _headers,
    );
    final list = _parseData(res) as List<dynamic>;
    return list
        .map((e) => ConversationDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// API #69: Lich su tin nhan
  Future<List<MessageDTO>> getMessages(
    String conversationId, {
    int page = 0,
    int limit = 30,
  }) async {
    final res = await client.get(
      Uri.parse(
        '$baseUrl/chat/conversations/$conversationId/messages?page=$page&limit=$limit',
      ),
      headers: _headers,
    );
    final data = _parseData(res);
    // Backend tra ve Page<MessageResponse> - lay content
    List<dynamic> list;
    if (data is Map && data.containsKey('content')) {
      list = data['content'] as List<dynamic>;
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }
    return list
        .map((e) => MessageDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// API #70: Gui tin nhan
  Future<MessageDTO> sendMessage(
    String conversationId,
    String content, {
    String? attachmentUrl,
  }) async {
    final res = await client.post(
      Uri.parse('$baseUrl/chat/conversations/$conversationId/messages'),
      headers: _headers,
      body: jsonEncode({
        'content': content,
        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      }),
    );
    return MessageDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #71: Danh dau da doc
  Future<void> markAsRead(String conversationId) async {
    final res = await client.put(
      Uri.parse('$baseUrl/chat/conversations/$conversationId/read'),
      headers: _headers,
    );
    _checkStatus(res);
  }

  /// API #72: Tao cuoc tro chuyen moi
  Future<ConversationDTO> createConversation({
    required String partnerId,
    String? roomId,
    String type = 'ROOM',
  }) async {
    final res = await client.post(
      Uri.parse('$baseUrl/chat/conversations'),
      headers: _headers,
      body: jsonEncode({
        'partnerId': partnerId,
        if (roomId != null) 'roomId': roomId,
        'type': type,
      }),
    );
    return ConversationDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }
}
