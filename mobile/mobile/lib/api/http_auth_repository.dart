import 'dart:convert';
import 'package:http/http.dart' as http;

import '../app/session.dart';
import '../core/async_resource.dart';
import '../domain/models.dart';
import '../features/auth/password_recovery.dart';

import 'api_config.dart';

class HttpAuthRepository implements AuthRepository, PasswordRecoveryRepository {
  final String baseUrl;
  final http.Client client;

  String? accessToken;

  HttpAuthRepository({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? _resolveBaseUrl(),
        client = client ?? http.Client();

  static String _resolveBaseUrl() => ApiConfig.baseUrl;

  @override
  Future<SessionUser> signIn(String login, String password) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login': login.trim(),
          'password': password,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        accessToken = data['accessToken'] as String?;
        final userMap = data['user'] as Map<String, dynamic>;

        final rawRole = (userMap['role'] ?? 'ROLE_TENANT').toString().toUpperCase();
        final role = rawRole.contains('LANDLORD')
            ? UserRole.landlord
            : rawRole.contains('ADMIN')
                ? UserRole.admin
                : UserRole.tenant;

        return SessionUser(
          id: userMap['id']?.toString() ?? '',
          email: userMap['email']?.toString() ?? login.trim(),
          name: userMap['fullName']?.toString() ?? userMap['name']?.toString() ?? 'Người dùng',
          phone: userMap['phoneNumber']?.toString() ?? userMap['phone']?.toString() ?? '',
          role: role,
          avatarUrl: userMap['avatarUrl']?.toString() ?? userMap['picture']?.toString(),
        );
      } else {
        final msg = body['message']?.toString() ?? 'Đăng nhập không thành công.';
        throw RepositoryFailure(RepositoryFault.denied, msg);
      }
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw RepositoryFailure(
        RepositoryFault.offline,
        'Không thể kết nối đến máy chủ Backend ($baseUrl). Vui lòng thử lại.',
      );
    }
  }

  @override
  Future<SessionUser> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': name.trim(),
          'email': email.trim().toLowerCase(),
          'phoneNumber': phone.trim(),
          'password': password,
          'role': 'TENANT',
        }),
      );

      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        accessToken = data['accessToken'] as String?;
        final userMap = data['user'] as Map<String, dynamic>;

        return SessionUser(
          id: userMap['id']?.toString() ?? '',
          email: userMap['email']?.toString() ?? email.trim(),
          name: userMap['fullName']?.toString() ?? name.trim(),
          phone: userMap['phoneNumber']?.toString() ?? phone.trim(),
          role: UserRole.tenant,
          avatarUrl: userMap['avatarUrl']?.toString() ?? userMap['picture']?.toString(),
        );
      } else {
        final msg = body['message']?.toString() ?? 'Đăng ký không thành công.';
        throw RepositoryFailure(RepositoryFault.server, msg);
      }
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw RepositoryFailure(
        RepositoryFault.offline,
        'Không thể kết nối đến máy chủ Backend ($baseUrl). Vui lòng thử lại.',
      );
    }
  }

  @override
  Future<void> sendOtp(String email) async {
    final uri = Uri.parse('$baseUrl/auth/forgot-password');
    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
        }),
      );

      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return;
      } else {
        final msg = body['message']?.toString() ?? 'Không thể gửi mã OTP.';
        throw RepositoryFailure(RepositoryFault.denied, msg);
      }
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw RepositoryFailure(
        RepositoryFault.offline,
        'Không thể kết nối đến máy chủ Backend ($baseUrl).',
      );
    }
  }

  Future<void> sendCustomOtp(String email, {String type = 'REGISTRATION'}) async {
    final uri = Uri.parse('$baseUrl/auth/send-otp');
    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'type': type,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return;
      } else {
        final msg = body['message']?.toString() ?? 'Không thể gửi mã OTP.';
        throw RepositoryFailure(RepositoryFault.denied, msg);
      }
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw RepositoryFailure(
        RepositoryFault.offline,
        'Không thể kết nối đến máy chủ Backend ($baseUrl).',
      );
    }
  }

  @override
  Future<String> verifyOtp(String email, String code) async {
    final uri = Uri.parse('$baseUrl/auth/verify-otp');
    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'otp': code.trim(),
          'type': 'RESET_PASSWORD',
        }),
      );

      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        final tempToken = data?['tempToken']?.toString();
        if (tempToken != null && tempToken.isNotEmpty) {
          return tempToken;
        }
        throw const RepositoryFailure(RepositoryFault.denied, 'Mã OTP không hợp lệ.');
      } else {
        final msg = body['message']?.toString() ?? 'Mã OTP không chính xác hoặc đã hết hạn.';
        throw RepositoryFailure(RepositoryFault.denied, msg);
      }
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw RepositoryFailure(
        RepositoryFault.offline,
        'Không thể kết nối đến máy chủ Backend ($baseUrl).',
      );
    }
  }

  @override
  Future<void> resetPassword(String token, String password) async {
    final uri = Uri.parse('$baseUrl/auth/reset-password');
    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tempToken': token,
          'newPassword': password,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return;
      } else {
        final msg = body['message']?.toString() ?? 'Không thể đặt lại mật khẩu.';
        throw RepositoryFailure(RepositoryFault.denied, msg);
      }
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw RepositoryFailure(
        RepositoryFault.offline,
        'Không thể kết nối đến máy chủ Backend ($baseUrl).',
      );
    }
  }

  Future<void> logout() async {
    if (accessToken == null) return;
    final uri = Uri.parse('$baseUrl/auth/logout');
    try {
      await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
    } catch (_) {}
    accessToken = null;
  }

  Future<String?> getGoogleClientId() async {
    final uri = Uri.parse('$baseUrl/auth/oauth/google/client-id');
    try {
      final response = await client.get(uri);
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        return data?['clientId']?.toString();
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<SessionUser> loginWithGoogle(String idToken, {String role = 'TENANT'}) =>
      googleLogin(idToken, role: role);

  Future<SessionUser> googleLogin(String idToken, {String role = 'TENANT'}) async {
    final uri = Uri.parse('$baseUrl/auth/oauth/google');
    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'role': role,
        }),
      );

      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        accessToken = data['accessToken'] as String?;
        final userMap = data['user'] as Map<String, dynamic>;

        final rawRole = (userMap['role'] ?? 'ROLE_TENANT').toString().toUpperCase();
        final role = rawRole.contains('LANDLORD')
            ? UserRole.landlord
            : rawRole.contains('ADMIN')
                ? UserRole.admin
                : UserRole.tenant;

        return SessionUser(
          id: userMap['id']?.toString() ?? '',
          email: userMap['email']?.toString() ?? '',
          name: userMap['fullName']?.toString() ?? userMap['name']?.toString() ?? 'Người dùng',
          phone: userMap['phoneNumber']?.toString() ?? '',
          role: role,
          avatarUrl: userMap['avatarUrl']?.toString() ?? userMap['picture']?.toString(),
        );
      } else {
        final msg = body['message']?.toString() ?? 'Đăng nhập Google thất bại.';
        throw RepositoryFailure(RepositoryFault.denied, msg);
      }
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw RepositoryFailure(
        RepositoryFault.offline,
        'Không thể kết nối đến máy chủ Backend ($baseUrl).',
      );
    }
  }

  Future<void> submitTenantOnboarding(Map<String, dynamic> requestData) async {
    final uri = Uri.parse('$baseUrl/auth/onboarding/tenant');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (accessToken != null && accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    try {
      final response = await client.post(
        uri,
        headers: headers,
        body: jsonEncode(requestData),
      );
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return;
      } else {
        final msg = body['message']?.toString() ?? 'Lưu thông tin khảo sát người thuê thất bại.';
        throw RepositoryFailure(RepositoryFault.server, msg);
      }
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw RepositoryFailure(
        RepositoryFault.offline,
        'Không thể kết nối đến máy chủ Backend ($baseUrl).',
      );
    }
  }

  Future<void> submitLandlordOnboarding(Map<String, dynamic> requestData) async {
    final uri = Uri.parse('$baseUrl/auth/onboarding/landlord');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (accessToken != null && accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    try {
      final response = await client.post(
        uri,
        headers: headers,
        body: jsonEncode(requestData),
      );
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return;
      } else {
        final msg = body['message']?.toString() ?? 'Lưu thông tin khảo sát chủ trọ thất bại.';
        throw RepositoryFailure(RepositoryFault.server, msg);
      }
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw RepositoryFailure(
        RepositoryFault.offline,
        'Không thể kết nối đến máy chủ Backend ($baseUrl).',
      );
    }
  }
}
