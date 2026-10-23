import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/async_resource.dart';
import 'api_config.dart';

class HttpReportRepository {
  final String baseUrl;
  final http.Client client;

  HttpReportRepository({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? _resolveBaseUrl(),
        client = client ?? http.Client();

  static String _resolveBaseUrl() => ApiConfig.baseUrl;

  static String _normalizeUuid(String id) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (uuidRegex.hasMatch(id)) return id;

    // Convert raw identifier to valid 36-char UUID format for backend Jackson deserializer
    final hex = id.codeUnits.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final padded = hex.padRight(32, '0').substring(0, 32);
    return '${padded.substring(0, 8)}-${padded.substring(8, 12)}-${padded.substring(12, 16)}-${padded.substring(16, 20)}-${padded.substring(20, 32)}';
  }

  Future<Map<String, dynamic>> submitReport({
    required String targetType,
    required String targetId,
    required String reportType,
    required String detail,
    String severity = 'MEDIUM',
    List<String> evidenceImages = const [],
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/reports');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await client.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'targetType': targetType.toUpperCase(),
          'targetId': _normalizeUuid(targetId),
          'reportType': reportType,
          'detail': detail,
          'severity': severity,
          'evidenceImages': evidenceImages,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return body['data'] as Map<String, dynamic>? ?? {};
      } else {
        final msg = body['message']?.toString() ?? 'Gửi báo cáo thất bại.';
        throw RepositoryFailure(RepositoryFault.server, msg);
      }
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw RepositoryFailure(
        RepositoryFault.offline,
        'Không thể kết nối đến máy chủ báo cáo ($baseUrl).',
      );
    }
  }
}
