import '../mock/fixtures.dart';
import '../mock/transport.dart';
import '../api/http_auth_repository.dart';
import '../api/http_room_repository.dart';
import '../api/http_admin_repository.dart';
import '../api/http_matching_repository.dart';
import '../api/http_rental_repository.dart';
import '../api/http_chat_repository.dart';
import '../api/http_user_repository.dart';
import '../api/http_notification_repository.dart';
import '../api/http_review_repository.dart';
import '../api/http_swap_repository.dart';
import '../api/http_payment_repository.dart';
import '../api/http_location_repository.dart';

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
  late final HttpAdminRepository adminRepository;
  late final HttpMatchingRepository matchingRepository;
  late final HttpRentalRepository rentalRepository;
  late final HttpChatRepository chatRepository;
  late final HttpUserRepository userRepository;
  late final HttpNotificationRepository notificationRepository;
  late final HttpReviewRepository reviewRepository;
  late final HttpSwapRepository swapRepository;
  late final HttpPaymentRepository paymentRepository;
  late final HttpLocationRepository locationRepository;
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
    final authRepo = auth ?? HttpAuthRepository();
    session = SessionController(authRepo);
    workflows = DemoWorkflows(this);
    adminRepository = HttpAdminRepository(
      tokenProvider: () => authRepo is HttpAuthRepository
          ? authRepo.accessToken
          : null,
    );
    matchingRepository = HttpMatchingRepository(
      tokenProvider: () => authRepo is HttpAuthRepository
          ? authRepo.accessToken
          : null,
    );
    rentalRepository = HttpRentalRepository(
      tokenProvider: () => authRepo is HttpAuthRepository
          ? authRepo.accessToken
          : null,
    );
    chatRepository = HttpChatRepository(
      tokenProvider: () => authRepo is HttpAuthRepository
          ? authRepo.accessToken
          : null,
    );
    userRepository = HttpUserRepository(
      tokenProvider: () => authRepo is HttpAuthRepository
          ? authRepo.accessToken
          : null,
    );
    notificationRepository = HttpNotificationRepository(
      tokenProvider: () => authRepo is HttpAuthRepository
          ? authRepo.accessToken
          : null,
    );
    reviewRepository = HttpReviewRepository(
      tokenProvider: () => authRepo is HttpAuthRepository
          ? authRepo.accessToken
          : null,
    );
    swapRepository = HttpSwapRepository(
      tokenProvider: () => authRepo is HttpAuthRepository
          ? authRepo.accessToken
          : null,
    );
    paymentRepository = HttpPaymentRepository(
      tokenProvider: () => authRepo is HttpAuthRepository
          ? authRepo.accessToken
          : null,
    );
    locationRepository = HttpLocationRepository(
      tokenProvider: () => authRepo is HttpAuthRepository
          ? authRepo.accessToken
          : null,
    );
    roomController = RoomController(
      this.store,
      HttpRoomRepository(
        tokenProvider: () => authRepo is HttpAuthRepository
            ? authRepo.accessToken
            : null,
      ),
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

  String? get avatarUrl =>
      _workspace.avatarUrl ??
      session.user?.avatarUrl ??
      (userId != null ? store.profiles[userId]?.avatarUrl : null);
  set avatarUrl(String? value) {
    _requireSession();
    _workspace.avatarUrl = value;
    if (session.user != null) {
      session.user = session.user!.copyWith(avatarUrl: value);
    }
    if (userId != null) {
      final p = store.profiles[userId];
      if (p != null) p.avatarUrl = value;
    }
    notifyListeners();
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
    if (authenticated && !id.startsWith('$userId-')) {
      notificationRepository.markAsRead(id).catchError((_) {});
    }
  }

  /// Load personal notifications from backend
  Future<void> loadNotifications() async {
    if (!authenticated) return;
    try {
      final dtos = await notificationRepository.getNotifications();
      final local = _workspace.notifications;
      for (final dto in dtos) {
        final existingIndex = local.indexWhere((n) => n.id == dto.id);
        if (existingIndex >= 0) {
          local[existingIndex].read = dto.isRead;
        } else {
          local.insert(0, dto.toAppNotification());
        }
      }
      notifyListeners();
    } catch (_) {}
    registerDeviceToken().catchError((_) {});
  }

  /// Dang ky device token FCM (API #76)
  Future<void> registerDeviceToken([String? token]) async {
    if (!authenticated) return;
    try {
      final t = token ?? 'ptx-fcm-${session.user?.id ?? "client"}';
      await notificationRepository.registerDeviceToken(
        t,
        deviceType: kIsWeb ? 'WEB' : 'ANDROID',
      );
    } catch (_) {}
  }

  /// Goong Maps Autocomplete (API #92)
  Future<List<LocationPredictionDTO>> autocompleteAddress(String input) =>
      locationRepository.autocomplete(input);

  /// Goong Maps Geocode (API #93)
  Future<GeocodeResultDTO> geocodeAddress(String address) =>
      locationRepository.geocode(address);

  /// Goong Maps Reverse Geocode (API #94)
  Future<ReverseGeocodeResultDTO> reverseGeocodeCoordinates(
    double lat,
    double lng,
  ) => locationRepository.reverseGeocode(latitude: lat, longitude: lng);

  Set<String> get interests => _workspace.interests;
  bool get smoking => _workspace.smoking;
  bool get nonSmoking => !_workspace.smoking;
  bool get earlySleep => _workspace.earlySleep;
  bool get tidy => _workspace.tidy;
  bool get allowGuests => _workspace.allowGuests;
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
  final Map<String, Room> _roomCache = {};
  final Map<String, Person> _personCache = {};

  void cacheRoom(Room room) {
    _roomCache[room.id] = room;
  }

  void cachePerson(Person person) {
    _personCache[person.id] = person;
  }

  Room? roomById(String id) {
    if (_roomCache.containsKey(id)) return _roomCache[id];
    final fromFeed = roomController.feed.data?.where((r) => r.id == id).firstOrNull;
    if (fromFeed != null) {
      _roomCache[id] = fromFeed;
      return fromFeed;
    }
    final fromFiltered = roomController.filtered.where((r) => r.id == id).firstOrNull;
    if (fromFiltered != null) {
      _roomCache[id] = fromFiltered;
      return fromFiltered;
    }
    final fromStore = store.rooms.where((r) => r.id == id).firstOrNull;
    if (fromStore != null) return fromStore;
    return null;
  }

  Person? personById(String id) {
    if (_personCache.containsKey(id)) return _personCache[id];
    final p = people.where((p) => p.id == id).firstOrNull;
    if (p != null) {
      _personCache[id] = p;
      return p;
    }
    return null;
  }
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
  Future<void> loadPeople() async {
    if (!authenticated) return;
    try {
      final list = await matchingRepository.getFeed();
      if (list.isNotEmpty) {
        people
          ..clear()
          ..addAll(list);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Load rentals from backend; purges mock data when authenticated.
  Future<void> loadRentals() async {
    if (!authenticated) return;
    try {
      List<RentalDTO> dtos;
      if (role == UserRole.landlord) {
        dtos = await rentalRepository.getMyLandlordRentals();
      } else {
        dtos = await rentalRepository.getMyTenantRentals();
      }
      final live = dtos.map((d) => d.toRental()).toList();
      // Purge fake mock rentals and replace with real server rentals
      store.rentals
        ..removeWhere(
          (r) => role == UserRole.landlord
              ? r.landlordId == userId
              : r.tenantId == userId,
        )
        ..removeWhere((r) => r.id.startsWith('lease-'))
        ..addAll(live);
      notifyListeners();
    } catch (_) {}
  }

  /// API #53: Yêu cầu thuê phòng (Tạo hợp đồng)
  Future<RentalDTO> createRental({
    required String roomId,
    required String startDate,
    required String endDate,
    String? message,
  }) async {
    _requireSession();
    final dto = await rentalRepository.createRental(
      roomId: roomId,
      startDate: startDate,
      endDate: endDate,
      message: message,
    );
    final rental = dto.toRental();
    store.rentals.removeWhere((r) => r.id == rental.id);
    store.rentals.add(rental);
    notifyListeners();
    return dto;
  }

  /// API #59: Kết thúc hợp đồng thuê & Hoàn tất cọc
  Future<void> terminateRental(String rentalId) async {
    _requireSession(UserRole.landlord);
    await rentalRepository.terminateRental(rentalId);
    final local = rentals.where((r) => r.id == rentalId).firstOrNull;
    if (local != null) {
      local.status = RentalStatus.terminated;
      notifyListeners();
    }
  }

  /// Load conversations from backend; merges with local state.
  Future<void> loadConversations() async {
    if (!authenticated) return;
    try {
      final dtos = await chatRepository.getConversations();
      if (dtos.isEmpty) return;
      final local = _workspace.conversations;
      for (final dto in dtos) {
        final existing = local.where((c) => c.id == dto.id).firstOrNull;
        if (existing != null) {
          existing.unread = dto.unreadCount;
        } else {
          local.add(dto.toConversation());
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Load user profile from backend and sync into local workspace.
  Future<void> loadUserProfile() async {
    if (!authenticated) return;
    try {
      final dto = await userRepository.getMe();
      // Sync names and profile info
      if (dto.fullName.isNotEmpty) fullName = dto.fullName;
      if (dto.email.isNotEmpty) email = dto.email;
      if (dto.bio != null && dto.bio!.isNotEmpty) bio = dto.bio!;
      if (dto.interests != null && dto.interests!.isNotEmpty) {
        _workspace.interests = dto.interests!.toSet();
      }
      // Sync avatarUrl
      if (dto.avatarUrl != null && dto.avatarUrl!.isNotEmpty) {
        avatarUrl = dto.avatarUrl;
      }
      // Sync profile details in store
      final p = store.profiles[userId];
      if (p != null) {
        if (dto.gender != null && dto.gender!.isNotEmpty) p.gender = dto.gender!;
        if (dto.birthday != null && dto.birthday!.isNotEmpty) p.birthday = dto.birthday!;
        if (dto.school != null && dto.school!.isNotEmpty) p.school = dto.school!;
        if (dto.avatarUrl != null && dto.avatarUrl!.isNotEmpty) p.avatarUrl = dto.avatarUrl;
        p.trustScore = dto.trustScore;
      }
      try {
        final ts = await userRepository.getTrustScore();
        if (p != null) p.trustScore = ts.currentScore;
      } catch (_) {}
      // Sync KYC status
      if (dto.kycStatus != null) verification = dto.kycStatus!;
      // Sync quotas
      if (dto.roomSwipeQuota >= 0) roomQuota = dto.roomSwipeQuota;
      if (dto.roommateSwipeQuota >= 0) roommateQuota = dto.roommateSwipeQuota;

      // Sync settings (API #22)
      try {
        final userSettings = await userRepository.getSettings();
        settings['public'] = userSettings.isPublic;
        settings['showSchool'] = userSettings.showSchool;
        settings['hideActiveStatus'] = userSettings.hideActiveStatus;
      } catch (_) {}

      // Sync matching profile (API #16)
      if (role == UserRole.tenant) {
        try {
          final mp = await userRepository.getMatchingProfile();
          if (mp.interests.isNotEmpty) _workspace.interests = mp.interests.toSet();
          if (mp.nonSmoking != null) _workspace.smoking = !mp.nonSmoking!;
          if (mp.earlySleeper != null) _workspace.earlySleep = mp.earlySleeper!;
          if (mp.isNeat != null) _workspace.tidy = mp.isNeat!;
          if (mp.allowGuests != null) _workspace.allowGuests = mp.allowGuests!;
        } catch (_) {}
      }

      // Sync consumables (API #78)
      try {
        final consumables = await paymentRepository.getMyConsumables();
        if (consumables.swipesLeft >= 0) roomQuota = consumables.swipesLeft;
        final p = store.profiles[userId];
        if (p != null) {
          p.boosts = consumables.boostsLeft;
        }
      } catch (_) {}

      // Sync active subscription
      try {
        final subs = await paymentRepository.getMySubscriptions();
        if (subs.isNotEmpty) {
          final p = store.profiles[userId];
          if (p != null) {
            p.package = subs.first.planName;
            if (subs.first.endDate != null) {
              p.packageExpiry = DateTime.tryParse(subs.first.endDate!);
            }
          }
        }
      } catch (_) {}

      notifyListeners();
    } catch (_) {}
  }
  Future<bool> authenticate(String login, String password) =>
      session.signIn(login, password);
  Future<bool> authenticateWithGoogle(String idToken, {String role = 'TENANT'}) =>
      session.loginWithGoogle(idToken, role: role);
  void logout() {
    _workspace.drafts.clear();
    final repo = session.repository;
    if (repo is HttpAuthRepository) {
      repo.logout();
    }
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
      if (authenticated) {
        loadUserProfile();
        loadConversations();
      }
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

  void preferences(
    Set<String> selected,
    bool smoke,
    bool early,
    bool clean, {
    bool? allowGuests,
  }) {
    _requireSession();
    _workspace.interests = {...selected};
    _workspace.smoking = smoke;
    _workspace.earlySleep = early;
    _workspace.tidy = clean;
    if (allowGuests != null) _workspace.allowGuests = allowGuests;
    notifyListeners();
    if (authenticated && role == UserRole.tenant) {
      userRepository.updateMatchingProfile(
        interests: selected.toList(),
        nonSmoking: !smoke,
        earlySleeper: early,
        isNeat: clean,
        allowGuests: allowGuests ?? _workspace.allowGuests,
      ).catchError((_) {});
    }
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
    final repo = roomController.repository;
    if (!saved.add(id)) {
      saved.remove(id);
      if (repo is HttpRoomRepository) repo.unsaveRoom(id);
    } else {
      if (repo is HttpRoomRepository) repo.saveRoom(id);
    }
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
      if (!person) {
        final repo = roomController.repository;
        if (repo is HttpRoomRepository) repo.swipeRoom(id, true);
      } else {
        matchingRepository.swipe(id, true);
      }
    } else {
      if (!person) {
        final id = filteredRooms[index].id;
        final repo = roomController.repository;
        if (repo is HttpRoomRepository) repo.swipeRoom(id, false);
      } else {
        final id = filteredPeople[index].id;
        matchingRepository.swipe(id, false);
      }
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
      final repo = roomController.repository;
      if (repo is HttpRoomRepository) {
        repo.resetSwipes().catchError((_) {});
      }
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
        'Hoi thoai khong thuoc tai khoan nay.',
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
          'Phong khong con ton tai.',
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
      // Try real API first if authenticated
      final authRepo = session.repository;
      final token = authRepo is HttpAuthRepository ? authRepo.accessToken : null;
      if (token != null) {
        String targetConvId = c.id;
        if (targetConvId.startsWith('$userId-') && c.participantId.isNotEmpty) {
          try {
            final convDto = await chatRepository.createConversation(
              partnerId: c.participantId,
              roomId: c.roomId,
              type: c.roomId != null ? 'ROOM' : 'ROOMMATE',
            );
            c.id = convDto.id;
            targetConvId = convDto.id;
          } catch (_) {}
        }
        if (!targetConvId.startsWith('$userId-')) {
          await chatRepository.sendMessage(targetConvId, outgoing.text);
        } else {
          await transport.run(() {
            if (_disposed || userId != user || session.revision != revision) {
              throw const RepositoryFailure(
                RepositoryFault.denied,
                'Phien da ket thuc.',
              );
            }
          });
        }
      } else {
        await transport.run(() {
          if (_disposed || userId != user || session.revision != revision) {
            throw const RepositoryFailure(
              RepositoryFault.denied,
              'Phien da ket thuc.',
            );
          }
        });
      }
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

  Future<String?> checkIn(String code, {String? rentalId}) async {
    _requireSession(UserRole.tenant);
    // If rentalId is given, try the real API first
    if (rentalId != null) {
      try {
        final dto = await rentalRepository.verifyCheckIn(rentalId, code);
        // Update local state
        final local = rentals.where((r) => r.id == rentalId).firstOrNull;
        if (local != null) {
          local.checkedIn = true;
          local.status = RentalStatus.active;
        } else {
          // Add the newly activated rental to local store
          store.rentals.add(dto.toRental());
        }
        notifyListeners();
        return null; // success
      } on RepositoryFailure catch (e) {
        return e.message;
      } catch (_) {
        // Fall through to local demo check
      }
    }
    // Fallback: local QR code matching (demo / offline)
    final rental = rentals
        .where(
          (r) =>
              r.code.toUpperCase() == code.trim().toUpperCase() &&
              (rentalId == null || r.id == rentalId),
        )
        .firstOrNull;
    if (rental == null) {
      return 'Ma khong hop le hoac khong thuoc hop dong cua ban.';
    }
    if (rental.status != RentalStatus.active &&
        rental.status != RentalStatus.pending) {
      return 'Hop dong khong con hieu luc.';
    }
    if (rental.checkedIn) return 'Ma nay da duoc su dung.';
    if (rental.codeExpiresAt?.isBefore(DateTime.now()) == true) {
      return 'Ma da het han. Hay lien he chu tro.';
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

  void updateProfile(
    String name,
    String mail,
    String description, {
    String? gender,
    String? birthday,
    String? school,
  }) {
    _requireSession();
    fullName = name;
    email = mail;
    bio = description;
    final p = store.profiles[userId];
    if (p != null) {
      if (gender != null && gender.isNotEmpty) p.gender = gender;
      if (birthday != null && birthday.isNotEmpty) p.birthday = birthday;
      if (school != null && school.isNotEmpty) p.school = school;
    }
    notifyListeners();
    if (authenticated) {
      userRepository.updateMe(
        fullName: name,
        bio: description,
        gender: gender,
        birthday: birthday,
        school: school,
      ).then<void>((_) {}, onError: (_) {});
    }
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
    if (authenticated) {
      notificationRepository.markAllAsRead().catchError((_) {});
    }
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
