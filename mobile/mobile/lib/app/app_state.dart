import '../mock/fixtures.dart';
import '../mock/auth_repository.dart';
import '../mock/room_repository.dart';
import '../mock/transport.dart';

import 'package:flutter/foundation.dart';

import '../core/async_resource.dart';
import '../core/device_media.dart';
import '../domain/models.dart';
import '../mock/demo_store.dart';
import '../mock/workflows.dart';
import '../domain/workflow_models.dart';
import '../features/rooms/room_controller.dart';
import 'session.dart';

/// Compatibility facade for existing screens; session and room loading are
/// owned by feature controllers. The demo store acts as a separate server.
class AppState extends ChangeNotifier {
  final DemoStore store;
  final DemoTransport transport;
  final MediaPicker mediaPicker;
  late final SessionController session;
  late final RoomController roomController;
  late final DemoWorkflows workflows;
  void changed() {
    if (!_disposed) notifyListeners();
  }

  int roomViews(String id) => store.profiles.values
      .where(
        (p) =>
            !store.deleted.contains(p.user.id) &&
            store.workspace(p.user).viewed.contains(id),
      )
      .length;
  int roomSaves(String id) => store.profiles.values
      .where(
        (p) =>
            !store.deleted.contains(p.user.id) &&
            store.workspace(p.user).saved.contains(id),
      )
      .length;

  String roomRating(String roomId) {
    final records = store.reviewRecords
        .where((r) => r.targetType == 'ROOM' && r.targetId == roomId)
        .toList();
    return records.isEmpty
        ? '—'
        : (records.fold<int>(0, (sum, r) => sum + r.rating) / records.length)
              .toStringAsFixed(1);
  }

  UserWorkspace _guest = UserWorkspace.guest();
  String? _activeUserId;
  int roomIndex = 0, personIndex = 0;
  String personDistrict = 'Quận 10', gender = 'Nữ', habit = 'Tất cả';
  double personBudget = 2500000;
  final List<({bool person, int index, String? savedId, bool consumed})>
  _history = [];
  int _messageSequence = 0;
  bool _disposed = false;

  AppState({
    DemoStore? store,
    DemoTransport? transport,
    AuthRepository? auth,
    UserRole? role,
    MediaPicker? mediaPicker,
  }) : store = store ?? DemoStore(),
       mediaPicker = mediaPicker ?? DeviceMediaPicker(),
       transport = transport ?? DemoTransport() {
    session = SessionController(
      auth ??
          DemoAuthRepository(
            transport: this.transport,
            isUnavailable: (id) =>
                this.store.blocked.contains(id) ||
                this.store.deleted.contains(id),
          ),
    );
    workflows = DemoWorkflows(this);
    roomController = RoomController(
      this.store,
      DemoRoomRepository(this.store, this.transport),
    );
    session.addListener(_sessionChanged);
    roomController.addListener(notifyListeners);
    if (role != null) session.startDemo(role);
  }
  UserWorkspace get _workspace =>
      session.user == null ? _guest : store.workspace(session.user!);
  bool get authenticated => session.authenticated;
  Future<List<LocalPhoto>> pickMedia({
    bool multiple = false,
    bool camera = false,
  }) async {
    _requireSession();
    final ownerId = userId!;
    final revision = workflows.epoch;
    final selected = await mediaPicker.pick(multiple: multiple, camera: camera);
    if (_disposed ||
        workflows.epoch != revision ||
        userId != ownerId ||
        store.blocked.contains(ownerId) ||
        store.deleted.contains(ownerId)) {
      throw const MediaFailure('Phiên đã thay đổi. Vui lòng chọn ảnh lại.');
    }
    final media = store.workspace(session.user!).media;
    for (final photo in selected) {
      media[photo.id] = photo;
    }
    return selected;
  }

  LocalPhoto? ownPhoto(String? id) => id == null ? null : _workspace.media[id];
  String? get userId => session.user?.id;
  UserRole get role => session.user?.role ?? UserRole.tenant;
  bool get unlimitedSwipes {
    final profile = store.profiles[userId];
    return authenticated &&
        role == UserRole.tenant &&
        ['Green Plus', 'Green Gold'].contains(profile?.package) &&
        (profile?.packageExpiry?.isAfter(DateTime.now()) ?? false);
  }

  List<Room> get rooms => List.unmodifiable(store.rooms);
  List<Room> get myRooms => rooms.where((r) => r.landlordId == userId).toList();
  final List<Person> people = [...DemoRepository.people];
  List<Conversation> get conversations => _workspace.conversations;
  Set<String> get saved => _workspace.saved;
  Set<String> get liked => _workspace.liked;
  List<Rental> get rentals => store.rentals
      .where(
        (r) => role == UserRole.landlord
            ? r.landlordId == userId
            : r.tenantId == userId,
      )
      .toList();
  List<Rental> get reviewableRentals => rentals
      .where((r) => r.checkedIn && r.status == RentalStatus.active)
      .toList();
  List<SwapRequest> get swaps => store.swaps
      .where(
        (s) => role == UserRole.landlord
            ? roomById(s.roomId)?.landlordId == userId
            : s.tenantId == userId,
      )
      .toList();
  Map<String, ({int rating, String comment})> get reviews => _workspace.reviews;
  Map<String, String> get roomStatus => {
    for (final r in rooms) r.id: r.status.label,
  };
  String get fullName => _workspace.fullName;
  set fullName(String value) {
    _requireSession();
    _workspace.fullName = value;
  }

  String get email => _workspace.email;
  set email(String value) {
    _requireSession();
    _workspace.email = value;
  }

  String get bio => _workspace.bio;
  set bio(String value) {
    _requireSession();
    _workspace.bio = value;
  }

  String get verification => _workspace.verification;
  set verification(String value) {
    _requireSession();
    _workspace.verification = value;
  }

  int get roomQuota => _workspace.roomQuota;
  set roomQuota(int value) => _workspace.roomQuota = value;
  int get roommateQuota => _workspace.roommateQuota;
  set roommateQuota(int value) => _workspace.roommateQuota = value;
  List<AppNotification> get notifications =>
      List.unmodifiable(_workspace.notifications);
  int get unreadNotifications => notifications.where((n) => !n.read).length;
  void readNotification(String id) {
    _requireSession();
    final item = notifications.where((n) => n.id == id).firstOrNull;
    if (item == null) return;
    item.read = true;
    notifyListeners();
  }

  Set<String> get interests => _workspace.interests;
  bool get smoking => _workspace.smoking;
  bool get earlySleep => _workspace.earlySleep;
  bool get tidy => _workspace.tidy;
  Map<String, bool> get settings => _workspace.settings;
  Map<String, String> get drafts => _workspace.drafts;
  String get district => roomController.district;
  set district(String value) => roomController.district = value;
  String get type => roomController.type;
  set type(String value) => roomController.type = value;
  double get maxPrice => roomController.maxPrice;
  set maxPrice(double value) => roomController.maxPrice = value;
  List<Room> get filteredRooms => roomController.filtered;
  List<Person> get filteredPeople => people
      .where(
        (p) =>
            (personDistrict == 'Tất cả' || p.district == personDistrict) &&
            (gender == 'Tất cả' || p.gender == gender) &&
            (habit == 'Tất cả' || p.habits.contains(habit)) &&
            p.budget <= personBudget,
      )
      .toList();

  Room? roomById(String id) => store.rooms.where((r) => r.id == id).firstOrNull;
  Person? personById(String id) => people.where((p) => p.id == id).firstOrNull;
  Conversation? conversationById(String id) =>
      conversations.where((c) => c.id == id).firstOrNull;
  Rental? rentalById(String id) => rentals.where((r) => r.id == id).firstOrNull;
  bool resourceExists(ResourceRef ref) => switch (ref.kind) {
    ResourceKind.room => roomById(ref.id) != null,
    ResourceKind.person => personById(ref.id) != null,
    ResourceKind.conversation => conversationById(ref.id) != null,
    ResourceKind.rental => rentalById(ref.id) != null,
    ResourceKind.swap => swaps.any((s) => s.id == ref.id),
    ResourceKind.kyc => store.kyc.any(
      (r) => r.id == ref.id && (role == UserRole.admin || r.userId == userId),
    ),
    ResourceKind.report => store.reports.any(
      (r) =>
          r.id == ref.id && (role == UserRole.admin || r.reporterId == userId),
    ),
    ResourceKind.order => store.orders.any(
      (r) => r.id == ref.id && r.userId == userId,
    ),
  };
  Future<void> loadRooms() => roomController.load();
  Future<bool> authenticate(String login, String password) =>
      session.signIn(login, password);
  void logout() {
    _workspace.drafts.clear();
    session.logout();
  }

  void _requireSession([UserRole? requiredRole]) {
    if (_disposed ||
        !authenticated ||
        (requiredRole != null && role != requiredRole)) {
      throw const RepositoryFailure(
        RepositoryFault.denied,
        'Bạn không có quyền thực hiện thao tác này.',
      );
    }
  }

  void _sessionChanged() {
    if (_activeUserId != userId) {
      workflows.sessionChanged();
      if (session.user != null) {
        store.profiles.putIfAbsent(userId!, () => PublicProfile(session.user!));
      }
      _activeUserId = userId;
      _guest = UserWorkspace.guest();
      _history.clear();
      roomIndex = 0;
      personIndex = 0;
      roomController.resetFilters();
      personDistrict = 'Quận 10';
      gender = 'Nữ';
      habit = 'Tất cả';
      personBudget = 2500000;
    }
    notifyListeners();
  }

  void personFilters(String area, String sex, String lifestyle, double budget) {
    personDistrict = area;
    gender = sex;
    habit = lifestyle;
    personBudget = budget;
    personIndex = 0;
    _history.removeWhere((h) => h.person);
    notifyListeners();
  }

  void preferences(Set<String> selected, bool smoke, bool early, bool clean) {
    _requireSession();
    _workspace.interests = {...selected};
    _workspace.smoking = smoke;
    _workspace.earlySleep = early;
    _workspace.tidy = clean;
    notifyListeners();
  }

  bool isSaved(String id) => saved.contains(id);
  void toggleSave(String id) {
    _requireSession();
    if (roomById(id) == null) {
      throw const RepositoryFailure(
        RepositoryFault.missing,
        'Không tìm thấy phòng.',
      );
    }
    if (!saved.add(id)) saved.remove(id);
    notifyListeners();
  }

  bool swipe({required bool person, required bool like}) {
    _requireSession();
    final quota = person ? roommateQuota : roomQuota;
    final length = person ? filteredPeople.length : filteredRooms.length;
    final index = person ? personIndex : roomIndex;
    if ((!unlimitedSwipes && quota <= 0) || index >= length) return false;
    String? savedId;
    if (like) {
      final id = person ? filteredPeople[index].id : filteredRooms[index].id;
      if ((person ? liked : saved).add(id)) savedId = id;
    }
    _history.add((
      person: person,
      index: index,
      savedId: savedId,
      consumed: !unlimitedSwipes,
    ));
    if (person) {
      personIndex++;
      if (!unlimitedSwipes) roommateQuota--;
    } else {
      roomIndex++;
      if (!unlimitedSwipes) roomQuota--;
    }
    notifyListeners();
    return true;
  }

  void undo(bool person) {
    _requireSession();
    final index = _history.lastIndexWhere((h) => h.person == person);
    if (index < 0) return;
    final action = _history.removeAt(index);
    if (person) {
      personIndex = action.index;
      if (action.consumed) roommateQuota++;
      if (action.savedId != null) liked.remove(action.savedId);
    } else {
      roomIndex = action.index;
      if (action.consumed) roomQuota++;
      if (action.savedId != null) saved.remove(action.savedId);
    }
    notifyListeners();
  }

  void filters(String area, String roomType, double price) {
    district = area;
    type = roomType;
    maxPrice = price;
    roomIndex = 0;
    _history.removeWhere((h) => !h.person);
    notifyListeners();
  }

  void applyRoomFilters({
    required String district,
    required String type,
    required double minPrice,
    required double maxPrice,
    required String query,
    required Set<String> amenities,
    required String sort,
  }) {
    if (minPrice < 0 || maxPrice < minPrice) return;
    roomController.district = district;
    roomController.type = type;
    roomController.minPrice = minPrice;
    roomController.maxPrice = maxPrice;
    roomController.query = query;
    roomController.sort = sort;
    roomController.amenities
      ..clear()
      ..addAll(amenities);
    resetDeck(false);
  }

  void resetDeck(bool person) {
    if (person) {
      personIndex = 0;
    } else {
      roomIndex = 0;
    }
    _history.removeWhere((h) => h.person == person);
    notifyListeners();
  }

  void send(Conversation c, String text) {
    _requireSession();
    if (!conversations.contains(c)) {
      throw const RepositoryFailure(
        RepositoryFault.denied,
        'Hội thoại không thuộc tài khoản này.',
      );
    }
    if (text.trim().isEmpty) return;
    final now = DateTime.now();
    c.messages.add(
      ChatMessage(
        text.trim(),
        mine: true,
        time:
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      ),
    );
    notifyListeners();
  }

  bool conversationMuted(String id) =>
      _workspace.mutedConversations.contains(id);
  void toggleConversationMute(String id) {
    _requireSession();
    if (conversationById(id) == null) return;
    if (!_workspace.mutedConversations.add(id)) {
      _workspace.mutedConversations.remove(id);
    }
    notifyListeners();
  }

  Future<void> sendAsync(
    Conversation c,
    String text, {
    String? roomId,
    String? retryId,
  }) async {
    _requireSession();
    if (!conversations.contains(c)) {
      throw const RepositoryFailure(
        RepositoryFault.denied,
        'Hội thoại không thuộc tài khoản này.',
      );
    }
    final workspace = _workspace;
    final user = userId;
    final revision = session.revision;
    ChatMessage outgoing;
    if (retryId != null) {
      final existing = c.messages.where((m) => m.id == retryId).firstOrNull;
      if (existing == null || existing.delivery != MessageDelivery.failed) {
        return;
      }
      outgoing = existing.withDelivery(MessageDelivery.sending);
      c.messages[c.messages.indexOf(existing)] = outgoing;
    } else {
      if (text.trim().isEmpty) return;
      if (roomId != null && roomById(roomId) == null) {
        throw const RepositoryFailure(
          RepositoryFault.missing,
          'Phòng không còn tồn tại.',
        );
      }
      final now = DateTime.now();
      outgoing = ChatMessage(
        text.trim(),
        mine: true,
        room: roomId != null,
        roomId: roomId,
        id: '$user-message-${++_messageSequence}',
        delivery: MessageDelivery.sending,
        time:
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      );
      c.messages.add(outgoing);
    }
    notifyListeners();
    MessageDelivery delivery;
    try {
      await transport.run(() {
        if (_disposed || userId != user || session.revision != revision) {
          throw const RepositoryFailure(
            RepositoryFault.denied,
            'Phiên đã kết thúc.',
          );
        }
      });
      delivery = MessageDelivery.sent;
    } catch (_) {
      delivery = MessageDelivery.failed;
    }
    final index = c.messages.indexWhere((m) => m.id == outgoing.id);
    if (index >= 0) c.messages[index] = outgoing.withDelivery(delivery);
    if (delivery == MessageDelivery.sent && workspace.conversations.remove(c)) {
      workspace.conversations.insert(0, c);
    }
    if (!_disposed && userId == user && session.revision == revision) {
      notifyListeners();
    }
  }

  void shareRoom(Conversation c, Room room) {
    _requireSession();
    if (!conversations.contains(c) || roomById(room.id) == null) {
      throw const RepositoryFailure(
        RepositoryFault.denied,
        'Không thể chia sẻ phòng vào hội thoại này.',
      );
    }
    c.messages.add(
      ChatMessage(
        'Mình chia sẻ phòng này nhé.',
        mine: true,
        room: true,
        roomId: room.id,
      ),
    );
    notifyListeners();
  }

  void read(Conversation c) {
    _requireSession();
    if (!conversations.contains(c)) return;
    c.unread = 0;
    notifyListeners();
  }

  Conversation contactRoom(Room room) {
    _requireSession();
    final current = roomById(room.id);
    if (current == null) {
      throw const RepositoryFailure(
        RepositoryFault.missing,
        'Phòng không còn tồn tại.',
      );
    }
    final existing = conversations
        .where(
          (c) =>
              c.roomId == current.id && c.participantId == current.landlordId,
        )
        .firstOrNull;
    if (existing != null) return existing;
    final created = Conversation(
      id: '$userId-room-${current.id}',
      name: current.landlordName,
      participantId: current.landlordId,
      participantName: current.landlordName,
      roomId: current.id,
      subtitle: current.title,
      host: true,
      messages: [
        ChatMessage(
          'Bạn đang quan tâm đến ${current.title}.',
          room: true,
          roomId: current.id,
        ),
      ],
    );
    conversations.insert(0, created);
    notifyListeners();
    return created;
  }

  Conversation contactPerson(Person person) {
    _requireSession();
    if (personById(person.id) == null) {
      throw const RepositoryFailure(
        RepositoryFault.missing,
        'Không tìm thấy hồ sơ.',
      );
    }
    final existing = conversations
        .where((c) => c.participantId == person.id && c.roomId == null)
        .firstOrNull;
    if (existing != null) return existing;
    final created = Conversation(
      id: '$userId-person-${person.id}',
      participantId: person.id,
      participantName: person.name,
      name: person.name,
      subtitle: 'Bắt đầu trò chuyện',
      photo: person.photo,
    );
    conversations.insert(0, created);
    notifyListeners();
    return created;
  }

  String? checkIn(String code, {String? rentalId}) {
    _requireSession(UserRole.tenant);
    final rental = rentals
        .where(
          (r) =>
              r.code.toUpperCase() == code.trim().toUpperCase() &&
              (rentalId == null || r.id == rentalId),
        )
        .firstOrNull;
    if (rental == null) {
      return 'Mã không hợp lệ hoặc không thuộc hợp đồng của bạn.';
    }
    if (rental.status != RentalStatus.active &&
        rental.status != RentalStatus.pending) {
      return 'Hợp đồng không còn hiệu lực.';
    }
    if (rental.checkedIn) return 'Mã này đã được sử dụng.';
    if (rental.codeExpiresAt?.isBefore(DateTime.now()) == true) {
      return 'Mã đã hết hạn. Hãy liên hệ chủ trọ.';
    }
    rental.checkedIn = true;
    notifyListeners();
    return null;
  }

  void review(String id, int rating, String comment) {
    _requireSession();
    final rental = reviewableRentals
        .where((r) => r.id == id || r.room.id == id)
        .firstOrNull;
    if (rental == null || rating < 1 || rating > 5 || comment.trim().isEmpty) {
      throw const RepositoryFailure(
        RepositoryFault.denied,
        'Hợp đồng chưa đủ điều kiện đánh giá.',
      );
    }
    if (reviews.containsKey(rental.id)) {
      throw const RepositoryFailure(
        RepositoryFault.denied,
        'Bạn đã đánh giá hợp đồng này.',
      );
    }
    reviews[rental.id] = (rating: rating, comment: comment.trim());
    store.reviewRecords.add(
      ReviewRecord(
        'review-${store.reviewRecords.length + 1}',
        rental.id,
        userId!,
        fullName,
        role == UserRole.landlord ? 'USER' : 'ROOM',
        role == UserRole.landlord ? rental.tenantId : rental.room.id,
        rating,
        comment.trim(),
        [],
      ),
    );
    notifyListeners();
  }

  void updateProfile(String name, String mail, String description) {
    _requireSession();
    fullName = name;
    email = mail;
    bio = description;
    notifyListeners();
  }

  void setSetting(String key, bool value) {
    _requireSession();
    settings[key] = value;
    notifyListeners();
  }

  void verify() {
    _requireSession();
    verification = 'Chờ duyệt';
    notifyListeners();
  }

  void addSwap(SwapRequest request) {
    _requireSession(UserRole.tenant);
    if (!reviewableRentals.any((r) => r.room.id == request.roomId)) {
      throw const RepositoryFailure(
        RepositoryFault.denied,
        'Chọn phòng đang thuê đã nhận phòng.',
      );
    }
    final owned = SwapRequest(
      id: 'swap-${store.swaps.length + 1}',
      roomId: request.roomId,
      tenantId: userId!,
      reason: request.reason,
      leaseholder: request.leaseholder,
      targetDistrict: request.targetDistrict,
      targetType: request.targetType,
      budgetMax: request.budgetMax,
      movingDate: request.movingDate,
      habits: request.habits,
      status: request.leaseholder ? 'Chờ duyệt' : 'Đang tìm phòng phù hợp',
    );
    request.status = owned.status;
    store.swaps.add(owned);
    notifyListeners();
  }

  void resolveSwap(SwapRequest request, bool approved) {
    _requireSession(UserRole.landlord);
    if (!swaps.contains(request)) {
      throw const RepositoryFailure(
        RepositoryFault.denied,
        'Yêu cầu không thuộc chủ trọ này.',
      );
    }
    request.status = approved ? 'Đã duyệt' : 'Đã từ chối';
    notifyListeners();
  }

  void addRoom(Room room) {
    _requireSession(UserRole.landlord);
    store.rooms.add(
      room.copyWith(
        status: RoomStatus.pending,
        landlordId: userId!,
        landlordName: fullName,
      ),
    );
    notifyListeners();
  }

  void replaceRoom(Room room) {
    _requireSession(UserRole.landlord);
    final existing = roomById(room.id);
    if (existing == null || existing.landlordId != userId) {
      throw const RepositoryFailure(
        RepositoryFault.denied,
        'Không thể sửa phòng của chủ khác.',
      );
    }
    final index = store.rooms.indexWhere((r) => r.id == room.id);
    store.rooms[index] = room.copyWith(
      status: RoomStatus.pending,
      landlordId: userId!,
      landlordName: fullName,
    );
    roomController.feed.clear();
    notifyListeners();
  }

  void setRoomStatus(Room room, String status) {
    _requireSession(UserRole.landlord);
    final current = roomById(room.id);
    if (current == null || current.landlordId != userId) {
      throw const RepositoryFailure(
        RepositoryFault.denied,
        'Phòng không thuộc tài khoản của bạn.',
      );
    }
    if (current.status == RoomStatus.pending &&
        status != RoomStatus.pending.label) {
      throw const RepositoryFailure(
        RepositoryFault.denied,
        'Tin đang chờ duyệt. Bạn có thể sửa tin và gửi lại.',
      );
    }
    final next = RoomStatus.values.where((s) => s.label == status).firstOrNull;
    if (next == null) return;
    store.rooms[store.rooms.indexWhere((r) => r.id == room.id)] = current
        .copyWith(status: next);
    roomController.feed.clear();
    notifyListeners();
  }

  void markNotificationsRead() {
    _requireSession();
    for (final item in notifications) {
      item.read = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    workflows.disposed = true;
    _disposed = true;
    session.removeListener(_sessionChanged);
    roomController.removeListener(notifyListeners);
    session.dispose();
    roomController.dispose();
    super.dispose();
  }
}
