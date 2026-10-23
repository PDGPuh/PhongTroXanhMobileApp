import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/async_resource.dart';
import 'api_config.dart';

/// DTO gợi ý địa chỉ từ autocomplete (API #92)
class LocationPredictionDTO {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const LocationPredictionDTO({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory LocationPredictionDTO.fromJson(Map<String, dynamic> j) =>
      LocationPredictionDTO(
        placeId: j['placeId']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        mainText: j['mainText']?.toString() ?? '',
        secondaryText: j['secondaryText']?.toString() ?? '',
      );
}

/// DTO chuyển đổi địa chỉ thành tọa độ (API #93)
class GeocodeResultDTO {
  final double latitude;
  final double longitude;
  final String formattedAddress;

  const GeocodeResultDTO({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
  });

  factory GeocodeResultDTO.fromJson(Map<String, dynamic> j) => GeocodeResultDTO(
    latitude: (j['latitude'] as num?)?.toDouble() ?? 0.0,
    longitude: (j['longitude'] as num?)?.toDouble() ?? 0.0,
    formattedAddress: j['formattedAddress']?.toString() ?? '',
  );
}

/// DTO chuyển đổi tọa độ thành địa chỉ (API #94)
class ReverseGeocodeResultDTO {
  final String formattedAddress;

  const ReverseGeocodeResultDTO({required this.formattedAddress});

  factory ReverseGeocodeResultDTO.fromJson(Map<String, dynamic> j) =>
      ReverseGeocodeResultDTO(
        formattedAddress: j['formattedAddress']?.toString() ?? '',
      );
}

/// Repository gọi các API bản đồ Goong Maps qua Backend
/// Module Location:
/// - API #92: GET /api/v1/locations/autocomplete?input=...
/// - API #93: GET /api/v1/locations/geocode?address=...
/// - API #94: GET /api/v1/locations/reverse-geocode?lat=...&lng=...
class HttpLocationRepository {
  final String baseUrl;
  final http.Client client;
  final String? Function()? tokenProvider;

  HttpLocationRepository({
    String? baseUrl,
    http.Client? client,
    this.tokenProvider,
  }) : baseUrl = baseUrl ?? _resolveBaseUrl(),
       client = client ?? http.Client();

  static String _resolveBaseUrl() => ApiConfig.baseUrl;

  Map<String, String> get _headers {
    final token = tokenProvider?.call();
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

  /// API #92: Tự động hoàn thành địa chỉ (Autocomplete)
  /// GET /api/v1/locations/autocomplete?input=...
  Future<List<LocationPredictionDTO>> autocomplete(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return [];

    final encoded = Uri.encodeQueryComponent(trimmed);
    final res = await client.get(
      Uri.parse('$baseUrl/locations/autocomplete?input=$encoded'),
      headers: _headers,
    );
    final data = _parseData(res);
    if (data is Map<String, dynamic> && data['predictions'] is List) {
      final list = data['predictions'] as List;
      return list
          .map((e) => LocationPredictionDTO.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// API #93: Chuyển đổi địa chỉ sang tọa độ (Geocoding)
  /// GET /api/v1/locations/geocode?address=...
  Future<GeocodeResultDTO> geocode(String address) async {
    final encoded = Uri.encodeQueryComponent(address.trim());
    final res = await client.get(
      Uri.parse('$baseUrl/locations/geocode?address=$encoded'),
      headers: _headers,
    );
    final data = _parseData(res);
    return GeocodeResultDTO.fromJson(data as Map<String, dynamic>);
  }

  /// API #94: Chuyển đổi tọa độ sang địa chỉ (Reverse Geocoding)
  /// GET /api/v1/locations/reverse-geocode?lat=...&lng=...
  Future<ReverseGeocodeResultDTO> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final res = await client.get(
      Uri.parse('$baseUrl/locations/reverse-geocode?lat=$latitude&lng=$longitude'),
      headers: _headers,
    );
    final data = _parseData(res);
    return ReverseGeocodeResultDTO.fromJson(data as Map<String, dynamic>);
  }
}
