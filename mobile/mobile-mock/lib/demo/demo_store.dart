import '../app/session.dart';
import 'models.dart';
import 'workflow_models.dart';
import '../core/device_media.dart';

/// Represents a demo server. Public records survive logout; private UI state is
/// selected by authenticated user ID and never copied into another account.
class DemoStore {
  final Map<String, PublicProfile> profiles = {
    for (final u in DemoAuthRepository.accounts) u.id: PublicProfile(u),
  };
  final Set<String> blocked = {}, deleted = {};
  final List<KycRecord> kyc = [];
  final List<ReviewRecord> reviewRecords = [];
  final List<ReportRecord> reports = [];
  final List<SwapProposal> proposals = [];
  final List<PaymentOrder> orders = [];
  final List<SupportTicket> tickets = [];
  // An explicit incoming demo like; other likes remain one-way.
  final Map<String, Set<String>> incomingLikes = {
    'tenant-a': {'p1'},
  };
  final Map<String, Set<String>> matches = {};
  final List<Room> rooms = [...DemoRepository.rooms];
  late final List<Rental> rentals = [
    Rental(
      rooms.firstWhere((r) => r.id == 'r1'),
      'PTX-2026',
      id: 'lease-a1',
      checkedIn: false,
    ),
    Rental(
      rooms.firstWhere((r) => r.id == 'r3'),
      'PTX-2027',
      id: 'lease-a2',
      checkedIn: false,
    ),
    Rental(
      rooms.firstWhere((r) => r.id == 'r4'),
      'PTX-4026',
      id: 'lease-b1',
      tenantId: 'tenant-b',
      checkedIn: false,
    ),
  ];
  final List<SwapRequest> swaps = [];
  final Map<String, UserWorkspace> _users = {};
  UserWorkspace workspace(SessionUser user) =>
      _users.putIfAbsent(user.id, () => UserWorkspace(user));
  UserWorkspace workspaceById(String id) => workspace(profiles[id]!.user);
}

class UserWorkspace {
  final Map<String, LocalPhoto> media = {};
  final Set<String> saved = {}, liked = {};
  final Set<String> viewed = {};
  final List<Conversation> conversations;
  final Map<String, ({int rating, String comment})> reviews = {};
  final Map<String, bool> settings = {
    'notifications': true,
    'matching': true,
    'privacy': false,
  };
  final Map<String, String> drafts = {};
  final Set<String> mutedConversations = {};
  final List<AppNotification> notifications = [];
  String fullName,
      email,
      bio = 'Một không gian sống tốt là khởi đầu cho những điều tuyệt vời.';
  String verification = 'Chưa xác minh';
  int roomQuota = 7, roommateQuota = 6;
  int roomAllowance = 15, roommateAllowance = 10;
  Set<String> interests = {'Nấu ăn', 'Đọc sách', 'Du lịch'};
  bool smoking = false, earlySleep = true, tidy = true;
  UserWorkspace(SessionUser user)
    : fullName = user.name,
      email = user.email,
      conversations = user.id == 'tenant-a'
          ? DemoRepository.conversations()
          : [] {
    if (user.id == 'tenant-a') {
      notifications.addAll([
        AppNotification(
          id: 'message-c1',
          title: 'Tin nhắn từ Cô Hồng',
          description: 'Xem hội thoại về Studio xanh gần Bách Khoa',
          target: const ResourceRef(ResourceKind.conversation, 'c1'),
        ),
        AppNotification(
          id: 'room-r1',
          title: 'Studio xanh gần Bách Khoa',
          description: 'Xem thông tin và liên hệ chủ trọ',
          target: const ResourceRef(ResourceKind.room, 'r1'),
        ),
      ]);
    }
    if (user.role != UserRole.admin) {
      notifications.add(
        AppNotification(
          id: 'verify-${user.id}',
          title: 'Hoàn thiện xác minh tài khoản',
          description: 'Thêm một bước để tăng sự tin cậy',
          verification: true,
        ),
      );
    }
  }
  UserWorkspace.guest() : fullName = 'Khách', email = '', conversations = [];
}
