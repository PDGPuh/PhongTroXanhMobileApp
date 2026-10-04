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
  final List<String> tags;
  final DateTime createdAt = DateTime.now();
  ReviewRecord(
    this.id,
    this.rentalId,
    this.authorId,
    this.authorName,
    this.targetType,
    this.targetId,
    this.rating,
    this.comment,
    this.tags,
  );
}

class ReportRecord {
  final String id, reporterId, targetType, targetId, reason, details;
  String status = 'Chờ xử lý';
  final List<String> history = [];
  ReportRecord(
    this.id,
    this.reporterId,
    this.targetType,
    this.targetId,
    this.reason,
    this.details,
  );
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
  });
  static const catalog = [
    ServicePlan(
      'plus',
      'Green Plus',
      39000,
      'Vuốt phòng và ghép bạn không giới hạn trong thời hạn gói',
    ),
    ServicePlan(
      'gold',
      'Green Gold',
      79000,
      'Đặc quyền Plus; xem ai đã thích bạn; 1 Boost và 5 Super Match',
      boosts: 1,
      superMatches: 5,
    ),
    ServicePlan(
      'swipes',
      '+150 lượt vuốt',
      29000,
      'Thêm 150 lượt khám phá',
      extraSwipes: 150,
    ),
    ServicePlan(
      'boost',
      '1 lượt Boost hồ sơ',
      19000,
      'Đẩy hồ sơ trong bản demo',
      boosts: 1,
    ),
    ServicePlan(
      'super',
      '5 lượt Super Match',
      29000,
      '5 lượt ưu tiên ghép bạn',
      superMatches: 5,
    ),
    ServicePlan(
      'owner-pro',
      'Chủ trọ Pro',
      199000,
      'Gói chủ trọ theo web hiện tại',
      yearly: 1908000,
      landlord: true,
    ),
    ServicePlan(
      'owner-premium',
      'Chủ trọ Premium',
      499000,
      'Gói chủ trọ Premium',
      yearly: 4788000,
      landlord: true,
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
  PublicProfile(this.user);
}

class SupportTicket {
  final String id, userId, subject, content;
  String status = 'Đã tiếp nhận';
  SupportTicket(this.id, this.userId, this.subject, this.content);
}
