import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/async_resource.dart';
import '../domain/models.dart';
import 'api_config.dart';

/// DTO mapping cho RentalResponse từ backend
class RentalDTO {
  final String id;
  final String roomId;
  final String roomTitle;
  final String roomAddress;
  final String tenantId;
  final String tenantName;
  final String landlordId;
  final String landlordName;
  final String startDate;
  final String endDate;
  final double monthlyRent;
  final double depositAmount;
  final String status;
  final String? checkInAt;
  final String createdAt;

  final String? tenantPhone;
  final String? landlordPhone;
  final int? tenantTrustScore;

  const RentalDTO({
    required this.id,
    required this.roomId,
    required this.roomTitle,
    required this.roomAddress,
    required this.tenantId,
    required this.tenantName,
    this.tenantPhone,
    required this.landlordId,
    required this.landlordName,
    this.landlordPhone,
    this.tenantTrustScore,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.depositAmount,
    required this.status,
    this.checkInAt,
    required this.createdAt,
  });

  factory RentalDTO.fromJson(Map<String, dynamic> j) => RentalDTO(
    id: j['id']?.toString() ?? '',
    roomId: j['roomId']?.toString() ?? '',
    roomTitle: j['roomTitle']?.toString() ?? '',
    roomAddress: j['roomAddress']?.toString() ?? '',
    tenantId: j['tenantId']?.toString() ?? '',
    tenantName: j['tenantName']?.toString() ?? '',
    tenantPhone: j['tenantPhone']?.toString(),
    landlordId: j['landlordId']?.toString() ?? '',
    landlordName: j['landlordName']?.toString() ?? '',
    landlordPhone: j['landlordPhone']?.toString(),
    tenantTrustScore: (j['tenantTrustScore'] as num?)?.toInt(),
    startDate: j['startDate']?.toString() ?? '',
    endDate: j['endDate']?.toString() ?? '',
    monthlyRent: (j['monthlyRent'] as num?)?.toDouble() ?? 0,
    depositAmount: (j['depositAmount'] as num?)?.toDouble() ?? 0,
    status: j['status']?.toString() ?? 'PENDING',
    checkInAt: j['checkInAt']?.toString(),
    createdAt: j['createdAt']?.toString() ?? '',
  );

  /// Chuyển thành domain Rental để UI hiện tại dùng được
  Rental toRental() {
    final parsedStatus = _parseStatus(status);
    return Rental(
      Room(
        id: roomId,
        title: roomTitle,
        district: '',
        price: monthlyRent.toInt(),
        address: roomAddress,
        landlordId: landlordId,
        landlordName: landlordName,
      ),
      'QR-$id',
      id: id,
      tenantId: tenantId,
      landlordId: landlordId,
      status: parsedStatus,
      checkedIn: checkInAt != null,
      codeExpiresAt: null,
    );
  }

  static RentalStatus _parseStatus(String s) => switch (s.toUpperCase()) {
    'ACTIVE' || 'CHECKED_IN' => RentalStatus.active,
    'EXPIRED' || 'COMPLETED' => RentalStatus.expired,
    'TERMINATED' => RentalStatus.terminated,
    _ => RentalStatus.pending,
  };
}

class CheckInQrDTO {
  final String rentalId;
  final String qrCodePayload;
  final String expiresAt;

  const CheckInQrDTO({
    required this.rentalId,
    required this.qrCodePayload,
    required this.expiresAt,
  });

  factory CheckInQrDTO.fromJson(Map<String, dynamic> j) => CheckInQrDTO(
    rentalId: j['rentalId']?.toString() ?? '',
    qrCodePayload: j['qrCodePayload']?.toString() ?? '',
    expiresAt: j['expiresAt']?.toString() ?? '',
  );
}

class HttpRentalRepository {
  final String baseUrl;
  final http.Client client;
  final String? Function() tokenProvider;

  HttpRentalRepository({
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

  /// API #53: Tao yeu cau thue phong
  Future<RentalDTO> createRental({
    required String roomId,
    required String startDate,
    required String endDate,
    String? message,
  }) async {
    final res = await client.post(
      Uri.parse('$baseUrl/rentals'),
      headers: _headers,
      body: jsonEncode({
        'roomId': roomId,
        'startDate': startDate,
        'endDate': endDate,
        if (message != null && message.isNotEmpty) 'message': message,
      }),
    );
    return RentalDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #54: Chi tiet hop dong
  Future<RentalDTO> getRentalDetail(String id) async {
    final res = await client.get(
      Uri.parse('$baseUrl/rentals/$id'),
      headers: _headers,
    );
    return RentalDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #55: Danh sach hop dong cua tenant
  Future<List<RentalDTO>> getMyTenantRentals() async {
    final res = await client.get(
      Uri.parse('$baseUrl/rentals/tenant/me'),
      headers: _headers,
    );
    final list = _parseData(res) as List<dynamic>;
    return list
        .map((e) => RentalDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// API #56: Danh sach hop dong cua landlord
  Future<List<RentalDTO>> getMyLandlordRentals() async {
    final res = await client.get(
      Uri.parse('$baseUrl/rentals/landlord/me'),
      headers: _headers,
    );
    final list = _parseData(res) as List<dynamic>;
    return list
        .map((e) => RentalDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// API #57: Tao ma QR Check-in
  Future<CheckInQrDTO> getCheckInQr(String rentalId) async {
    final res = await client.get(
      Uri.parse('$baseUrl/rentals/$rentalId/check-in-qr'),
      headers: _headers,
    );
    return CheckInQrDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #58: Xac nhan check-in bang ma QR
  Future<RentalDTO> verifyCheckIn(String rentalId, String checkInCode) async {
    final res = await client.post(
      Uri.parse('$baseUrl/rentals/$rentalId/check-in'),
      headers: _headers,
      body: jsonEncode({'checkInCode': checkInCode}),
    );
    return RentalDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #59: Ket thuc hop dong
  Future<RentalDTO> terminateRental(String rentalId) async {
    final res = await client.post(
      Uri.parse('$baseUrl/rentals/$rentalId/terminate'),
      headers: _headers,
      body: '{}',
    );
    return RentalDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }
}
