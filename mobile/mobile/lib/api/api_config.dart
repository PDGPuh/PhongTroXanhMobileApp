import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  /// Base URL mặc định cho ứng dụng.
  /// - Có thể ghi đè lúc build bằng flag: --dart-define=API_BASE_URL=https://...
  /// - Web chạy local: http://localhost:8080/api/v1
  /// - Android (máy thật / APK release): https://phongtroxanh-backend.onrender.com/api/v1
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) return 'http://localhost:8080/api/v1';

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Điện thoại thật hoặc giả lập gọi về backend Render online
        return 'https://phongtroxanh-backend.onrender.com/api/v1';
      }
    } catch (_) {}

    return 'https://phongtroxanh-backend.onrender.com/api/v1';
  }
}
