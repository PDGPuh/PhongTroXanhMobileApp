import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/async_resource.dart';
import 'api_config.dart';

/// DTO cho UserProfileResponse
class UserProfileDTO {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? bio;
  final String? gender;
  final String? birthday;
  final String? school;
  final List<String>? interests;
  final int trustScore;
  final bool verified;
  final String? kycStatus;
  final String? packageName;
  final int roomSwipeQuota;
  final int roommateSwipeQuota;

  const UserProfileDTO({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.bio,
    this.gender,
    this.birthday,
    this.school,
    this.interests,
    required this.trustScore,
    required this.verified,
    this.kycStatus,
    this.packageName,
    required this.roomSwipeQuota,
    required this.roommateSwipeQuota,
  });

  factory UserProfileDTO.fromJson(Map<String, dynamic> j) {
    // Map gender enum ("MALE" / "FEMALE" / "OTHER") to display string ("Nam" / "Nữ" / "Khác")
    final rawGender = (j['gender'] ?? '').toString().toUpperCase();
    final gender = switch (rawGender) {
      'FEMALE' || 'NỮ' || 'NU' => 'Nữ',
      'MALE' || 'NAM' => 'Nam',
      'OTHER' || 'KHÁC' || 'KHAC' => 'Khác',
      _ => rawGender.isNotEmpty ? j['gender']?.toString() : null,
    };

    // Parse birthDate or birthday (e.g. backend sends 'birthDate': '2003-05-12')
    final rawBirthday = (j['birthDate'] ?? j['birthday'])?.toString();
    String? birthday;
    if (rawBirthday != null && rawBirthday.isNotEmpty) {
      if (rawBirthday.contains('-')) {
        final parts = rawBirthday.split('-');
        if (parts.length == 3 && parts[0].length == 4) {
          // YYYY-MM-DD -> DD/MM/YYYY
          birthday = '${parts[2]}/${parts[1]}/${parts[0]}';
        } else {
          birthday = rawBirthday;
        }
      } else {
        birthday = rawBirthday;
      }
    }

    final rawInterests = (j['interests'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();

    return UserProfileDTO(
      id: j['id']?.toString() ?? '',
      fullName: j['fullName']?.toString() ?? '',
      email: j['email']?.toString() ?? '',
      phoneNumber: j['phoneNumber']?.toString(),
      avatarUrl: j['avatarUrl']?.toString(),
      bio: j['bio']?.toString(),
      gender: gender,
      birthday: birthday,
      school: (j['schoolOrCompany'] ?? j['school'])?.toString(),
      interests: rawInterests,
      trustScore: (j['trustScore'] as num?)?.toInt() ?? 0,
      verified: (j['isVerified'] ?? j['verified']) as bool? ?? false,
      kycStatus: j['kycStatus']?.toString(),
      packageName: j['packageName']?.toString(),
      roomSwipeQuota:
          (j['swipesLeft'] ?? j['roomSwipeQuota'] as num?)?.toInt() ?? 5,
      roommateSwipeQuota: (j['roommateSwipeQuota'] as num?)?.toInt() ?? 5,
    );
  }
}

class KycStatusDTO {
  final String status;
  final String? rejectionReason;
  final String? submittedAt;
  final String? reviewedAt;

  const KycStatusDTO({
    required this.status,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
  });

  factory KycStatusDTO.fromJson(Map<String, dynamic> j) => KycStatusDTO(
    status: j['status']?.toString() ?? 'NOT_SUBMITTED',
    rejectionReason: j['rejectionReason']?.toString(),
    submittedAt: j['submittedAt']?.toString(),
    reviewedAt: j['reviewedAt']?.toString(),
  );
}

class PackagePlanDTO {
  final String id;
  final String name;
  final String description;
  final int price;
  final int durationDays;
  final bool isActive;

  const PackagePlanDTO({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    required this.isActive,
  });

  factory PackagePlanDTO.fromJson(Map<String, dynamic> j) => PackagePlanDTO(
    id: j['id']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    description: j['description']?.toString() ?? '',
    price: (j['price'] as num?)?.toInt() ?? 0,
    durationDays: (j['durationDays'] as num?)?.toInt() ?? 30,
    isActive: j['isActive'] as bool? ?? true,
  );
}

class CreatePaymentResponseDTO {
  final String orderCode;
  final String paymentUrl;
  final String status;

  const CreatePaymentResponseDTO({
    required this.orderCode,
    required this.paymentUrl,
    required this.status,
  });

  factory CreatePaymentResponseDTO.fromJson(Map<String, dynamic> j) =>
      CreatePaymentResponseDTO(
        orderCode: j['orderCode']?.toString() ?? '',
        paymentUrl: j['paymentUrl']?.toString() ?? '',
        status: j['status']?.toString() ?? 'PENDING',
      );
}

class TrustScoreLogDTO {
  final String id;
  final int delta;
  final int finalScore;
  final String reason;
  final String? createdAt;

  const TrustScoreLogDTO({
    required this.id,
    required this.delta,
    required this.finalScore,
    required this.reason,
    this.createdAt,
  });

  factory TrustScoreLogDTO.fromJson(Map<String, dynamic> j) => TrustScoreLogDTO(
    id: j['id']?.toString() ?? '',
    delta: (j['delta'] as num?)?.toInt() ?? 0,
    finalScore: (j['finalScore'] as num?)?.toInt() ?? 0,
    reason: j['reason']?.toString() ?? '',
    createdAt: j['createdAt']?.toString(),
  );
}

class TrustScoreDTO {
  final int currentScore;
  final bool isVerified;
  final List<String> badges;
  final int kycScore;
  final int reviewScore;
  final int rentalDurationScore;
  final int responseRateScore;
  final List<TrustScoreLogDTO> history;

  const TrustScoreDTO({
    required this.currentScore,
    required this.isVerified,
    required this.badges,
    required this.kycScore,
    required this.reviewScore,
    required this.rentalDurationScore,
    required this.responseRateScore,
    required this.history,
  });

  factory TrustScoreDTO.fromJson(Map<String, dynamic> j) => TrustScoreDTO(
    currentScore: (j['currentScore'] as num?)?.toInt() ?? 0,
    isVerified: j['isVerified'] as bool? ?? false,
    badges: (j['badges'] as List?)?.map((e) => e.toString()).toList() ?? [],
    kycScore: (j['kycScore'] as num?)?.toInt() ?? 0,
    reviewScore: (j['reviewScore'] as num?)?.toInt() ?? 0,
    rentalDurationScore: (j['rentalDurationScore'] as num?)?.toInt() ?? 0,
    responseRateScore: (j['responseRateScore'] as num?)?.toInt() ?? 0,
    history: (j['history'] as List?)
            ?.map((e) => TrustScoreLogDTO.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

class UserSettingsDTO {
  final bool isPublic;
  final bool showSchool;
  final bool hideActiveStatus;

  const UserSettingsDTO({
    required this.isPublic,
    required this.showSchool,
    required this.hideActiveStatus,
  });

  factory UserSettingsDTO.fromJson(Map<String, dynamic> j) => UserSettingsDTO(
    isPublic: j['isPublic'] as bool? ?? true,
    showSchool: j['showSchool'] as bool? ?? true,
    hideActiveStatus: j['hideActiveStatus'] as bool? ?? false,
  );
}

class MatchingProfileDTO {
  final String userId;
  final num? budgetMin;
  final num? budgetMax;
  final List<String> preferredDistricts;
  final String? preferredGender;
  final String? preferredRoomType;
  final bool? earlySleeper;
  final bool? isNeat;
  final bool? allowGuests;
  final bool? nonSmoking;
  final int? noiseTolerance;
  final bool? proximitySchool;
  final bool? proximityWork;
  final bool? proximityMarket;
  final bool? proximityBus;
  final List<String> interests;

  const MatchingProfileDTO({
    required this.userId,
    this.budgetMin,
    this.budgetMax,
    this.preferredDistricts = const [],
    this.preferredGender,
    this.preferredRoomType,
    this.earlySleeper,
    this.isNeat,
    this.allowGuests,
    this.nonSmoking,
    this.noiseTolerance,
    this.proximitySchool,
    this.proximityWork,
    this.proximityMarket,
    this.proximityBus,
    this.interests = const [],
  });

  factory MatchingProfileDTO.fromJson(Map<String, dynamic> j) => MatchingProfileDTO(
    userId: j['userId']?.toString() ?? '',
    budgetMin: j['budgetMin'] as num?,
    budgetMax: j['budgetMax'] as num?,
    preferredDistricts: (j['preferredDistricts'] as List?)?.map((e) => e.toString()).toList() ?? [],
    preferredGender: j['preferredGender']?.toString(),
    preferredRoomType: j['preferredRoomType']?.toString(),
    earlySleeper: j['earlySleeper'] as bool?,
    isNeat: j['isNeat'] as bool?,
    allowGuests: j['allowGuests'] as bool?,
    nonSmoking: j['nonSmoking'] as bool?,
    noiseTolerance: (j['noiseTolerance'] as num?)?.toInt(),
    proximitySchool: j['proximitySchool'] as bool?,
    proximityWork: j['proximityWork'] as bool?,
    proximityMarket: j['proximityMarket'] as bool?,
    proximityBus: j['proximityBus'] as bool?,
    interests: (j['interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
  );
}

class PublicProfileDTO {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String role;
  final bool isVerified;
  final int trustScore;
  final String? lastActiveAt;
  final String? schoolOrCompany;
  final String? gender;
  final String? bio;
  final num? budgetMin;
  final num? budgetMax;
  final List<String> preferredDistricts;
  final String? preferredRoomType;
  final List<String> interests;
  final bool? earlySleeper;
  final bool? isNeat;
  final bool? allowGuests;
  final bool? nonSmoking;
  final int? noiseTolerance;

  const PublicProfileDTO({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    required this.isVerified,
    required this.trustScore,
    this.lastActiveAt,
    this.schoolOrCompany,
    this.gender,
    this.bio,
    this.budgetMin,
    this.budgetMax,
    this.preferredDistricts = const [],
    this.preferredRoomType,
    this.interests = const [],
    this.earlySleeper,
    this.isNeat,
    this.allowGuests,
    this.nonSmoking,
    this.noiseTolerance,
  });

  factory PublicProfileDTO.fromJson(Map<String, dynamic> j) => PublicProfileDTO(
    id: j['id']?.toString() ?? '',
    fullName: j['fullName']?.toString() ?? '',
    avatarUrl: j['avatarUrl']?.toString(),
    role: j['role']?.toString() ?? 'TENANT',
    isVerified: j['isVerified'] as bool? ?? false,
    trustScore: (j['trustScore'] as num?)?.toInt() ?? 0,
    lastActiveAt: j['lastActiveAt']?.toString(),
    schoolOrCompany: j['schoolOrCompany']?.toString(),
    gender: j['gender']?.toString(),
    bio: j['bio']?.toString(),
    budgetMin: j['budgetMin'] as num?,
    budgetMax: j['budgetMax'] as num?,
    preferredDistricts: (j['preferredDistricts'] as List?)?.map((e) => e.toString()).toList() ?? [],
    preferredRoomType: j['preferredRoomType']?.toString(),
    interests: (j['interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
    earlySleeper: j['earlySleeper'] as bool?,
    isNeat: j['isNeat'] as bool?,
    allowGuests: j['allowGuests'] as bool?,
    nonSmoking: j['nonSmoking'] as bool?,
    noiseTolerance: (j['noiseTolerance'] as num?)?.toInt(),
  );
}

class HttpUserRepository {
  final String baseUrl;
  final http.Client client;
  final String? Function() tokenProvider;

  HttpUserRepository({
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

  /// API #13: Xem thong tin ca nhan
  Future<UserProfileDTO> getMe() async {
    final res = await client.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );
    return UserProfileDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #14: Cap nhat thong tin co ban
  Future<UserProfileDTO> updateMe({
    required String fullName,
    String? gender,
    String? birthday,
    String? school,
    String? bio,
  }) async {
    // Map Vietnamese display gender to backend Gender enum
    final backendGender = switch (gender?.trim().toLowerCase()) {
      'nam' || 'male' => 'MALE',
      'nữ' || 'nu' || 'female' => 'FEMALE',
      'khác' || 'khac' || 'other' => 'OTHER',
      _ => gender,
    };

    // Format birthday to YYYY-MM-DD for backend LocalDate
    String? birthDate;
    if (birthday != null && birthday.trim().isNotEmpty) {
      final b = birthday.trim();
      if (b.contains('/')) {
        final parts = b.split('/');
        if (parts.length == 3) {
          // DD/MM/YYYY -> YYYY-MM-DD
          birthDate =
              '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        } else {
          birthDate = b;
        }
      } else {
        birthDate = b;
      }
    }

    final res = await client.put(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
      body: jsonEncode({
        'fullName': fullName,
        if (backendGender != null) 'gender': backendGender,
        if (birthDate != null) 'birthDate': birthDate,
        if (school != null) 'schoolOrCompany': school,
        if (bio != null) 'bio': bio,
      }),
    );
    return UserProfileDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #17: Cap nhat ma tran thoi quen sinh hoat
  Future<void> updateMatchingProfile({
    num? budgetMin,
    num? budgetMax,
    List<String>? preferredDistricts,
    String? preferredGender,
    String? preferredRoomType,
    bool? earlySleeper,
    bool? isNeat,
    bool? allowGuests,
    bool? nonSmoking,
    int? noiseTolerance,
    List<String>? interests,
  }) async {
    final res = await client.put(
      Uri.parse('$baseUrl/users/me/matching-profile'),
      headers: _headers,
      body: jsonEncode({
        if (budgetMin != null) 'budgetMin': budgetMin,
        if (budgetMax != null) 'budgetMax': budgetMax,
        if (preferredDistricts != null) 'preferredDistricts': preferredDistricts,
        if (preferredGender != null) 'preferredGender': preferredGender,
        if (preferredRoomType != null) 'preferredRoomType': preferredRoomType,
        if (earlySleeper != null) 'earlySleeper': earlySleeper,
        if (isNeat != null) 'isNeat': isNeat,
        if (allowGuests != null) 'allowGuests': allowGuests,
        if (nonSmoking != null) 'nonSmoking': nonSmoking,
        if (noiseTolerance != null) 'noiseTolerance': noiseTolerance,
        if (interests != null) 'interests': interests,
      }),
    );
    _checkStatus(res);
  }

  /// API #19: Nop ho so xac thuc CCCD/KYC
  Future<KycStatusDTO> submitKyc({
    required String cccdNumber,
    required String frontImageUrl,
    required String backImageUrl,
  }) async {
    final res = await client.post(
      Uri.parse('$baseUrl/users/me/kyc/cccd'),
      headers: _headers,
      body: jsonEncode({
        'cccdNumber': cccdNumber,
        'frontImageUrl': frontImageUrl,
        'backImageUrl': backImageUrl,
      }),
    );
    return KycStatusDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #20: Tra cuu trang thai KYC
  Future<KycStatusDTO> getKycStatus() async {
    final res = await client.get(
      Uri.parse('$baseUrl/users/me/kyc/status'),
      headers: _headers,
    );
    return KycStatusDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #73: Danh sach goi dich vu
  Future<List<PackagePlanDTO>> getPackagePlans() async {
    final res = await client.get(
      Uri.parse('$baseUrl/monetization/plans'),
      headers: _headers,
    );
    final list = _parseData(res) as List<dynamic>;
    return list
        .map((e) => PackagePlanDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// API #74: Khoi tao thanh toan payOS
  Future<CreatePaymentResponseDTO> createPayment({
    required String planId,
    String paymentMethod = 'PAYOS',
  }) async {
    final res = await client.post(
      Uri.parse('$baseUrl/monetization/create-payment'),
      headers: _headers,
      body: jsonEncode({'planId': planId, 'paymentMethod': paymentMethod}),
    );
    return CreatePaymentResponseDTO.fromJson(
      _parseData(res) as Map<String, dynamic>,
    );
  }

  /// API #77: Lich su giao dich
  Future<List<Map<String, dynamic>>> getMyTransactions() async {
    final res = await client.get(
      Uri.parse('$baseUrl/monetization/transactions/me'),
      headers: _headers,
    );
    final list = _parseData(res) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// API #78: So du luot quay va luot day tin
  Future<Map<String, dynamic>> getConsumableBalance() async {
    final res = await client.get(
      Uri.parse('$baseUrl/monetization/consumables/me'),
      headers: _headers,
    );
    return (_parseData(res) as Map<String, dynamic>?) ?? {};
  }

  /// API #15: Tải lên ảnh đại diện
  Future<String> uploadAvatar(List<int> bytes, String filename) async {
    final uri = Uri.parse('$baseUrl/users/me/avatar');
    final req = http.MultipartRequest('POST', uri);
    final token = tokenProvider();
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamed = await client.send(req);
    final res = await http.Response.fromStream(streamed);
    final data = _parseData(res) as Map<String, dynamic>;
    return data['avatarUrl']?.toString() ?? '';
  }

  /// API #16: Xem ma trận thói quen sinh hoạt
  Future<MatchingProfileDTO> getMatchingProfile() async {
    final res = await client.get(
      Uri.parse('$baseUrl/users/me/matching-profile'),
      headers: _headers,
    );
    return MatchingProfileDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #18: Xem chi tiết điểm uy tín TrustScore
  Future<TrustScoreDTO> getTrustScore() async {
    final res = await client.get(
      Uri.parse('$baseUrl/users/me/trust-score'),
      headers: _headers,
    );
    return TrustScoreDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #21: Xem hồ sơ công khai của người dùng
  Future<PublicProfileDTO> getPublicProfile(String userId) async {
    final res = await client.get(
      Uri.parse('$baseUrl/users/$userId/public'),
      headers: _headers,
    );
    return PublicProfileDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #22: Lấy cấu hình thông báo & quyền riêng tư
  Future<UserSettingsDTO> getSettings() async {
    final res = await client.get(
      Uri.parse('$baseUrl/users/me/settings'),
      headers: _headers,
    );
    return UserSettingsDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #23: Cập nhật cấu hình thông báo & quyền riêng tư
  Future<UserSettingsDTO> updateSettings({
    bool? isPublic,
    bool? showSchool,
    bool? hideActiveStatus,
  }) async {
    final res = await client.put(
      Uri.parse('$baseUrl/users/me/settings'),
      headers: _headers,
      body: jsonEncode({
        if (isPublic != null) 'isPublic': isPublic,
        if (showSchool != null) 'showSchool': showSchool,
        if (hideActiveStatus != null) 'hideActiveStatus': hideActiveStatus,
      }),
    );
    return UserSettingsDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// API #24: Yêu cầu xóa tài khoản
  Future<void> deleteAccount() async {
    final res = await client.delete(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );
    _checkStatus(res);
  }
}
