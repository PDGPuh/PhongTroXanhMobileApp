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
    // --- Gói dành cho Người thuê (TENANT) ---
    ServicePlan(
      'FREE',
      'Gói Miễn Phí',
      0,
      'Gói miễn phí cơ bản dành cho người tìm trọ và tìm bạn ở ghép',
      yearly: 0,
      extraSwipes: 15,
      boosts: 0,
      landlord: false,
      features: [
        '15 lượt quẹt tìm phòng & bạn ở mỗi ngày',
        'Tìm kiếm và lọc phòng trọ cơ bản',
        'Nhắn tin trao đổi khi có ghép đôi thành công',
      ],
    ),
    ServicePlan(
      'PRO_TENANT',
      'Gói Pro Tìm Bạn & Thuê Phòng',
      29000,
      'Tăng lượt quẹt và ưu tiên hiển thị hồ sơ ghép bạn',
      yearly: 290000,
      extraSwipes: 50,
      boosts: 2,
      landlord: false,
      features: [
        '50 lượt quẹt khám phá mỗi ngày',
        'Tặng 2 lượt đẩy hồ sơ (ưu tiên hiển thị 24 giờ/lượt)',
        'Bộ lọc nâng cao theo lối sống, ngân sách & trường học',
        'Ưu tiên ghép đôi siêu tốc',
      ],
    ),
    ServicePlan(
      'VIP_TENANT',
      'Gói VIP Ghép Đôi Siêu Tốc',
      59000,
      'Đặc quyền tối đa cho người thuê: 100 lượt quẹt/ngày và 6 lượt đẩy hồ sơ',
      yearly: 590000,
      extraSwipes: 100,
      boosts: 6,
      landlord: false,
      features: [
        '100 lượt quẹt khám phá mỗi ngày',
        'Tặng 6 lượt đẩy hồ sơ (ưu tiên hiển thị 24 giờ/lượt)',
        'Xem ai đã thích hồ sơ của bạn',
        'Huy hiệu thành viên VIP nổi bật',
        'Hỗ trợ ưu tiên 24/7',
      ],
    ),

    // --- Gói dành cho Chủ trọ (LANDLORD) ---
    ServicePlan(
      'LANDLORD_BASIC',
      'Gói Đẩy Tin Trải Nghiệm',
      39000,
      'Dành cho chủ trọ mới tiếp cận khách thuê nhanh chóng',
      yearly: 390000,
      boosts: 3,
      landlord: true,
      features: [
        '3 lượt đẩy tin phòng lên đầu trang tìm kiếm (24 giờ/lượt)',
        'Tiếp cận khách thuê tiềm năng nhanh gấp 2 lần',
        'Hỗ trợ duyệt tin và hiển thị ngay lập tức',
      ],
    ),
    ServicePlan(
      'LANDLORD_VIP',
      'Gói Chủ Trọ VIP',
      79000,
      'Tối ưu tỷ lệ lấp đầy phòng trọ với 8 lượt đẩy tin VIP',
      yearly: 790000,
      boosts: 8,
      landlord: true,
      features: [
        '8 lượt đẩy tin phòng VIP đầu trang (24 giờ/lượt)',
        'Huy hiệu Chủ trọ Uy tín VIP',
        'Ưu tiên hiển thị trên bản đồ và danh sách gợi ý',
        'Thống kê lượt xem và tương tác của khách thuê',
      ],
    ),
    ServicePlan(
      'LANDLORD_PRO',
      'Gói Chủ Trọ Chuyên Nghiệp',
      149000,
      'Giải pháp toàn diện cho chủ chuỗi nhà trọ & căn hộ dịch vụ',
      yearly: 1490000,
      boosts: 20,
      landlord: true,
      features: [
        '20 lượt đẩy tin nổi bật VIP đầu trang',
        'Đăng tin phòng trọ không giới hạn',
        'Huy hiệu Đối tác Xác thực Chuyên nghiệp',
        'Báo cáo phân tích nhu cầu thị trường khu vực',
        'Quản lý hợp đồng & nhân khẩu trực tiếp',
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
  String? avatarUrl;
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
  int trustScore = 50;
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
