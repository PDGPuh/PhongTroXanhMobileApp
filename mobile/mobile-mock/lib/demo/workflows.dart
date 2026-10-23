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
      throw const RepositoryFailure(DemoFault.denied, 'Phiên đã thay đổi.');
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
    List<String> tags,
  ) => run('review-$rentalId', () {
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
    );
    state.store.reviewRecords.add(record);
    state.reviews[rentalId] = (rating: rating, comment: comment.trim());
    return record;
  });

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
        if (!ServicePlan.catalog.contains(plan) ||
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
      if (['plus', 'gold', 'owner-pro', 'owner-premium'].contains(o.plan.id)) {
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
}
