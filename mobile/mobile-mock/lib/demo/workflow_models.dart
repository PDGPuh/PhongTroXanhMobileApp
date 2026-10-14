import '../app/session.dart';
import '../core/reference_photo.dart';
import '../core/device_media.dart';

class KycRecord {
  final String id, userId, number, front, back;
  final DateTime createdAt = DateTime.now();
  String status = 'Chờ duyệt', note = '';
  KycRecord(this.id, this.userId, this.number, this.front, this.back);
}

class ReviewRecord {
  final String id,
      rentalId,
      authorId,
      authorName,
      targetType,
      targetId,
      comment;
  final int rating;
  final int cleanlinessRating, accuracyRating, communicationRating;
  final List<String> tags;
  final DateTime createdAt = DateTime.now();
  String? landlordReply;
  DateTime? repliedAt;
  String? disputeStatus;
  String? disputeReason;
  String? disputeResolutionNote;
  ReviewRecord(
    this.id,
    this.rentalId,
    this.authorId,
    this.authorName,
    this.targetType,
    this.targetId,
    this.rating,
    this.comment,
    this.tags, {
    this.cleanlinessRating = 5,
    this.accuracyRating = 5,
    this.communicationRating = 5,
    this.landlordReply,
    this.repliedAt,
    this.disputeStatus,
    this.disputeReason,
    this.disputeResolutionNote,
  });
}

class ReportRecord {
  final String id, reporterId, targetType, targetId, reason, details;
  final String severity;
  final List<String> evidence;
  final DateTime createdAt = DateTime.now();
  String status = 'Chờ xử lý';
  final List<String> history = [];
  ReportRecord(
    this.id,
    this.reporterId,
    this.targetType,
    this.targetId,
    this.reason,
    this.details, {
    this.severity = 'Trung bình',
    this.evidence = const ['Ảnh chụp màn hình vi phạm'],
  });
}

class SwapProposal {
  final String id, listingId, proposerId, offeredRentalId, note;
  String status = 'Chờ phản hồi';
  SwapProposal(
    this.id,
    this.listingId,
    this.proposerId,
    this.offeredRentalId,
    this.note,
  );
}

class ServicePlan {
  final String id, name, description;
  final int monthly, yearly, extraSwipes, boosts, superMatches;
  final bool landlord;
  final List<String> features;
  const ServicePlan(
    this.id,
    this.name,
    this.monthly,
    this.description, {
    this.yearly = 0,
    this.extraSwipes = 0,
    this.boosts = 0,
    this.superMatches = 0,
    this.landlord = false,
    this.features = const [],
  });
  static const catalog = [
    ServicePlan(
      'plus',
      'Green Plus',
      39000,
      'Vuốt phòng và ghép bạn không giới hạn trong thời hạn gói',
      features: [
        'Vuốt phòng & tìm bạn ở không giới hạn',
        'Bộ lọc nâng cao theo lối sống',
        'Ưu tiên hiển thị hồ sơ tìm bạn ở',
      ],
    ),
    ServicePlan(
      'gold',
      'Green Gold',
      79000,
      'Đặc quyền Plus; xem ai đã thích bạn; 1 Boost và 5 Super Match',
      boosts: 1,
      superMatches: 5,
      features: [
        'Toàn bộ đặc quyền của gói Green Plus',
        'Xem danh sách ai đã thích hồ sơ của bạn',
        'Tặng 1 lượt Boost & 5 lượt Super Match',
      ],
    ),
    ServicePlan(
      'swipes',
      '+150 lượt vuốt',
      29000,
      'Thêm 150 lượt khám phá',
      extraSwipes: 150,
      features: ['Cộng ngay 150 lượt vuốt phòng', 'Không giới hạn thời gian dùng'],
    ),
    ServicePlan(
      'boost',
      '1 lượt Boost hồ sơ',
      19000,
      'Đẩy hồ sơ trong bản demo',
      boosts: 1,
      features: ['Đẩy nổi bật hồ sơ / tin phòng trong 24 giờ'],
    ),
    ServicePlan(
      'super',
      '5 lượt Super Match',
      29000,
      '5 lượt ưu tiên ghép bạn',
      superMatches: 5,
      features: ['Gửi lời thích ưu tiên đến 5 bạn ở tiềm năng'],
    ),
    ServicePlan(
      'owner-pro',
      'Chủ trọ Pro',
      199000,
      'Gói chủ trọ theo web hiện tại',
      yearly: 1908000,
      boosts: 5,
      landlord: true,
      features: [
        'Đăng tối đa 15 tin phòng cùng lúc',
        'Tặng 5 lượt Đẩy tin nổi bật mỗi tháng',
        'Báo cáo phân tích lượt xem & tỉ lệ lấp đầy',
        'Huy hiệu Chủ trọ Uy tín Pro',
      ],
    ),
    ServicePlan(
      'owner-premium',
      'Chủ trọ Premium',
      499000,
      'Gói chủ trọ Premium',
      yearly: 4788000,
      boosts: 15,
      landlord: true,
      features: [
        'Đăng tin phòng không giới hạn',
        'Tặng 15 lượt Đẩy tin VIP đầu trang',
        'Ưu tiên duyệt tin nhanh & hỗ trợ 24/7',
        'Phân tích chuyên sâu thị trường theo khu vực',
      ],
    ),
  ];
}

class PaymentOrder {
  final String id, userId, method;
  final ServicePlan plan;
  final bool yearly;
  final DateTime createdAt = DateTime.now();
  String status = 'Chờ thanh toán';
  int get amount => yearly ? plan.yearly : plan.monthly;
  PaymentOrder(this.id, this.userId, this.plan, this.yearly, this.method);
}

class PublicProfile {
  LocalPhoto? avatarPhoto;
  final SessionUser user;
  PhotoKind avatar = PhotoKind.man;
  String school = '', gender = 'Nữ', birthday = '', district = 'Quận 10';
  int budgetMin = 1500000, budgetMax = 3000000;
  bool onboardingDone = false;
  String package = 'Miễn phí';
  DateTime? packageExpiry;
  int boosts = 0, superMatches = 0;
  DateTime? boostedAt;
  final Set<String> priorityPeople = {};
  int trustScore = 85;
  bool warned = false;
  String warningNote = '';
  String address = '';
  String roomCountRange = '1-5';
  String primaryRoomType = 'Studio';
  Set<String> operatingDistricts = {'Quận 10'};
  final DateTime joinedAt = DateTime(2026, 5, 15);
  PublicProfile(this.user);
}

class SupportTicket {
  final String id, userId, subject, content;
  String status = 'Đã tiếp nhận';
  SupportTicket(this.id, this.userId, this.subject, this.content);
}

class SystemFeedbackRecord {
  final String id, authorName, roleLabel, comment;
  final int rating;
  final DateTime createdAt;
  SystemFeedbackRecord({
    required this.id,
    required this.authorName,
    required this.roleLabel,
    required this.rating,
    required this.comment,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class AuditLogRecord {
  final String id, actorName, action, target, ipAddress;
  final DateTime timestamp;
  AuditLogRecord({
    required this.id,
    required this.actorName,
    required this.action,
    required this.target,
    this.ipAddress = '103.199.18.42',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
