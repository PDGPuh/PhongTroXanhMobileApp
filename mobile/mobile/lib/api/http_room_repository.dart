import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/async_resource.dart';
import '../domain/models.dart';
import '../features/rooms/room_controller.dart';
import 'api_config.dart';

/// HTTP implementation of [RoomRepository] — calls the real Spring Boot backend.
class HttpRoomRepository implements RoomRepository {
  final String baseUrl;
  final http.Client client;
  final String? Function() tokenProvider;

  HttpRoomRepository({
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

  /// API #25: GET /api/v1/rooms
  @override
  Future<List<Room>> discover() async {
    final uri = Uri.parse('$baseUrl/rooms').replace(queryParameters: {
      'limit': '50',
      'sortBy': 'boost_first',
    });
    try {
      final response = await client.get(uri, headers: _headers());
      final Map<String, dynamic> body =
          jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        final content = data?['content'] as List<dynamic>? ?? [];
        return content.map((e) => _roomFromJson(e as Map<String, dynamic>)).toList();
      }
      throw RepositoryFailure(
        RepositoryFault.server,
        body['message']?.toString() ?? 'Không thể tải danh sách phòng.',
      );
    } on RepositoryFailure {
      rethrow;
    } catch (_) {
      throw const RepositoryFailure(
        RepositoryFault.offline,
        'Không thể kết nối đến máy chủ. Vui lòng thử lại.',
      );
    }
  }

  /// API #28: GET /api/v1/rooms/{id}
  @override
  Future<Room?> find(String id) async {
    final uri = Uri.parse('$baseUrl/rooms/$id');
    try {
      final response = await client.get(uri, headers: _headers());
      final Map<String, dynamic> body =
          jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 404) return null;
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data == null) return null;
        return _roomFromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// API #32: POST /api/v1/rooms (Đăng phòng mới)
  Future<Room> createRoom(Room room) async {
    final uri = Uri.parse('$baseUrl/rooms');
    try {
      final response = await client.post(
        uri,
        headers: _headers(),
        body: jsonEncode({
          'title': room.title,
          'description': room.description,
          'roomType': room.type,
          'price': room.price,
          'depositAmount': room.price,
          'areaSqm': room.area,
          'floorNumber': room.floor,
          'maxOccupants': 2,
          'addressStreet': room.address,
          'district': room.district,
          'city': 'TP. Hồ Chí Minh',
          'latitude': room.latitude ?? 10.7626,
          'longitude': room.longitude ?? 106.6697,
        }),
      );
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        return _roomFromJson(data);
      }
      throw RepositoryFailure(RepositoryFault.server, body['message']?.toString() ?? 'Đăng tin phòng thất bại');
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }

  /// API #33: PUT /api/v1/rooms/{id} (Chỉnh sửa phòng)
  Future<Room> updateRoom(String id, Room room) async {
    final uri = Uri.parse('$baseUrl/rooms/$id');
    try {
      final response = await client.put(
        uri,
        headers: _headers(),
        body: jsonEncode({
          'title': room.title,
          'description': room.description,
          'roomType': room.type,
          'price': room.price,
          'depositAmount': room.price,
          'areaSqm': room.area,
          'floorNumber': room.floor,
          'maxOccupants': 2,
          'addressStreet': room.address,
          'district': room.district,
          'city': 'TP. Hồ Chí Minh',
          'latitude': room.latitude ?? 10.7626,
          'longitude': room.longitude ?? 106.6697,
        }),
      );
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        return _roomFromJson(data);
      }
      throw RepositoryFailure(RepositoryFault.server, body['message']?.toString() ?? 'Cập nhật phòng thất bại');
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }

  /// API #34: DELETE /api/v1/rooms/{id} (Ẩn/xóa phòng)
  Future<void> deleteRoom(String id) async {
    final uri = Uri.parse('$baseUrl/rooms/$id');
    try {
      final response = await client.delete(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return;
      }
      throw RepositoryFailure(RepositoryFault.denied, body['message']?.toString() ?? 'Ẩn tin thất bại');
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }

  /// API #37: GET /api/v1/rooms/landlord/me
  Future<List<Room>> getMyLandlordRooms() async {
    final uri = Uri.parse('$baseUrl/rooms/landlord/me');
    try {
      final response = await client.get(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final List<dynamic> list = body['data'] as List<dynamic>? ?? [];
        return list.map((e) => _roomFromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// API #29: POST /api/v1/rooms/{id}/save
  Future<void> saveRoom(String id) async {
    final uri = Uri.parse('$baseUrl/rooms/$id/save');
    try {
      await client.post(uri, headers: _headers());
    } catch (_) {}
  }

  /// API #30: DELETE /api/v1/rooms/{id}/save
  Future<void> unsaveRoom(String id) async {
    final uri = Uri.parse('$baseUrl/rooms/$id/save');
    try {
      await client.delete(uri, headers: _headers());
    } catch (_) {}
  }

  /// API #31: GET /api/v1/rooms/saved/me
  Future<List<Room>> getSavedRooms() async {
    final uri = Uri.parse('$baseUrl/rooms/saved/me');
    try {
      final response = await client.get(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final List<dynamic> list = body['data'] as List<dynamic>? ?? [];
        return list.map((e) => _roomFromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// API #39: GET /api/v1/landlord/analytics/overview (Module 3)
  Future<LandlordAnalyticsDTO?> getLandlordAnalytics() async {
    final uri = Uri.parse('$baseUrl/landlord/analytics/overview');
    try {
      final response = await client.get(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return LandlordAnalyticsDTO.fromJson(data);
        }
      }
    } catch (_) {}
    return null;
  }

  /// API #38: POST /api/v1/rooms/{id}/boost
  Future<void> boostRoom(String id) async {
    final uri = Uri.parse('$baseUrl/rooms/$id/boost');
    try {
      final response = await client.post(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return;
      }
      throw RepositoryFailure(RepositoryFault.denied, body['message']?.toString() ?? 'Đẩy tin thất bại');
    } on RepositoryFailure {
      rethrow;
    } catch (e) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }

  /// API #39: POST /api/v1/rooms/{id}/swipe
  Future<void> swipeRoom(String id, bool like) async {
    final uri = Uri.parse('$baseUrl/rooms/$id/swipe');
    try {
      await client.post(
        uri,
        headers: _headers(),
        body: jsonEncode({'action': like ? 'LIKE' : 'PASS'}),
      );
    } catch (_) {}
  }

  /// API #38b: POST /api/v1/rooms/{id}/renew (Gia hạn tin đăng phòng)
  Future<void> renewRoom(String id) async {
    final uri = Uri.parse('$baseUrl/rooms/$id/renew');
    try {
      final response = await client.post(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        return;
      }
      throw RepositoryFailure(RepositoryFault.denied, body['message']?.toString() ?? 'Gia hạn phòng thất bại');
    } on RepositoryFailure {
      rethrow;
    } catch (_) {
      throw const RepositoryFailure(RepositoryFault.offline, 'Không thể kết nối đến máy chủ.');
    }
  }

  /// API #35: POST /api/v1/rooms/{id}/images (Tải lên hình ảnh phòng)
  Future<List<String>> uploadRoomImages(String id, List<List<int>> filesBytes, List<String> filenames) async {
    final uri = Uri.parse('$baseUrl/rooms/$id/images');
    try {
      final req = http.MultipartRequest('POST', uri);
      final token = tokenProvider();
      if (token != null && token.isNotEmpty) req.headers['Authorization'] = 'Bearer $token';
      for (var i = 0; i < filesBytes.length; i++) {
        req.files.add(http.MultipartFile.fromBytes('files', filesBytes[i], filename: filenames[i]));
      }
      final streamed = await client.send(req);
      final res = await http.Response.fromStream(streamed);
      final Map<String, dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
        final list = body['data'] as List<dynamic>? ?? [];
        return list.map((img) => (img['imageUrl'] ?? img['url'] ?? '').toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  /// API #36: DELETE /api/v1/rooms/{id}/images/{imageId} (Xóa hình ảnh phòng)
  Future<void> deleteRoomImage(String id, String imageId) async {
    final uri = Uri.parse('$baseUrl/rooms/$id/images/$imageId');
    try {
      await client.delete(uri, headers: _headers());
    } catch (_) {}
  }

  /// API #39b: DELETE /api/v1/rooms/swipes/me (Đặt lại lịch sử quẹt phòng)
  Future<void> resetSwipes() async {
    final uri = Uri.parse('$baseUrl/rooms/swipes/me');
    try {
      await client.delete(uri, headers: _headers());
    } catch (_) {}
  }

  /// API #26: GET /api/v1/rooms/map (Lấy danh sách ghim bản đồ PostGIS)
  Future<List<MapPinDTO>> getRoomsOnMap({
    double lat = 10.776,
    double lng = 106.667,
    double radiusKm = 30.0,
    double? minPrice,
    double? maxPrice,
    String? district,
    String? roomType,
  }) async {
    final queryParams = <String, String>{
      'lat': lat.toString(),
      'lng': lng.toString(),
      'radiusKm': radiusKm.toString(),
      if (minPrice != null) 'minPrice': minPrice.toInt().toString(),
      if (maxPrice != null) 'maxPrice': maxPrice.toInt().toString(),
      if (district != null && district.isNotEmpty) 'district': district,
      if (roomType != null && roomType.isNotEmpty) 'roomType': roomType,
    };
    final uri = Uri.parse('$baseUrl/rooms/map').replace(queryParameters: queryParams);
    try {
      final response = await client.get(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final list = body['data'] as List<dynamic>? ?? [];
        return list.map((e) => MapPinDTO.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// API #27: GET /api/v1/rooms/compare?ids=... (So sánh phòng trọ)
  Future<List<Room>> compareRooms(List<String> ids) async {
    final uri = Uri.parse('$baseUrl/rooms/compare').replace(queryParameters: {
      'ids': ids.join(','),
    });
    try {
      final response = await client.get(uri, headers: _headers());
      final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        final list = data?['rooms'] as List<dynamic>? ?? [];
        return list.map((e) => _roomFromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Room _roomFromJson(Map<String, dynamic> e) {
    final amenities = (e['amenities'] as List<dynamic>? ?? [])
        .map((a) => a.toString())
        .toList();

    final rawType = (e['roomType'] ?? e['type'] ?? 'Studio').toString();
    final rawStatus = (e['status'] ?? 'AVAILABLE').toString().toUpperCase();
    final status = switch (rawStatus) {
      'AVAILABLE' => RoomStatus.available,
      'RENTED' => RoomStatus.rented,
      'HIDDEN' => RoomStatus.hidden,
      'PENDING' => RoomStatus.pending,
      _ => RoomStatus.available,
    };

    final price = () {
      final raw = e['price'] ?? e['monthlyRent'] ?? 0;
      if (raw is num) return raw.toInt();
      return int.tryParse(raw.toString()) ?? 0;
    }();

    final area = () {
      final raw = e['area'] ?? e['areaM2'] ?? 20;
      if (raw is num) return raw.toInt();
      return int.tryParse(raw.toString()) ?? 20;
    }();

    final lat = () {
      final raw = e['lat'] ?? e['latitude'];
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString() ?? '');
    }();

    final lng = () {
      final raw = e['lng'] ?? e['longitude'];
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString() ?? '');
    }();

    final landlordObj = e['landlord'] is Map<String, dynamic>
        ? e['landlord'] as Map<String, dynamic>
        : null;
    final landlordId = (landlordObj?['id'] ?? e['landlordId'] ?? e['ownerId'] ?? '').toString();
    final landlordName = (landlordObj?['fullName'] ?? e['landlordName'] ?? e['ownerName'] ?? '').toString();
    final landlordAvatar = (landlordObj?['avatarUrl'] ?? e['landlordAvatarUrl'] ?? e['avatarUrl'] ?? '').toString();
    final landlordPhone = (landlordObj?['phoneNumber'] ?? e['landlordPhone'] ?? e['phoneNumber'] ?? '').toString();

    return Room(
      id: (e['id'] ?? '').toString(),
      title: (e['title'] ?? 'Phòng trọ').toString(),
      address: (e['address'] ?? '').toString(),
      district: (e['district'] ?? 'Quận 10').toString(),
      price: price,
      type: rawType,
      area: area,
      amenities: amenities,
      status: status,
      landlordId: landlordId,
      landlordName: landlordName.isNotEmpty ? landlordName : 'Chủ trọ đối tác',
      landlordAvatarUrl: landlordAvatar.isNotEmpty ? landlordAvatar : null,
      landlordPhone: landlordPhone.isNotEmpty ? landlordPhone : null,
      description: (e['description'] ?? '').toString(),
      latitude: lat,
      longitude: lng,
    );
  }
}

/// Fetches landing page statistics from API #12: GET /api/v1/misc/landing-stats
class HttpMiscRepository {
  final String baseUrl;
  final http.Client client;

  HttpMiscRepository({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? _resolveBaseUrl(),
        client = client ?? http.Client();

  static String _resolveBaseUrl() => ApiConfig.baseUrl;

  Future<LandingStats?> getLandingStats() async {
    final uri = Uri.parse('$baseUrl/misc/landing-stats');
    try {
      final response = await client.get(uri);
      final Map<String, dynamic> body =
          jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data == null) return null;
        return LandingStats(
          availableRoomsCount: (data['availableRoomsCount'] as num?)?.toInt() ?? 0,
          matchedPairsCount: (data['matchedPairsCount'] as num?)?.toInt() ?? 0,
          activeUsersCount: (data['activeUsersCount'] as num?)?.toInt() ?? 0,
          positiveReviewRate: (data['positiveReviewRate'] as num?)?.toDouble() ?? 0.0,
        );
      }
    } catch (_) {}
    return null;
  }
}

/// Simple model for landing stats
class LandingStats {
  final int availableRoomsCount;
  final int matchedPairsCount;
  final int activeUsersCount;
  final double positiveReviewRate;
  LandingStats({
    required this.availableRoomsCount,
    required this.matchedPairsCount,
    required this.activeUsersCount,
    required this.positiveReviewRate,
  });
}

/// Model for Module 3: Landlord Analytics
class LandlordAnalyticsDTO {
  final int totalRooms;
  final int activeRooms;
  final int rentedRooms;
  final int totalViews;
  final int totalContacts;
  final double occupancyRate;
  final Map<String, int> viewsChart7Days;

  LandlordAnalyticsDTO({
    required this.totalRooms,
    required this.activeRooms,
    required this.rentedRooms,
    required this.totalViews,
    required this.totalContacts,
    required this.occupancyRate,
    this.viewsChart7Days = const {},
  });

  factory LandlordAnalyticsDTO.fromJson(Map<String, dynamic> j) {
    final chartRaw = j['viewsChart7Days'] as Map<String, dynamic>? ?? {};
    final chart = <String, int>{};
    chartRaw.forEach((k, v) {
      chart[k] = (v as num?)?.toInt() ?? 0;
    });

    return LandlordAnalyticsDTO(
      totalRooms: (j['totalRooms'] as num?)?.toInt() ?? 0,
      activeRooms: (j['activeRooms'] as num?)?.toInt() ?? 0,
      rentedRooms: (j['rentedRooms'] as num?)?.toInt() ?? 0,
      totalViews: (j['totalViews'] as num?)?.toInt() ?? 0,
      totalContacts: (j['totalContacts'] as num?)?.toInt() ?? 0,
      occupancyRate: (j['occupancyRate'] as num?)?.toDouble() ?? 0.0,
      viewsChart7Days: chart,
    );
  }
}

/// DTO for API #26: GET /api/v1/rooms/map (PostGIS Map Pins)
class MapPinDTO {
  final String id;
  final String title;
  final int price;
  final double latitude;
  final double longitude;
  final String? primaryImageUrl;
  final String? roomType;
  final bool isBoosted;
  final String? district;

  MapPinDTO({
    required this.id,
    required this.title,
    required this.price,
    required this.latitude,
    required this.longitude,
    this.primaryImageUrl,
    this.roomType,
    this.isBoosted = false,
    this.district,
  });

  factory MapPinDTO.fromJson(Map<String, dynamic> j) => MapPinDTO(
    id: (j['id'] ?? '').toString(),
    title: (j['title'] ?? '').toString(),
    price: (j['price'] as num?)?.toInt() ?? 0,
    latitude: (j['latitude'] as num?)?.toDouble() ?? (j['lat'] as num?)?.toDouble() ?? 10.776,
    longitude: (j['longitude'] as num?)?.toDouble() ?? (j['lng'] as num?)?.toDouble() ?? 106.667,
    primaryImageUrl: j['primaryImageUrl']?.toString() ?? j['image']?.toString(),
    roomType: j['roomType']?.toString() ?? j['type']?.toString(),
    isBoosted: j['isBoosted'] as bool? ?? false,
    district: j['district']?.toString(),
  );
}

