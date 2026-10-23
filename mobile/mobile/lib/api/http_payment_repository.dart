import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/async_resource.dart';
import 'api_config.dart';

/// DTO cho PackagePlan từ backend
class PackagePlanDTO {
  final String id;
  final String targetRole; // TENANT, LANDLORD, ADMIN
  final String name;
  final double priceMonthly;
  final double priceYearly;
  final String features; // JSON string

  const PackagePlanDTO({
    required this.id,
    required this.targetRole,
    required this.name,
    required this.priceMonthly,
    required this.priceYearly,
    required this.features,
  });

  factory PackagePlanDTO.fromJson(Map<String, dynamic> j) => PackagePlanDTO(
    id: j['id']?.toString() ?? '',
    targetRole: j['targetRole']?.toString() ?? 'TENANT',
    name: j['name']?.toString() ?? '',
    priceMonthly: (j['priceMonthly'] as num?)?.toDouble() ?? 0.0,
    priceYearly: (j['priceYearly'] as num?)?.toDouble() ?? 0.0,
    features: j['features']?.toString() ?? '',
  );

  Map<String, dynamic> parseFeatures() {
    try {
      return jsonDecode(features) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  int get boosts {
    final f = parseFeatures();
    return (f['boosts'] as num?)?.toInt() ?? 0;
  }

  int get swipesPerDay {
    final f = parseFeatures();
    return (f['swipes_per_day'] as num?)?.toInt() ?? 15;
  }
}

/// DTO cho phản hồi khởi tạo thanh toán payOS (API #74)
class CreatePaymentResponseDTO {
  final String transactionCode;
  final String paymentMethod;
  final double amount;
  final String paymentUrl;
  final String? qrCode;
  final String? paymentLinkId;

  const CreatePaymentResponseDTO({
    required this.transactionCode,
    required this.paymentMethod,
    required this.amount,
    required this.paymentUrl,
    this.qrCode,
    this.paymentLinkId,
  });

  factory CreatePaymentResponseDTO.fromJson(Map<String, dynamic> j) =>
      CreatePaymentResponseDTO(
        transactionCode:
            j['transactionCode']?.toString() ??
            j['orderCode']?.toString() ??
            '',
        paymentMethod: j['paymentMethod']?.toString() ?? 'PAYOS',
        amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
        paymentUrl: j['paymentUrl']?.toString() ?? '',
        qrCode: j['qrCode']?.toString(),
        paymentLinkId: j['paymentLinkId']?.toString(),
      );
}

/// DTO cho lịch sử giao dịch (API #77)
class TransactionDTO {
  final String id;
  final String transactionCode;
  final String packageId;
  final double amount;
  final String paymentMethod;
  final String status;
  final String? vnpTransactionNo;
  final String? createdAt;

  const TransactionDTO({
    required this.id,
    required this.transactionCode,
    required this.packageId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.vnpTransactionNo,
    this.createdAt,
  });

  factory TransactionDTO.fromJson(Map<String, dynamic> j) => TransactionDTO(
    id: j['id']?.toString() ?? '',
    transactionCode: j['transactionCode']?.toString() ?? '',
    packageId: j['packageId']?.toString() ?? '',
    amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
    paymentMethod: j['paymentMethod']?.toString() ?? 'PAYOS',
    status: j['status']?.toString() ?? 'PENDING',
    vnpTransactionNo: j['vnpTransactionNo']?.toString(),
    createdAt: j['createdAt']?.toString(),
  );
}

/// DTO cho số dư lượt quẹt & lượt đẩy tin (API #78)
class ConsumableBalanceDTO {
  final int swipesLeft;
  final int boostsLeft;

  const ConsumableBalanceDTO({
    required this.swipesLeft,
    required this.boostsLeft,
  });

  factory ConsumableBalanceDTO.fromJson(Map<String, dynamic> j) =>
      ConsumableBalanceDTO(
        swipesLeft: (j['swipesLeft'] as num?)?.toInt() ?? 0,
        boostsLeft: (j['boostsLeft'] as num?)?.toInt() ?? 0,
      );
}

/// DTO cho gói đang hoạt động của tôi
class ActiveSubscriptionDTO {
  final String planId;
  final String planName;
  final String? endDate;

  const ActiveSubscriptionDTO({
    required this.planId,
    required this.planName,
    this.endDate,
  });

  factory ActiveSubscriptionDTO.fromJson(Map<String, dynamic> j) =>
      ActiveSubscriptionDTO(
        planId: j['planId']?.toString() ?? '',
        planName: j['planName']?.toString() ?? '',
        endDate: j['endDate']?.toString(),
      );
}

/// Repository HTTP cho Module 9: Monetization, Packages & Payments
class HttpPaymentRepository {
  final String baseUrl;
  final http.Client client;
  final String? Function() tokenProvider;

  HttpPaymentRepository({
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
    final msg =
        body['detail']?.toString() ??
        body['message']?.toString() ??
        'Lỗi ${res.statusCode}';
    throw RepositoryFailure(RepositoryFault.server, msg);
  }

  dynamic _parseData(http.Response res) {
    _checkStatus(res);
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return body['data'];
  }

  /// API #73: Danh sách gói dịch vụ
  Future<List<PackagePlanDTO>> getPlans() async {
    final res = await client.get(
      Uri.parse('$baseUrl/monetization/plans'),
      headers: _headers,
    );
    final list = _parseData(res) as List<dynamic>;
    return list
        .map((e) => PackagePlanDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admin: Tạo gói dịch vụ mới
  Future<PackagePlanDTO> createPlan({
    String? id,
    required String targetRole,
    required String name,
    required double priceMonthly,
    required double priceYearly,
    required String features,
  }) async {
    final res = await client.post(
      Uri.parse('$baseUrl/monetization/admin/plans'),
      headers: _headers,
      body: jsonEncode({
        if (id != null && id.isNotEmpty) 'id': id,
        'targetRole': targetRole,
        'name': name,
        'priceMonthly': priceMonthly,
        'priceYearly': priceYearly,
        'features': features,
      }),
    );
    return PackagePlanDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// Admin: Cập nhật gói dịch vụ
  Future<PackagePlanDTO> updatePlan(
    String id, {
    required String targetRole,
    required String name,
    required double priceMonthly,
    required double priceYearly,
    required String features,
  }) async {
    final res = await client.put(
      Uri.parse('$baseUrl/monetization/admin/plans/$id'),
      headers: _headers,
      body: jsonEncode({
        'targetRole': targetRole,
        'name': name,
        'priceMonthly': priceMonthly,
        'priceYearly': priceYearly,
        'features': features,
      }),
    );
    return PackagePlanDTO.fromJson(_parseData(res) as Map<String, dynamic>);
  }

  /// Admin: Xóa gói dịch vụ
  Future<void> deletePlan(String id) async {
    final res = await client.delete(
      Uri.parse('$baseUrl/monetization/admin/plans/$id'),
      headers: _headers,
    );
    _checkStatus(res);
  }

  /// API #74: Khởi tạo thanh toán payOS
  Future<CreatePaymentResponseDTO> createPayment({
    required String packageId,
    String paymentMethod = 'PAYOS',
    String? returnUrl,
  }) async {
    final payload = <String, dynamic>{
      'packageId': packageId,
      'paymentMethod': paymentMethod,
    };
    if (returnUrl != null) payload['returnUrl'] = returnUrl;
    final res = await client.post(
      Uri.parse('$baseUrl/monetization/create-payment'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    return CreatePaymentResponseDTO.fromJson(
      _parseData(res) as Map<String, dynamic>,
    );
  }

  /// API #76: Đọc trạng thái thanh toán
  Future<Map<String, String>> getPaymentResult(String orderCode) async {
    final res = await client.get(
      Uri.parse('$baseUrl/monetization/payos-return?orderCode=$orderCode'),
      headers: _headers,
    );
    final data = _parseData(res) as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, v.toString()));
  }

  /// API #77: Lịch sử giao dịch của tôi
  Future<List<TransactionDTO>> getMyTransactions() async {
    final res = await client.get(
      Uri.parse('$baseUrl/monetization/transactions/me'),
      headers: _headers,
    );
    final list = _parseData(res) as List<dynamic>;
    return list
        .map((e) => TransactionDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// API #78: Số dư lượt quẹt & lượt đẩy tin
  Future<ConsumableBalanceDTO> getMyConsumables() async {
    final res = await client.get(
      Uri.parse('$baseUrl/monetization/consumables/me'),
      headers: _headers,
    );
    return ConsumableBalanceDTO.fromJson(
      _parseData(res) as Map<String, dynamic>,
    );
  }

  /// Gói đang hoạt động của tôi
  Future<List<ActiveSubscriptionDTO>> getMySubscriptions() async {
    final res = await client.get(
      Uri.parse('$baseUrl/monetization/subscriptions/me'),
      headers: _headers,
    );
    final list = _parseData(res) as List<dynamic>;
    return list
        .map((e) => ActiveSubscriptionDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
