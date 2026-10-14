import '../app/app_state.dart';
import '../core/async_resource.dart';
import 'models.dart';
import 'workflow_models.dart';

/// Async demo server operations. Every mutation validates identity again after
/// transport completes; logout, disposal and account switches invalidate it.
class DemoWorkflows {
  final AppState state;
  int epoch = 0;
  bool disposed = false;
  final Set<String> _pending = {};
  DemoWorkflows(this.state);
  int _codeSequence = 0;
  Future<void> refreshCode(String rentalId) => run('code-$rentalId', () {
    final r = state.rentals.where((r) => r.id == rentalId).firstOrNull;
    if (r == null || r.checkedIn || r.status != RentalStatus.active) {
      throw const RepositoryFailure(
        DemoFault.denied,
        'Chỉ tạo mã cho hợp đồng đang chờ nhận phòng.',
      );
    }
    r.code = 'PTX-${DateTime.now().microsecondsSinceEpoch}-${++_codeSequence}';
    r.codeExpiresAt = DateTime.now().add(const Duration(hours: 24));
  }, role: UserRole.landlord);
  Future<void> deleteAccount(String password) async {
    final user = state.session.user;
    final revision = epoch;
    if (user == null || disposed) {
      throw const RepositoryFailure(DemoFault.denied, 'Cần đăng nhập.');
    }
    await state.session.repository.signIn(user.email, password);
    if (revision != epoch) {
      throw const RepositoryFailure(
        DemoFault.denied,
        'Phiên đã thay đổi.',
      );
    }
    await run('delete-account', () {
      state.store.deleted.add(user.id);
      final workspace = state.store.workspace(user);
      workspace.saved.clear();
      workspace.liked.clear();
      workspace.drafts.clear();
      workspace.conversations.clear();
      workspace.notifications.clear();
      workspace.media.clear();
      state.store.profiles[user.id]?.avatarPhoto = null;
      state.store.matches.remove(user.id);
      for (final s in state.store.swaps.where((s) => s.tenantId == user.id)) {
        s.status = 'Đã hủy';
      }
      for (final p in state.store.proposals.where(
        (p) => p.proposerId == user.id && p.status == 'Chờ phản hồi',
      )) {
        p.status = 'Đã từ chối';
      }
    });
  }

  Future<SupportTicket> support(String subject, String content) =>
      run('support', () {
        if (subject.trim().isEmpty || content.trim().isEmpty) {
          throw const RepositoryFailure(
            DemoFault.server,
            'Nhập tiêu đề và nội dung hỗ trợ.',
          );
        }
        final ticket = SupportTicket(
          'support-${state.store.tickets.length + 1}',
          state.userId!,
          subject.trim(),
          content.trim(),
        );
        state.store.tickets.add(ticket);
        return ticket;
      });
  void sessionChanged() => epoch++;
  Future<T> run<T>(String key, T Function() action, {UserRole? role}) async {
    final user = state.session.user;
    final revision = epoch;
    if (disposed ||
        user == null ||
        (role != null && user.role != role) ||
        state.store.blocked.contains(user.id) ||
        state.store.deleted.contains(user.id)) {
      throw const RepositoryFailure(
        DemoFault.denied,
        'Thao tác không được phép.',
      );
    }
    final operationKey = '${user.id}:$key';
    if (!_pending.add(operationKey)) {
      throw const RepositoryFailure(
        DemoFault.denied,
        'Thao tác đang được xử lý.',
      );
    }
    try {
      return await state.transport.run(() {
        if (disposed ||
            revision != epoch ||
            state.userId != user.id ||
            state.store.blocked.contains(user.id) ||
            state.store.deleted.contains(user.id)) {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Phiên làm việc đã thay đổi.',
          );
        }
        final result = action();
        state.changed();
        return result;
      });
    } finally {
      _pending.remove(operationKey);
    }
  }

  Future<KycRecord> submitKyc(String number, String front, String back) =>
      run('kyc', () {
        if (!RegExp(r'^\d{12}$').hasMatch(number) ||
            front.isEmpty ||
            back.isEmpty) {
          throw const RepositoryFailure(
            DemoFault.server,
            'Nhập số CCCD 12 chữ số và đủ hai mặt.',
          );
        }
        final previous = state.store.kyc
            .where((k) => k.userId == state.userId)
            .lastOrNull;
        for (final ref in [front, back]) {
          if (!['front', 'back', 'demo-front', 'demo-back'].contains(ref) &&
              state.ownPhoto(ref) == null) {
            throw const RepositoryFailure(
              DemoFault.denied,
              'Ảnh giấy tờ không thuộc tài khoản đang gửi. Hãy chọn lại.',
            );
          }
        }
        if (previous != null && previous.status != 'Đã từ chối') {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Hồ sơ đã gửi; chỉ gửi lại sau khi bị từ chối.',
          );
        }
        final item = KycRecord(
          'kyc-${state.store.kyc.length + 1}',
          state.userId!,
          number,
          front,
          back,
        );
        state.store.kyc.add(item);
        state.verification = item.status;
        return item;
      });

  Future<void> decideKyc(String id, bool approved, String note) =>
      run('kyc-$id', () {
        final item = state.store.kyc.where((k) => k.id == id).firstOrNull;
        if (item == null || item.status != 'Chờ duyệt') {
          throw const RepositoryFailure(
            DemoFault.missing,
            'Hồ sơ không còn chờ duyệt.',
          );
        }
        if (!approved && note.trim().isEmpty) {
          throw const RepositoryFailure(
            DemoFault.server,
            'Nhập lý do từ chối để người dùng sửa hồ sơ.',
          );
        }
        item.status = approved ? 'Đã xác minh' : 'Đã từ chối';
        item.note = note.trim();
        final workspace = state.store.workspaceById(item.userId);
        workspace.verification = item.status;
        workspace.notifications.add(
          AppNotification(
            id: 'decision-$id',
            title: 'Kết quả xác minh: ${item.status}',
            description: item.note,
            verification: true,
          ),
        );
      }, role: UserRole.admin);

  Future<ReviewRecord> review(
    String rentalId,
    int rating,
    String comment,
    List<String> tags, {
    int cleanlinessRating = 5,
    int accuracyRating = 5,
    int communicationRating = 5,
  }) => run('review-$rentalId', () {
    final rental = state.reviewableRentals
        .where((r) => r.id == rentalId)
        .firstOrNull;
    if (rental == null || rating < 1 || rating > 5 || comment.trim().isEmpty) {
      throw const RepositoryFailure(
        DemoFault.denied,
        'Chọn hợp đồng đã nhận phòng, số sao và nhận xét.',
      );
    }
    if (state.store.reviewRecords.any(
      (r) => r.rentalId == rentalId && r.authorId == state.userId,
    )) {
      throw const RepositoryFailure(
        DemoFault.denied,
        'Bạn đã đánh giá hợp đồng này.',
      );
    }
    final owner = state.role == UserRole.landlord;
    final record = ReviewRecord(
      'review-${state.store.reviewRecords.length + 1}',
      rentalId,
      state.userId!,
      state.fullName,
      owner ? 'USER' : 'ROOM',
      owner ? rental.tenantId : rental.room.id,
      rating,
      comment.trim(),
      [...tags],
      cleanlinessRating: cleanlinessRating,
      accuracyRating: accuracyRating,
      communicationRating: communicationRating,
    );
    state.store.reviewRecords.add(record);
    state.reviews[rentalId] = (rating: rating, comment: comment.trim());
    return record;
  });

  Future<void> replyReview(String reviewId, String reply) =>
      run('reply-review-$reviewId', () {
        final record = state.store.reviewRecords
            .where((r) => r.id == reviewId)
            .firstOrNull;
        if (record == null ||
            reply.trim().isEmpty ||
            !state.myRooms.any((room) => room.id == record.targetId)) {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Nhập nội dung phản hồi hợp lệ cho đánh giá thuộc phòng của bạn.',
          );
        }
        record.landlordReply = reply.trim();
        record.repliedAt = DateTime.now();
      }, role: UserRole.landlord);

  Future<void> disputeReview(String reviewId, String reason) =>
      run('dispute-review-$reviewId', () {
        final record = state.store.reviewRecords
            .where((r) => r.id == reviewId)
            .firstOrNull;
        if (record == null ||
            reason.trim().isEmpty ||
            !state.myRooms.any((room) => room.id == record.targetId)) {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Nhập lý do khiếu nại và bằng chứng hợp lệ.',
          );
        }
        record.disputeStatus = 'Chờ xử lý';
        record.disputeReason = reason.trim();
      }, role: UserRole.landlord);

  Future<ReportRecord> report(
    String type,
    String targetId,
    String reason,
    String details,
  ) => run('report-$type-$targetId', () {
    final exists = switch (type) {
      'ROOM' => state.roomById(targetId) != null,
      'CONVERSATION' => state.conversationById(targetId) != null,
      'REVIEW' => state.store.reviewRecords.any((r) => r.id == targetId),
      'USER' =>
        state.store.profiles.containsKey(targetId) ||
            state.personById(targetId) != null,
      _ => false,
    };
    if (!exists || reason.trim().isEmpty || details.trim().isEmpty) {
      throw const RepositoryFailure(
        DemoFault.server,
        'Chọn đối tượng và mô tả vi phạm.',
      );
    }
    final item = ReportRecord(
      'report-${state.store.reports.length + 1}',
      state.userId!,
      type,
      targetId,
      reason,
      details.trim(),
    );
    state.store.reports.add(item);
    return item;
  });

  Future<void> resolveReport(String id, String action, String note) =>
      run('report-$id', () {
        final item = state.store.reports.where((r) => r.id == id).firstOrNull;
        if (item == null || item.status != 'Chờ xử lý') {
          throw const RepositoryFailure(
            DemoFault.missing,
            'Báo cáo không còn chờ xử lý.',
          );
        }
        if (![
              'resolve',
              'dismiss',
              'warn',
              'remove_content',
              'ban',
            ].contains(action) ||
            note.trim().isEmpty) {
          throw const RepositoryFailure(
            DemoFault.server,
            'Chọn hành động và ghi chú xử lý.',
          );
        }
        if (action == 'remove_content') {
          final room = state.roomById(item.targetId);
          if (item.targetType != 'ROOM' || room == null) {
            throw const RepositoryFailure(
              DemoFault.denied,
              'Đối tượng không phải tin phòng.',
            );
          }
          state.store.rooms[state.store.rooms.indexOf(room)] = room.copyWith(
            status: RoomStatus.hidden,
          );
          state.roomController.feed.clear();
        }
        if (action == 'ban') {
          final target = item.targetType == 'ROOM'
              ? state.roomById(item.targetId)?.landlordId
              : item.targetId;
          if (target == null ||
              !state.store.profiles.containsKey(target) ||
              target == state.userId) {
            throw const RepositoryFailure(
              DemoFault.denied,
              'Không thể khóa đối tượng này.',
            );
          }
          state.store.blocked.add(target);
        }
        item.status = action == 'dismiss' ? 'Đã bỏ qua' : 'Đã xử lý';
        item.history.add(
          '$action • ${note.trim()} • ${DateTime.now().toIso8601String()}',
        );
      }, role: UserRole.admin);

  Future<void> userStatus(String id, bool blocked, String note) =>
      run('user-$id', () {
        if (id == state.userId ||
            !state.store.profiles.containsKey(id) ||
            note.trim().isEmpty) {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Chọn tài khoản khác và nhập lý do.',
          );
        }
        blocked ? state.store.blocked.add(id) : state.store.blocked.remove(id);
      }, role: UserRole.admin);

  Future<void> moderateRoom(String id, bool approve) => run('room-$id', () {
    final room = state.roomById(id);
    if (room == null || room.status != RoomStatus.pending) {
      throw const RepositoryFailure(
        DemoFault.denied,
        'Tin không còn chờ duyệt.',
      );
    }
    state.store.rooms[state.store.rooms.indexOf(room)] = room.copyWith(
      status: approve ? RoomStatus.available : RoomStatus.hidden,
    );
    state.roomController.feed.clear();
  }, role: UserRole.admin);

  Future<SwapRequest> createSwap(SwapRequest draft) => run('swap-create', () {
    if (draft.reason.trim().isEmpty ||
        draft.targetDistrict.isEmpty ||
        draft.budgetMax <= 0 ||
        state.swaps.any(
          (s) =>
              s.roomId == draft.roomId &&
              !['Đã từ chối', 'Đã hủy', 'Hoàn tất'].contains(s.status),
        )) {
      throw const RepositoryFailure(
        DemoFault.server,
        'Điền nhu cầu hợp lệ; mỗi phòng chỉ có một yêu cầu đang mở.',
      );
    }
    state.addSwap(draft);
    return state.swaps.last;
  }, role: UserRole.tenant);

  Future<void> decideSwap(String id, bool approved, String note) =>
      run('swap-$id', () {
        final item = state.swaps.where((s) => s.id == id).firstOrNull;
        if (item == null ||
            item.status != 'Chờ duyệt' ||
            (!approved && note.trim().isEmpty)) {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Yêu cầu không còn chờ duyệt hoặc thiếu lý do.',
          );
        }
        state.resolveSwap(item, approved);
        item.decisionNote = note.trim();
      }, role: UserRole.landlord);

  Future<SwapProposal> propose(
    String listingId,
    String rentalId,
    String note,
  ) => run('proposal-$listingId', () {
    final listing = state.store.swaps
        .where((s) => s.id == listingId)
        .firstOrNull;
    final offered = state.reviewableRentals
        .where((r) => r.id == rentalId)
        .firstOrNull;
    if (listing == null ||
        listing.tenantId == state.userId ||
        offered == null ||
        !['Đã duyệt', 'Đang tìm phòng phù hợp'].contains(listing.status) ||
        state.store.proposals.any(
          (p) =>
              p.listingId == listingId &&
              p.proposerId == state.userId &&
              p.status != 'Đã từ chối',
        )) {
      throw const RepositoryFailure(
        DemoFault.denied,
        'Chọn tin đang mở và phòng bạn đã nhận; không gửi đề nghị lặp.',
      );
    }
    final item = SwapProposal(
      'proposal-${state.store.proposals.length + 1}',
      listingId,
      state.userId!,
      rentalId,
      note.trim(),
    );
    state.store.proposals.add(item);
    return item;
  }, role: UserRole.tenant);

  Future<void> respondProposal(String id, bool accept) =>
      run('proposal-$id', () {
        final p = state.store.proposals.where((p) => p.id == id).firstOrNull;
        final listing = state.store.swaps
            .where((s) => s.id == p?.listingId)
            .firstOrNull;
        if (p == null ||
            listing == null ||
            listing.tenantId != state.userId ||
            p.status != 'Chờ phản hồi' ||
            !['Đã duyệt', 'Đang tìm phòng phù hợp'].contains(listing.status)) {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Đề nghị không còn khả dụng.',
          );
        }
        p.status = accept ? 'Đã chấp nhận' : 'Đã từ chối';
        if (accept) {
          listing.status = 'Đã ghép • chờ hợp đồng mới';
          for (final other in state.store.proposals.where(
            (o) =>
                o.listingId == listing.id &&
                o.id != id &&
                o.status == 'Chờ phản hồi',
          )) {
            other.status = 'Đã từ chối';
          }
        }
      }, role: UserRole.tenant);

  Future<void> cancelSwap(String id) => run('swap-cancel-$id', () {
    final s = state.swaps.where((s) => s.id == id).firstOrNull;
    if (s == null ||
        [
          'Hoàn tất',
          'Đã hủy',
          'Đã ghép • chờ hợp đồng mới',
        ].contains(s.status)) {
      throw const RepositoryFailure(
        DemoFault.denied,
        'Yêu cầu không thể hủy ở trạng thái này.',
      );
    }
    s.status = 'Đã hủy';
    for (final p in state.store.proposals.where(
      (p) => p.listingId == id && p.status == 'Chờ phản hồi',
    )) {
      p.status = 'Đã từ chối';
    }
  }, role: UserRole.tenant);

  Future<void> confirmMatch(String personId, {bool likeBack = false}) =>
      run('match-$personId', () {
        final gold =
            state.unlimitedSwipes &&
            state.store.profiles[state.userId]?.package == 'Green Gold';
        if ((!state.liked.contains(personId) && !(likeBack && gold)) ||
            !(state.store.incomingLikes[state.userId]?.contains(personId) ??
                false)) {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Chỉ ghép khi cả hai đã gửi lời thích.',
          );
        }
        state.liked.add(personId);
        if (state.store.matches
            .putIfAbsent(state.userId!, () => {})
            .add(personId)) {
          state.store
              .workspace(state.session.user!)
              .notifications
              .add(
                AppNotification(
                  id: 'match-$personId',
                  title: 'Bạn có match mới',
                  description: state.personById(personId)!.name,
                  target: ResourceRef(ResourceKind.person, personId),
                ),
              );
        }
      }, role: UserRole.tenant);
  Future<void> unmatch(String personId) => run('unmatch-$personId', () {
    state.store.matches[state.userId]?.remove(personId);
    state.liked.remove(personId);
    state.store.incomingLikes[state.userId]?.remove(personId);
  }, role: UserRole.tenant);

  Future<PaymentOrder> checkout(ServicePlan plan, bool yearly, String method) =>
      run('checkout', () {
        final knownPlan =
            ServicePlan.catalog.contains(plan) ||
            state.store.plans.any((p) => p.id == plan.id);
        if (!knownPlan ||
            plan.landlord != (state.role == UserRole.landlord) ||
            state.role == UserRole.admin ||
            (yearly && plan.yearly <= 0) ||
            !['MoMo', 'Ngân hàng', 'Thẻ'].contains(method)) {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Gói hoặc phương thức không phù hợp.',
          );
        }
        final order = PaymentOrder(
          'order-${state.store.orders.length + 1}',
          state.userId!,
          plan,
          yearly,
          method,
        );
        state.store.orders.add(order);
        return order;
      });
  Future<void> paymentResult(
    String id,
    String result,
  ) => run('payment-$id', () {
    final o = state.store.orders
        .where((o) => o.id == id && o.userId == state.userId)
        .firstOrNull;
    if (o == null || !['Thành công', 'Thất bại', 'Đã hủy'].contains(result)) {
      throw const RepositoryFailure(
        DemoFault.missing,
        'Không tìm thấy giao dịch.',
      );
    }
    if (o.status != 'Chờ thanh toán') {
      return;
    }
    o.status = result;
    if (result == 'Thành công') {
      final profile = state.store.profiles[state.userId]!;
      if (['plus', 'gold', 'owner-pro', 'owner-premium'].contains(o.plan.id) ||
          o.plan.monthly >= 39000 && o.plan.extraSwipes == 0) {
        profile.package = o.plan.name;
        profile.packageExpiry = DateTime.now().add(
          Duration(days: o.yearly ? 365 : 30),
        );
      }
      state.roomQuota += o.plan.extraSwipes;
      state.store.workspace(state.session.user!).roomAllowance +=
          o.plan.extraSwipes;
      profile.boosts += o.plan.boosts;
      profile.superMatches += o.plan.superMatches;
    }
  });

  Future<void> consume(String type, String? targetId) =>
      run('consume-$type', () {
        final profile = state.store.profiles[state.userId]!;
        if (type == 'BOOST' && profile.boosts > 0) {
          profile.boosts--;
          profile.boostedAt = DateTime.now();
        } else if (type == 'SUPER' &&
            profile.superMatches > 0 &&
            targetId != null &&
            state.personById(targetId) != null &&
            !profile.priorityPeople.contains(targetId)) {
          profile.superMatches--;
          profile.priorityPeople.add(targetId);
          state.liked.add(targetId);
        } else {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Không còn lượt sử dụng.',
          );
        }
      });

  Future<void> renewRoom(String roomId, {int days = 30}) =>
      run('renew-$roomId', () {
        final room = state.roomById(roomId);
        if (room == null || room.landlordId != state.userId) {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Phòng không thuộc tài khoản của bạn.',
          );
        }
        final base = room.expiresAt != null && room.expiresAt!.isAfter(DateTime.now())
            ? room.expiresAt!
            : DateTime.now();
        final idx = state.store.rooms.indexWhere((r) => r.id == roomId);
        state.store.rooms[idx] = room.copyWith(
          expiresAt: base.add(Duration(days: days)),
        );
      }, role: UserRole.landlord);

  Future<void> boostRoom(String roomId) => run('boost-room-$roomId', () {
    final room = state.roomById(roomId);
    if (room == null || room.landlordId != state.userId) {
      throw const RepositoryFailure(
        DemoFault.denied,
        'Phòng không thuộc tài khoản của bạn.',
      );
    }
    final profile = state.store.profiles[state.userId]!;
    if (profile.boosts <= 0) {
      throw const RepositoryFailure(
        DemoFault.denied,
        'Bạn đã hết lượt Đẩy tin. Hãy nâng cấp gói dịch vụ để nhận thêm lượt.',
      );
    }
    profile.boosts--;
    profile.boostedAt = DateTime.now();
    final idx = state.store.rooms.indexWhere((r) => r.id == roomId);
    state.store.rooms[idx] = room.copyWith(isBoosted: true);
  }, role: UserRole.landlord);

  Future<void> confirmHandover(String rentalId) =>
      run('handover-$rentalId', () {
        final rental = state.rentals.where((r) => r.id == rentalId).firstOrNull;
        if (rental == null || rental.status != RentalStatus.active) {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Không tìm thấy hợp đồng đang hoạt động để bàn giao.',
          );
        }
        rental.checkedIn = true;
        rental.handoverConfirmed = true;
        final tenantWorkspace = state.store.workspaceById(rental.tenantId);
        tenantWorkspace.notifications.add(
          AppNotification(
            id: 'handover-${rental.id}-${DateTime.now().millisecondsSinceEpoch}',
            title: 'Đã xác nhận bàn giao phòng',
            description: 'Chủ trọ đã xác nhận bàn giao phòng ${rental.room.title}.',
            target: ResourceRef(ResourceKind.rental, rental.id),
          ),
        );
      }, role: UserRole.landlord);

  Future<void> terminateRental(String rentalId, String reason) =>
      run('terminate-$rentalId', () {
        final rental = state.rentals.where((r) => r.id == rentalId).firstOrNull;
        if (rental == null || reason.trim().isEmpty) {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Nhập lý do chấm dứt hợp đồng.',
          );
        }
        rental.status = RentalStatus.terminated;
        rental.terminationReason = reason.trim();
        final room = state.roomById(rental.room.id);
        if (room != null) {
          final idx = state.store.rooms.indexOf(room);
          state.store.rooms[idx] = room.copyWith(status: RoomStatus.available);
          state.roomController.feed.clear();
        }
      }, role: UserRole.landlord);

  Future<void> warnUser(String userId, String reason) =>
      run('warn-user-$userId', () {
        final profile = state.store.profiles[userId];
        if (profile == null || userId == state.userId || reason.trim().isEmpty) {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Chọn người dùng hợp lệ và nhập lý do cảnh cáo.',
          );
        }
        profile.warned = !profile.warned;
        profile.warningNote = reason.trim();
        if (profile.warned) {
          profile.trustScore = (profile.trustScore - 15).clamp(0, 100);
          state.store.workspace(profile.user).notifications.add(
            AppNotification(
              id: 'warn-$userId-${DateTime.now().millisecondsSinceEpoch}',
              title: 'Cảnh báo từ Quản trị viên',
              description: reason.trim(),
            ),
          );
        }
        state.store.auditLogs.insert(
          0,
          AuditLogRecord(
            id: 'audit-${state.store.auditLogs.length + 1}',
            actorName: state.fullName,
            action: profile.warned ? 'CẢNH CÁO NGƯỜI DÙNG' : 'GỠ CẢNH CÁO',
            target: '${profile.user.email} • ${reason.trim()}',
          ),
        );
      }, role: UserRole.admin);

  Future<void> toggleUserVerification(
    String userId,
    bool verified,
    String note,
  ) => run('verify-user-$userId', () {
    final profile = state.store.profiles[userId];
    if (profile == null) {
      throw const RepositoryFailure(
        DemoFault.missing,
        'Không tìm thấy tài khoản.',
      );
    }
    final workspace = state.store.workspace(profile.user);
    workspace.verification = verified ? 'Đã xác minh' : 'Chưa xác minh';
    profile.trustScore = (profile.trustScore + (verified ? 15 : -15)).clamp(
      0,
      100,
    );
    workspace.notifications.add(
      AppNotification(
        id: 'admin-verify-$userId-${DateTime.now().millisecondsSinceEpoch}',
        title: verified
            ? 'Tài khoản đã được cấp tích xanh xác minh'
            : 'Trạng thái xác minh đã được thu hồi',
        description: note.trim().isEmpty
            ? 'Cập nhật trực tiếp bởi Quản trị viên (+Điểm uy tín).'
            : note.trim(),
        verification: true,
      ),
    );
    state.store.auditLogs.insert(
      0,
      AuditLogRecord(
        id: 'audit-${state.store.auditLogs.length + 1}',
        actorName: state.fullName,
        action: verified ? 'CẤP TÍCH XANH XÁC MINH' : 'THU HỒI XÁC MINH',
        target: profile.user.email,
      ),
    );
  }, role: UserRole.admin);

  Future<void> adminResetPassword(String userId) =>
      run('reset-pw-$userId', () {
        final profile = state.store.profiles[userId];
        if (profile == null) {
          throw const RepositoryFailure(
            DemoFault.missing,
            'Không tìm thấy tài khoản.',
          );
        }
        state.store.workspace(profile.user).notifications.add(
          AppNotification(
            id: 'pw-reset-$userId-${DateTime.now().millisecondsSinceEpoch}',
            title: 'Yêu cầu đặt lại mật khẩu từ Quản trị viên',
            description:
                'Liên kết đặt lại mật khẩu đã được gửi tới ${profile.user.email}.',
          ),
        );
        state.store.auditLogs.insert(
          0,
          AuditLogRecord(
            id: 'audit-${state.store.auditLogs.length + 1}',
            actorName: state.fullName,
            action: 'RESET MẬT KHẨU',
            target: profile.user.email,
          ),
        );
      }, role: UserRole.admin);

  Future<void> notifyUser(String userId, String title, String content) =>
      run('notify-$userId', () {
        final profile = state.store.profiles[userId];
        if (profile == null ||
            title.trim().isEmpty ||
            content.trim().isEmpty) {
          throw const RepositoryFailure(
            DemoFault.server,
            'Nhập tiêu đề và nội dung thông báo.',
          );
        }
        state.store.workspace(profile.user).notifications.add(
          AppNotification(
            id: 'admin-msg-$userId-${DateTime.now().millisecondsSinceEpoch}',
            title: title.trim(),
            description: content.trim(),
          ),
        );
        state.store.auditLogs.insert(
          0,
          AuditLogRecord(
            id: 'audit-${state.store.auditLogs.length + 1}',
            actorName: state.fullName,
            action: 'GỬI THÔNG BÁO TRỰC TIẾP',
            target: '${profile.user.email} • ${title.trim()}',
          ),
        );
      }, role: UserRole.admin);

  Future<void> adminSavePlan(ServicePlan plan) =>
      run('save-plan-${plan.id}', () {
        if (plan.name.trim().isEmpty ||
            plan.monthly <= 0 ||
            plan.description.trim().isEmpty) {
          throw const RepositoryFailure(
            DemoFault.server,
            'Nhập tên gói, giá tháng (> 0đ) và mô tả quyền lợi.',
          );
        }
        final idx = state.store.plans.indexWhere((p) => p.id == plan.id);
        final isNew = idx < 0;
        if (isNew) {
          state.store.plans.add(plan);
        } else {
          state.store.plans[idx] = plan;
        }
        for (final profile in state.store.profiles.values) {
          if (profile.user.role ==
              (plan.landlord ? UserRole.landlord : UserRole.tenant)) {
            state.store.workspace(profile.user).notifications.add(
              AppNotification(
                id: 'plan-${plan.id}-${DateTime.now().millisecondsSinceEpoch}',
                title: isNew
                    ? 'Ra mắt gói dịch vụ mới: ${plan.name}'
                    : 'Cập nhật gói dịch vụ: ${plan.name}',
                description: plan.description,
              ),
            );
          }
        }
        state.store.auditLogs.insert(
          0,
          AuditLogRecord(
            id: 'audit-${state.store.auditLogs.length + 1}',
            actorName: state.fullName,
            action: isNew ? 'TẠO GÓI DỊCH VỤ' : 'CẬP NHẬT GÓI DỊCH VỤ',
            target: '${plan.name} (${plan.monthly}đ/tháng)',
          ),
        );
      }, role: UserRole.admin);

  Future<void> adminDeletePlan(String planId) =>
      run('delete-plan-$planId', () {
        final plan = state.store.plans.where((p) => p.id == planId).firstOrNull;
        if (plan == null) {
          throw const RepositoryFailure(
            DemoFault.missing,
            'Không tìm thấy gói dịch vụ.',
          );
        }
        state.store.plans.removeWhere((p) => p.id == planId);
        state.store.auditLogs.insert(
          0,
          AuditLogRecord(
            id: 'audit-${state.store.auditLogs.length + 1}',
            actorName: state.fullName,
            action: 'XÓA GÓI DỊCH VỤ',
            target: plan.name,
          ),
        );
      }, role: UserRole.admin);

  Future<void> resolveDispute(
    String reviewId,
    bool upholdDispute,
    String note,
  ) => run('resolve-dispute-$reviewId', () {
    final record = state.store.reviewRecords
        .where((r) => r.id == reviewId)
        .firstOrNull;
    if (record == null || note.trim().isEmpty) {
      throw const RepositoryFailure(
        DemoFault.server,
        'Nhập ghi chú kết luận giải quyết khiếu nại.',
      );
    }
    record.disputeStatus = upholdDispute ? 'Đã chấp nhận' : 'Đã bác bỏ';
    record.disputeResolutionNote = note.trim();
    state.store.auditLogs.insert(
      0,
      AuditLogRecord(
        id: 'audit-${state.store.auditLogs.length + 1}',
        actorName: state.fullName,
        action: upholdDispute ? 'CHẤP NHẬN KHIẾU NẠI REVIEW' : 'BÁC BỎ KHIẾU NẠI REVIEW',
        target: '${record.id} • ${note.trim()}',
      ),
    );
  }, role: UserRole.admin);

  Future<void> deleteSystemFeedback(String feedbackId) =>
      run('delete-feedback-$feedbackId', () {
        state.store.systemFeedbacks.removeWhere((f) => f.id == feedbackId);
      }, role: UserRole.admin);
}
