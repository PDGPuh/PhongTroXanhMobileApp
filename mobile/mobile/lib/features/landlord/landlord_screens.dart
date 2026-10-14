import 'dart:convert';

export '../rentals/rental_workflows.dart'
    show LandlordSwapsScreen, LandlordReviewsScreen, LandlordTenantsScreen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../core/theme.dart';
import '../../core/device_media.dart';
import '../../core/widgets.dart';
import '../../core/reference_photo.dart';
import '../../domain/models.dart';
import '../rooms/room_screens.dart';
import '../rooms/room_gallery.dart';
import '../account/account_screens.dart';
import '../rentals/rental_screens.dart';

class LandlordScreen extends StatelessWidget {
  final AppState state;
  const LandlordScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    final myRooms = state.myRooms;
    final availableCount =
        myRooms.where((r) => r.status == RoomStatus.available).length;
    final pendingCount =
        myRooms.where((r) => r.status == RoomStatus.pending).length;
    final activeTenants =
        state.rentals.map((r) => r.tenantId).toSet().length;
    final roomReviews = state.store.reviewRecords
        .where((r) => myRooms.any((room) => room.id == r.targetId))
        .toList();
    final rentedCount = myRooms
        .where(
          (r) =>
              r.status == RoomStatus.rented ||
              state.rentals.any(
                (l) =>
                    l.room.id == r.id &&
                    l.status == RentalStatus.active &&
                    l.checkedIn,
              ),
        )
        .length;
    final occupancyRate =
        myRooms.isEmpty ? 0 : ((rentedCount / myRooms.length) * 100).round();
    final totalViews =
        myRooms.fold<int>(0, (sum, r) => sum + state.roomViews(r.id)) +
        myRooms.length * 18;
    final totalSaves =
        myRooms.fold<int>(0, (sum, r) => sum + state.roomSaves(r.id)) +
        myRooms.length * 5;
    final totalContacts =
        myRooms.fold<int>(0, (sum, r) => sum + r.contactCount);
    final profile = state.store.profiles[state.userId];
    final monthlyEst = myRooms
        .where((r) => r.status == RoomStatus.available || r.status == RoomStatus.rented)
        .fold<int>(0, (sum, r) => sum + r.price);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Header(
          unreadNotifications: state.unreadNotifications,
          owner: true,
          onProfile: () => openPage(
            context,
            ProfileScreen(
              state: state,
              onLogout: () => AppScope.maybeOf(context)?.logout(),
            ),
          ),
          onMap: () => openPage(context, MapScreen(state: state)),
          onNotifications: () =>
              openPage(context, NotificationsScreen(state: state)),
        ),
        const PageHeading(
          'Bảng điều khiển Chủ trọ',
          'Quản lý tài sản, hợp đồng và tối ưu hiệu suất cho thuê',
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [PT.deep, Color(0xFF006B54)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18073B3C),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Pill(
                    'Hội viên: ${profile?.package ?? 'Miễn phí'}',
                    dense: true,
                    color: Colors.white,
                    bg: Colors.white.withValues(alpha: 0.16),
                  ),
                  Pill(
                    '${profile?.boosts ?? 0} lượt Đẩy tin',
                    dense: true,
                    color: PT.deep,
                    bg: const Color(0xFFFDE68A),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Doanh thu dự kiến danh mục',
                style: PT.body(12, Colors.white.withValues(alpha: 0.78)),
              ),
              const SizedBox(height: 4),
              Text(
                '${(monthlyEst / 1000000).toStringAsFixed(1)} triệu đ / tháng',
                style: PT.title(24).copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Nâng cấp Chủ trọ Pro / Premium để nhận lượt đẩy tin VIP và báo cáo chuyên sâu.',
                style: PT.body(12, Colors.white.withValues(alpha: 0.82)),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: PT.deep,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        openPage(context, PostRoomScreen(state: state)),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Đăng phòng mới'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        openPage(context, PackagesScreen(state: state)),
                    icon: const Icon(LucideIcons.zap, size: 16),
                    label: const Text('Nâng cấp hội viên / Mua lượt Đẩy tin'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 680 ? 4 : 2;
            final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
            final stats = <Widget>[
              _SmallStat(
                LucideIcons.house,
                '$availableCount',
                'Phòng đang hiển thị',
                'Đang hoạt động',
                PT.green,
                PT.mint,
              ),
              _SmallStat(
                LucideIcons.clock,
                '$pendingCount',
                'Phòng chờ duyệt',
                'Đang xử lý',
                PT.amber,
                const Color(0xFFFFF8ED),
              ),
              _SmallStat(
                LucideIcons.users,
                '$activeTenants',
                'Người thuê',
                'Lấp đầy $occupancyRate%',
                const Color(0xFF0799DE),
                const Color(0xFFEEF8FF),
              ),
              _SmallStat(
                LucideIcons.star,
                '${roomReviews.length}',
                'Đánh giá nhận được',
                'Từ người thuê',
                PT.green,
                PT.mint,
              ),
            ];
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final stat in stats) SizedBox(width: width, child: stat),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: PT.card(radius: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: PT.mint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.trendingUp,
                        size: 18,
                        color: PT.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thống kê lượt xem 7 ngày qua',
                            style: PT.title(17),
                          ),
                          Text(
                            '$totalViews lượt xem • $totalSaves lượt lưu • $totalContacts liên hệ',
                            style: PT.body(12, PT.muted),
                          ),
                        ],
                      ),
                    ),
                    const Pill('+18%', dense: true, color: PT.green),
                  ],
                ),
                const SizedBox(height: 16),
                _Views7DaysChart(baseViews: totalViews),
                const Divider(height: 24, color: PT.line),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tỉ lệ lấp đầy phòng ($rentedCount/${myRooms.length})',
                        style: PT.body(13, PT.muted),
                      ),
                    ),
                    Text(
                      '$occupancyRate%',
                      style: PT.body(14, PT.green).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (occupancyRate / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    color: PT.green,
                    backgroundColor: PT.mint,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Số liệu minh họa trong bản demo', style: PT.caption()),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: Text('Hoạt động gần đây', style: PT.title(21))),
            TextButton.icon(
              onPressed: () =>
                  openPage(context, LandlordRoomsScreen(state: state)),
              icon: const Icon(LucideIcons.arrowRight, size: 15),
              label: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...myRooms
            .take(3)
            .map((r) => _ManageRoomTile(state: state, room: r)),
        const SizedBox(height: 16),
        Text('Quản lý vận hành & Hợp đồng', style: PT.title(19)),
        const SizedBox(height: 10),
        MenuRow(
          spacious: true,
          icon: LucideIcons.users,
          title: 'Người thuê',
          subtitle: 'Hợp đồng, bàn giao phòng và đánh giá',
          onTap: () => openPage(context, LandlordTenantsScreen(state: state)),
        ),
        MenuRow(
          spacious: true,
          icon: LucideIcons.arrowLeftRight,
          title: 'Yêu cầu đổi phòng',
          subtitle: 'Đối chiếu hồ sơ và duyệt chuyển nhượng',
          onTap: () => openPage(context, LandlordSwapsScreen(state: state)),
        ),
        MenuRow(
          spacious: true,
          icon: LucideIcons.qrCode,
          title: 'Mã QR nhận phòng',
          subtitle: 'Tạo mã và chia sẻ cho người thuê',
          onTap: () => openPage(context, LandlordQRScreen(state: state)),
        ),
        MenuRow(
          spacious: true,
          icon: LucideIcons.star,
          title: 'Đánh giá & Phản hồi',
          subtitle: 'Phản hồi công khai và khiếu nại đánh giá',
          onTap: () => openPage(context, LandlordReviewsScreen(state: state)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PT.mint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PT.green.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.lightbulb,
                  size: 22,
                  color: PT.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mẹo tối ưu tỷ lệ lấp đầy', style: PT.title(16)),
                    const SizedBox(height: 4),
                    Text(
                      'Cập nhật biểu phí điện nước minh bạch và bật Đẩy tin VIP vào cuối tuần giúp tăng 2.4x lượt liên hệ.',
                      style: PT.body(13, PT.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Views7DaysChart extends StatelessWidget {
  final int baseViews;
  const _Views7DaysChart({required this.baseViews});
  @override
  Widget build(BuildContext context) {
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    const weights = [0.45, 0.62, 0.54, 0.78, 0.70, 0.92, 1.0];
    final peak = (baseViews / 4).clamp(8, 120).round();
    return Container(
      height: 118,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: PT.grey.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${(peak * weights[i]).round()}',
                      style: PT.caption(
                        i == days.length - 1 ? PT.green : PT.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 50 * weights[i],
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: i == days.length - 1
                              ? const [PT.green, PT.deep]
                              : [
                                  PT.green.withValues(alpha: 0.55),
                                  PT.green.withValues(alpha: 0.25),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      days[i],
                      style: PT.caption(
                        i == days.length - 1 ? PT.deep : PT.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final IconData icon;
  final String value, label, badge;
  final Color color, bg;
  const _SmallStat(
    this.icon,
    this.value,
    this.label,
    this.badge,
    this.color,
    this.bg,
  );
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: PT.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A073B3C),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(value, style: PT.title(26))),
            ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: bg,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.textScalerOf(context).scale(13) * 1.45 * 2,
          ),
          child: Text(label, style: PT.body(13, PT.muted)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            badge,
            style: PT.body(11, color).copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _ManageRoomTile extends StatelessWidget {
  final AppState state;
  final Room room;
  const _ManageRoomTile({required this.state, required this.room});
  @override
  Widget build(BuildContext context) {
    final statusLabel = state.roomStatus[room.id] ?? 'Chờ duyệt';
    final isPending = statusLabel == 'Chờ duyệt';
    final isHidden = statusLabel == 'Đã ẩn';
    final badgeColor = isPending
        ? PT.amber
        : isHidden
        ? PT.muted
        : PT.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: PT.card(radius: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              openPage(context, ManageRoomScreen(state: state, room: room)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 102,
                  height: 98,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Positioned.fill(child: RoomPhoto(room: room)),
                        Positioned(
                          left: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              statusLabel,
                              style: PT.body(9, badgeColor).copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (room.isBoosted)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: PT.amber,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'VIP',
                                style: PT.body(9, Colors.white).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.title,
                        style: PT.title(16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${room.district}, TP.HCM • ${room.area}m²',
                        style: PT.body(12, PT.muted),
                      ),
                      const SizedBox(height: 6),
                      Text(room.priceLabel, style: PT.price(16)),
                      if (room.expiresAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Hết hạn: ${room.expiresAt!.toString().substring(0, 10)}',
                          style: PT.body(11, PT.green),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.eye,
                                size: 12,
                                color: PT.muted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${state.roomViews(room.id)} lượt xem',
                                style: PT.body(11, PT.muted),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.heart,
                                size: 12,
                                color: PT.muted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${state.roomSaves(room.id)} lượt lưu',
                                style: PT.body(11, PT.muted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 18, color: PT.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LandlordRoomsScreen extends StatefulWidget {
  final AppState state;
  final bool standalone;
  const LandlordRoomsScreen({
    super.key,
    required this.state,
    this.standalone = true,
  });
  @override
  State<LandlordRoomsScreen> createState() => _LandlordRoomsScreenState();
}

class _LandlordRoomsScreenState extends State<LandlordRoomsScreen> {
  String statusFilter = 'Tất cả';
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final content = ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final rooms = state.myRooms
            .where(
              (r) => statusFilter == 'Tất cả' || r.status.label == statusFilter,
            )
            .toList();
        final boostsLeft = state.store.profiles[state.userId]?.boosts ?? 0;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!widget.standalone)
              const PageHeading(
                'Quản lý phòng',
                'Thông tin phòng, gia hạn và đẩy tin nổi bật',
              ),
            PrimaryButton(
              'Đăng phòng mới',
              icon: LucideIcons.plus,
              onTap: () => openPage(context, PostRoomScreen(state: state)),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Tất cả',
                'Đang hiển thị',
                'Chờ duyệt',
                'Đã cho thuê',
                'Đã ẩn',
              ]
                  .map(
                    (label) => ChoiceChip(
                      label: Text(label),
                      selected: statusFilter == label,
                      onSelected: (_) => setState(() => statusFilter = label),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: PT.mint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: PT.green.withValues(alpha: 0.22)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.zap, size: 16, color: PT.green),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Lượt đẩy tin còn lại: $boostsLeft lượt',
                          style: PT.body(13, PT.deep).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () =>
                        openPage(context, PackagesScreen(state: state)),
                    child: const Text('Mua thêm lượt'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (rooms.isEmpty)
              const EmptyState(
                'Không có phòng trong mục này',
                'Thay đổi bộ lọc trạng thái hoặc đăng phòng mới.',
                icon: LucideIcons.house,
              ),
            ...rooms.map((r) => _ManageRoomTile(state: state, room: r)),
          ],
        );
      },
    );
    return widget.standalone
        ? BasicPage(title: 'Quản lý phòng', child: content)
        : content;
  }
}

class ManageRoomScreen extends StatelessWidget implements ResourceScreen {
  @override
  ResourceRef get resource => ResourceRef(ResourceKind.room, room.id);
  final AppState state;
  final Room room;
  const ManageRoomScreen({super.key, required this.state, required this.room});
  @override
  Widget build(BuildContext context) => BasicPage(
    title: 'Quản lý tin phòng',
    child: ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final room = state.roomById(this.room.id) ?? this.room;
        final boostsLeft = state.store.profiles[state.userId]?.boosts ?? 0;
        final expiryText = room.expiresAt != null
            ? room.expiresAt!.toString().substring(0, 10)
            : 'Mặc định 30 ngày';
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            RoomCard(
              room: room,
              saved: state.isSaved(room.id),
              onSave: () => state.toggleSave(room.id),
              onInfo: () =>
                  openPage(context, RoomDetailScreen(state: state, room: room)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: PT.card(radius: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Chi tiết vận hành & Chi phí', style: PT.title(18)),
                      Pill(
                        room.isBoosted ? 'Đang nổi bật VIP' : 'Tin thường',
                        dense: true,
                        color: room.isBoosted ? PT.amber : PT.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trạng thái: ${state.roomStatus[room.id]} • Hạn tin: $expiryText • Còn $boostsLeft lượt Đẩy tin',
                    style: PT.body(13, PT.muted),
                  ),
                  const Divider(height: 20, color: PT.line),
                  LayoutBuilder(
                    builder: (context, c) {
                      final colWidth = (c.maxWidth - 10) / 2;
                      final fees = [
                        ('Đặt cọc', room.depositLabel),
                        ('Điện', room.electricity),
                        ('Nước', room.water),
                        ('Internet', room.internetFee),
                        ('Gửi xe', room.parkingFee),
                        ('Dịch vụ', room.serviceFee),
                      ];
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final item in fees)
                            Container(
                              width: colWidth,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: PT.mint.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.$1, style: PT.body(11, PT.muted)),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.$2,
                                    style: PT.body(13, PT.deep).copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            MenuRow(
              icon: LucideIcons.pencil,
              title: 'Sửa thông tin',
              onTap: () => openPage(
                context,
                PostRoomScreen(state: state, existing: room),
              ),
            ),
            MenuRow(
              icon: LucideIcons.calendarPlus,
              title: 'Gia hạn tin đăng (+30 ngày)',
              subtitle: 'Hạn hiển thị hiện tại: $expiryText',
              onTap: () async {
                try {
                  await state.workflows.renewRoom(room.id);
                  if (context.mounted) {
                    message(context, 'Đã gia hạn tin phòng thêm 30 ngày.');
                  }
                } catch (e) {
                  if (context.mounted) message(context, e.toString());
                }
              },
            ),
            MenuRow(
              icon: LucideIcons.eyeOff,
              title: state.roomStatus[room.id] == 'Đã ẩn'
                  ? 'Hiển thị tin'
                  : 'Ẩn tin',
              onTap: state.roomById(room.id)?.status == RoomStatus.pending
                  ? null
                  : () => state.setRoomStatus(
                      room,
                      state.roomStatus[room.id] == 'Đã ẩn'
                          ? 'Đang hiển thị'
                          : 'Đã ẩn',
                    ),
            ),
            MenuRow(
              icon: LucideIcons.circleCheck,
              title: 'Đánh dấu đã cho thuê',
              onTap: state.roomById(room.id)?.status == RoomStatus.pending
                  ? null
                  : () => state.setRoomStatus(room, 'Đã cho thuê'),
            ),
            MenuRow(
              icon: LucideIcons.qrCode,
              title: 'Mã QR nhận phòng',
              onTap: () => openPage(context, LandlordQRScreen(state: state)),
            ),
            MenuRow(
              icon: LucideIcons.users,
              title: 'Người thuê',
              subtitle: 'Danh sách người đã nhận phòng & bàn giao',
              onTap: () => openPage(
                context,
                LandlordTenantsScreen(state: state, roomId: room.id),
              ),
            ),
            MenuRow(
              icon: LucideIcons.arrowLeftRight,
              title: 'Yêu cầu hoán đổi',
              onTap: () => openPage(context, LandlordSwapsScreen(state: state)),
            ),
            MenuRow(
              icon: LucideIcons.zap,
              title: 'Đẩy tin nổi bật',
              subtitle: room.isBoosted
                  ? 'Tin đang được ưu tiên hiển thị VIP'
                  : boostsLeft > 0
                  ? 'Dùng 1 lượt Đẩy tin ngay (Còn $boostsLeft lượt)'
                  : 'Mua gói hoặc lượt Đẩy tin mới',
              onTap: () async {
                if (boostsLeft > 0 && !room.isBoosted) {
                  try {
                    await state.workflows.boostRoom(room.id);
                    if (context.mounted) {
                      message(context, 'Đã đẩy tin nổi bật thành công!');
                    }
                  } catch (e) {
                    if (context.mounted) message(context, e.toString());
                  }
                } else {
                  openPage(context, PackagesScreen(state: state));
                }
              },
            ),
          ],
        );
      },
    ),
  );
}

class PostRoomScreen extends StatefulWidget {
  final AppState state;
  final Room? existing;
  const PostRoomScreen({super.key, required this.state, this.existing});
  @override
  State<PostRoomScreen> createState() => _PostRoomScreenState();
}

class _PostRoomScreenState extends State<PostRoomScreen> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.existing?.title ?? ''),
      price = TextEditingController(
        text: widget.existing?.price.toString() ?? '',
      ),
      area = TextEditingController(
        text: widget.existing?.area.toString() ?? '',
      ),
      address = TextEditingController(text: widget.existing?.address ?? ''),
      description = TextEditingController(
        text: widget.existing?.description ?? '',
      ),
      electricity = TextEditingController(
        text: widget.existing?.electricity ?? '3.500đ/kWh',
      ),
      water = TextEditingController(
        text: widget.existing?.water ?? '100.000đ/người',
      ),
      fees = TextEditingController(text: widget.existing?.otherFees ?? ''),
      deposit = TextEditingController(
        text: widget.existing?.deposit.toString() ?? '',
      ),
      internetFee = TextEditingController(
        text: widget.existing?.internetFee ?? 'Miễn phí',
      ),
      parkingFee = TextEditingController(
        text: widget.existing?.parkingFee ?? 'Miễn phí',
      ),
      serviceFee = TextEditingController(
        text: widget.existing?.serviceFee ?? '50.000đ/phòng',
      );
  int step = 0;
  bool photo = false, submitting = false, boostOnPublish = false;
  bool pickingPhotos = false;
  List<LocalPhoto> localPhotos = [];
  String? submitError;
  late final newId = 'room-${DateTime.now().microsecondsSinceEpoch}';
  late final floor = TextEditingController(
    text: '${widget.existing?.floor ?? 3}',
  );
  late final latitude = TextEditingController(
    text: widget.existing?.latitude?.toString() ?? '',
  );
  late final longitude = TextEditingController(
    text: widget.existing?.longitude?.toString() ?? '',
  );
  String get draftKey => 'post-room-${widget.existing?.id ?? 'new'}';
  void saveDraft() {
    widget.state.drafts[draftKey] = jsonEncode({
      'title': title.text,
      'price': price.text,
      'deposit': deposit.text,
      'area': area.text,
      'floor': floor.text,
      'latitude': latitude.text,
      'longitude': longitude.text,
      'address': address.text,
      'description': description.text,
      'electricity': electricity.text,
      'water': water.text,
      'internetFee': internetFee.text,
      'parkingFee': parkingFee.text,
      'serviceFee': serviceFee.text,
      'fees': fees.text,
      'step': step,
      'photo': photo,
      'boostOnPublish': boostOnPublish,
      'localPhotos': localPhotos.map((p) => p.id).toList(),
      'district': district,
      'type': type,
      'amenities': amenities.toList(),
    });
  }

  String district = 'Quận 10', type = 'Studio';
  final amenities = {'Có nội thất', 'Wifi riêng', 'Máy lạnh'};
  @override
  void initState() {
    super.initState();
    district = widget.existing?.district ?? district;
    type = widget.existing?.type ?? type;
    photo = widget.existing != null;
    localPhotos = [...?widget.existing?.localPhotos];
    photo = widget.existing?.images.isNotEmpty ?? false;
    Map<String, dynamic> restored = {};
    try {
      restored = jsonDecode(
        widget.state.drafts[draftKey] ?? '{}',
      ) as Map<String, dynamic>;
    } catch (_) {
      /* Obsolete draft. */
    }
    final controllers = {
      'title': title,
      'price': price,
      'deposit': deposit,
      'area': area,
      'floor': floor,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'description': description,
      'electricity': electricity,
      'water': water,
      'internetFee': internetFee,
      'parkingFee': parkingFee,
      'serviceFee': serviceFee,
      'fees': fees,
    };
    for (final e in controllers.entries) {
      if (restored[e.key] != null) {
        e.value.text = restored[e.key];
      }
      e.value.addListener(saveDraft);
    }
    step = (restored['step'] as int? ?? 0).clamp(0, 4);
    photo = restored['photo'] ?? photo;
    boostOnPublish = restored['boostOnPublish'] ?? false;
    if (restored['localPhotos'] is List) {
      localPhotos = (restored['localPhotos'] as List)
          .cast<String>()
          .map(
            (id) =>
                widget.state.ownPhoto(id) ??
                widget.existing?.localPhotos
                    .where((p) => p.id == id)
                    .firstOrNull,
          )
          .whereType<LocalPhoto>()
          .toList();
    }
    district = restored['district'] ?? district;
    type = restored['type'] ?? type;
    if (widget.existing != null) {
      amenities
        ..clear()
        ..addAll(widget.existing!.amenities);
    }
    if (restored['amenities'] != null) {
      amenities
        ..clear()
        ..addAll((restored['amenities'] as List).cast<String>());
    }
    saveDraft();
  }

  @override
  void dispose() {
    for (final c in [
      floor,
      latitude,
      longitude,
      title,
      price,
      deposit,
      area,
      address,
      description,
      electricity,
      water,
      internetFee,
      parkingFee,
      serviceFee,
      fees,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Room get draft {
    final parsedPrice = int.tryParse(price.text) ?? 0;
    final parsedDeposit = int.tryParse(deposit.text);
    return Room(
      id: widget.existing?.id ?? newId,
      title: title.text.trim(),
      floor: int.tryParse(floor.text) ?? 3,
      images: photo
          ? (widget.existing?.images.isNotEmpty ?? false)
                ? widget.existing!.images
                : const [PhotoKind.room]
          : const [],
      localPhotos: [...localPhotos],
      latitude: double.tryParse(latitude.text.trim()),
      longitude: double.tryParse(longitude.text.trim()),
      district: district,
      price: parsedPrice,
      deposit: parsedDeposit != null && parsedDeposit > 0
          ? parsedDeposit
          : parsedPrice,
      area: int.tryParse(area.text) ?? 20,
      type: type,
      amenities: amenities.toList(),
      address: address.text.trim(),
      description: description.text.trim(),
      electricity: electricity.text.trim(),
      water: water.text.trim(),
      internetFee: internetFee.text.trim(),
      parkingFee: parkingFee.text.trim(),
      serviceFee: serviceFee.text.trim(),
      otherFees: fees.text.trim(),
      isBoosted: boostOnPublish || (widget.existing?.isBoosted ?? false),
      expiresAt:
          widget.existing?.expiresAt ??
          DateTime.now().add(const Duration(days: 30)),
    );
  }

  static const _goongSuggestions = [
    (
      label: '268 Lý Thường Kiệt, P.14, Quận 10',
      district: 'Quận 10',
      lat: '10.7721',
      lng: '106.6579',
    ),
    (
      label: '123 Nguyễn Tri Phương, P.8, Quận 10',
      district: 'Quận 10',
      lat: '10.7626',
      lng: '106.6697',
    ),
    (
      label: '196 Pasteur, P. Võ Thị Sáu, Quận 3',
      district: 'Quận 3',
      lat: '10.7825',
      lng: '106.6901',
    ),
    (
      label: '42 Xuân Thủy, Thảo Điền, Thủ Đức',
      district: 'Thủ Đức',
      lat: '10.8035',
      lng: '106.7328',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final boostsLeft =
        widget.state.store.profiles[widget.state.userId]?.boosts ?? 0;
    return BasicPage(
      title: widget.existing == null ? 'Đăng phòng mới' : 'Sửa phòng',
      bottom: Row(
        children: [
          if (step > 0) ...[
            Expanded(
              child: PrimaryButton(
                'Quay lại',
                outline: true,
                onTap: submitting || pickingPhotos
                    ? null
                    : () {
                        setState(() => step--);
                        saveDraft();
                      },
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: PrimaryButton(
              step == 4 ? 'Gửi tin chờ duyệt' : 'Tiếp tục',
              busy: submitting,
              onTap: submitting || pickingPhotos
                  ? null
                  : () async {
                      if (step == 0 || step == 1 || step == 3) {
                        if (!form.currentState!.validate()) {
                          return;
                        }
                      }
                      if ((step == 2 || step == 4) &&
                          !photo &&
                          localPhotos.isEmpty) {
                        message(context, 'Hãy thêm ít nhất một ảnh phòng.');
                        return;
                      }
                      if (step < 4) {
                        setState(() => step++);
                        saveDraft();
                        return;
                      }
                      final room = draft;
                      setState(() {
                        submitting = true;
                        submitError = null;
                      });
                      try {
                        await widget.state.workflows.run('post-${room.id}', () {
                          if (boostOnPublish && boostsLeft > 0) {
                            final p = widget
                                .state
                                .store
                                .profiles[widget.state.userId]!;
                            p.boosts--;
                            p.boostedAt = DateTime.now();
                          }
                          if (widget.existing == null) {
                            widget.state.addRoom(room);
                          } else {
                            widget.state.replaceRoom(room);
                          }
                          widget.state.drafts.remove(draftKey);
                        }, role: UserRole.landlord);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => submitError = e.toString());
                        }
                      } finally {
                        if (mounted) {
                          setState(() => submitting = false);
                        }
                      }
                    },
            ),
          ),
        ],
      ),
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (submitError != null)
              Text(submitError!, style: PT.body(14, PT.error)),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: PT.card(color: PT.mint, radius: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bước ${step + 1}/5 • ${['Thông tin', 'Giá & phí', 'Hình ảnh', 'Vị trí', 'Xem trước'][step]}',
                    style: PT.body(13, PT.green).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (step + 1) / 5,
                      minHeight: 7,
                      color: PT.green,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < 5; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: i == step
                                ? PT.green
                                : i < step
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${i + 1}. ${['Thông tin', 'Giá & phí', 'Hình ảnh', 'Vị trí', 'Xem trước'][i]}',
                            style: PT.body(
                              11,
                              i == step
                                  ? Colors.white
                                  : i < step
                                  ? PT.green
                                  : PT.muted,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (step == 0) ...[
              TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Tiêu đề phòng'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Nhập tiêu đề phòng' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: floor,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tầng'),
                validator: (v) => (int.tryParse(v ?? '') ?? -1) < 0
                    ? 'Nhập tầng hợp lệ'
                    : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: area,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Diện tích (m²)'),
                validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                    ? 'Nhập diện tích hợp lệ'
                    : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Loại phòng'),
                items: [
                  'Studio',
                  'Phòng trọ',
                  'Căn hộ mini',
                ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (s) {
                  type = s!;
                  saveDraft();
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
              const SizedBox(height: 20),
              Text('Tiện nghi', style: PT.title(21)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 8,
                children: [
                  'Có nội thất',
                  'Wifi riêng',
                  'Máy lạnh',
                  'Bếp riêng',
                  'Ban công',
                  'Thang máy',
                  'Chỗ để xe',
                  'An ninh 24/7',
                  'Giờ giấc tự do',
                ]
                    .map(
                      (a) => FilterChip(
                        label: Text(a),
                        selected: amenities.contains(a),
                        onSelected: (v) => setState(() {
                          if (v) {
                            amenities.add(a);
                          } else {
                            amenities.remove(a);
                          }
                          saveDraft();
                        }),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (step == 1) ...[
              TextFormField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tiền thuê (đ/tháng)',
                ),
                validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                    ? 'Nhập giá thuê hợp lệ'
                    : null,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: electricity,
                decoration: const InputDecoration(
                  labelText: 'Điện (đ/kWh)',
                  hintText: '3.500',
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: water,
                decoration: const InputDecoration(
                  labelText: 'Nước (đ/người)',
                  hintText: '100.000',
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: fees,
                decoration: const InputDecoration(
                  labelText: 'Phí khác',
                  hintText: 'Wifi, gửi xe, đặt cọc...',
                ),
              ),
              const SizedBox(height: 18),
              Text('Chi tiết biểu phí & Tiền cọc', style: PT.title(19)),
              const SizedBox(height: 12),
              TextField(
                controller: deposit,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tiền đặt cọc (đ)',
                  hintText: 'Mặc định 1 tháng tiền phòng',
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: internetFee,
                decoration: const InputDecoration(
                  labelText: 'Phí Internet / Wifi',
                  hintText: 'Miễn phí hoặc 100.000đ/phòng',
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: parkingFee,
                decoration: const InputDecoration(
                  labelText: 'Phí gửi xe',
                  hintText: 'Miễn phí hoặc 120.000đ/xe',
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: serviceFee,
                decoration: const InputDecoration(
                  labelText: 'Phí rác & vệ sinh chung',
                  hintText: '50.000đ/phòng',
                ),
              ),
            ],
            if (step == 2) ...[
              Text('Thêm hình ảnh phòng', style: PT.title(25)),
              const SizedBox(height: 14),
              if (localPhotos.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final picture in localPhotos)
                      SizedBox(
                        width: 110,
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: LocalPhotoView(photo: picture, height: 90),
                            ),
                            IconButton(
                              tooltip: 'Xóa ảnh ${picture.name}',
                              icon: const Icon(LucideIcons.trash2),
                              onPressed: submitting
                                  ? null
                                  : () {
                                      setState(
                                        () => localPhotos.remove(picture),
                                      );
                                      saveDraft();
                                    },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              PrimaryButton(
                'Chọn ảnh phòng từ thiết bị',
                outline: true,
                busy: pickingPhotos,
                onTap: pickingPhotos || submitting
                    ? null
                    : () async {
                        final camera = await choosePhotoSource(context);
                        if (camera == null || !mounted) return;
                        setState(() {
                          pickingPhotos = true;
                          submitError = null;
                        });
                        try {
                          final photos = await widget.state.pickMedia(
                            multiple: !camera,
                            camera: camera,
                          );
                          if (!mounted) return;
                          if (localPhotos.length + photos.length > 8) {
                            throw const MediaFailure(
                              'Một tin phòng có tối đa 8 ảnh từ thiết bị.',
                            );
                          }
                          setState(() => localPhotos.addAll(photos));
                          saveDraft();
                        } on MediaFailure catch (e) {
                          if (mounted) setState(() => submitError = e.message);
                        } finally {
                          if (mounted) setState(() => pickingPhotos = false);
                        }
                      },
              ),
              const SizedBox(height: 12),
              if (photo)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: const ReferencePhoto(height: 220),
                ),
              const SizedBox(height: 18),
              PrimaryButton(
                photo ? 'Thay ảnh mẫu' : 'Chọn ảnh mẫu',
                outline: true,
                icon: LucideIcons.imagePlus,
                onTap: () {
                  setState(() => photo = true);
                  saveDraft();
                },
              ),
              if (photo)
                TextButton(
                  onPressed: () {
                    setState(() => photo = false);
                    saveDraft();
                  },
                  child: const Text('Xóa ảnh phòng'),
                ),
              const SizedBox(height: 15),
              Text(
                'Ảnh từ thiết bị được giữ trong lần chạy này, chưa tải lên máy chủ. Có thể chọn ảnh mẫu để thử nhanh.',
                style: PT.body(13, PT.muted),
              ),
            ],
            if (step == 3) ...[
              TextFormField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Nhập địa chỉ' : null,
              ),
              const SizedBox(height: 12),
              Text('Gợi ý địa chỉ Goong Maps:', style: PT.body(13, PT.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _goongSuggestions
                    .map(
                      (s) => ActionChip(
                        avatar: const Icon(
                          LucideIcons.mapPin,
                          size: 14,
                          color: PT.green,
                        ),
                        label: Text(
                          s.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () {
                          setState(() {
                            address.text = s.label;
                            district = s.district;
                            latitude.text = s.lat;
                            longitude.text = s.lng;
                          });
                          saveDraft();
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: district,
                decoration: const InputDecoration(labelText: 'Khu vực'),
                items: [
                  'Quận 10',
                  'Quận 3',
                  'Thủ Đức',
                ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (s) {
                  district = s!;
                  saveDraft();
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: latitude,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Vĩ độ (không bắt buộc)',
                ),
                validator: (value) {
                  final raw = value?.trim() ?? '';
                  if (raw.isEmpty) {
                    return longitude.text.trim().isEmpty
                        ? null
                        : 'Nhập đủ cả vĩ độ và kinh độ.';
                  }
                  final lat = double.tryParse(raw);
                  return lat == null || !lat.isFinite || lat.abs() > 90
                      ? 'Vĩ độ phải từ -90 đến 90.'
                      : null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: longitude,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Kinh độ (không bắt buộc)',
                ),
                validator: (value) {
                  final raw = value?.trim() ?? '';
                  if (raw.isEmpty) {
                    return latitude.text.trim().isEmpty
                        ? null
                        : 'Nhập đủ cả vĩ độ và kinh độ.';
                  }
                  final lng = double.tryParse(raw);
                  return lng == null || !lng.isFinite || lng.abs() > 180
                      ? 'Kinh độ phải từ -180 đến 180.'
                      : null;
                },
              ),
              const SizedBox(height: 15),
              const Text(
                'Điền tọa độ chính xác để mở chỉ đường; để trống nếu chưa có vị trí. Bản đồ dưới đây là minh họa.',
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: const CustomPaint(
                    painter: StreetPainter(),
                    child: Center(
                      child: Icon(LucideIcons.mapPin, size: 40, color: PT.green),
                    ),
                  ),
                ),
              ),
            ],
            if (step == 4) ...[
              RoomCard(room: draft, saved: false, onSave: () {}, onInfo: () {}),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: PT.card(color: PT.mint),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tóm tắt chi phí & Tùy chọn đăng', style: PT.title(18)),
                    const SizedBox(height: 8),
                    Text('Tiền đặt cọc: ${draft.depositLabel}'),
                    Text(
                      'Điện: ${draft.electricity} • Nước: ${draft.water}',
                      style: PT.body(13, PT.muted),
                    ),
                    Text(
                      'Internet: ${draft.internetFee} • Gửi xe: ${draft.parkingFee} • Dịch vụ: ${draft.serviceFee}',
                      style: PT.body(13, PT.muted),
                    ),
                    const Divider(height: 20),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Đẩy tin nổi bật VIP ngay sau khi đăng'),
                      subtitle: Text(
                        boostsLeft > 0
                            ? 'Sử dụng 1 lượt Đẩy tin (Hiện có $boostsLeft lượt)'
                            : 'Chưa có lượt Đẩy tin khả dụng',
                      ),
                      value: boostOnPublish && boostsLeft > 0,
                      onChanged: boostsLeft > 0
                          ? (v) {
                              setState(() => boostOnPublish = v);
                              saveDraft();
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LandlordQRScreen extends StatefulWidget {
  final AppState state;
  const LandlordQRScreen({super.key, required this.state});
  @override
  State<LandlordQRScreen> createState() => _LandlordQRScreenState();
}

class _LandlordQRScreenState extends State<LandlordQRScreen> {
  String? selectedId;
  bool busy = false;
  String? error;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, _) {
      final rentals = widget.state.rentals;
      final selected =
          rentals.where((r) => r.id == selectedId).firstOrNull ??
          rentals.firstOrNull;
      if (selected == null) {
        return const BasicPage(
          title: 'Mã nhận phòng',
          child: EmptyState(
            'Chưa có hợp đồng',
            'Mã nhận phòng được cấp cho từng hợp đồng của bạn.',
          ),
        );
      }
      return BasicPage(
        title: 'Mã nhận phòng',
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<String>(
              initialValue: selected.id,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Hợp đồng / phòng'),
              items: rentals
                  .map(
                    (r) => DropdownMenuItem(
                      value: r.id,
                      child: Text(
                        r.room.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (id) => setState(() => selectedId = id),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: PT.card(radius: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Pill(
                        selected.checkedIn
                            ? 'Đã nhận phòng'
                            : 'Chờ nhận phòng',
                        color: PT.green,
                      ),
                      Text(
                        'HĐ: ${selected.id}',
                        style: PT.body(12, PT.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(selected.room.title, style: PT.title(23)),
                  const SizedBox(height: 16),
                  if (!selected.checkedIn) ...[
                    RepaintBoundary(
                      child: Container(
                        height: 230,
                        decoration: BoxDecoration(
                          color: PT.mint,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: PT.green.withValues(alpha: 0.22),
                          ),
                        ),
                        alignment: Alignment.center,
                        child:
                            selected.codeExpiresAt?.isBefore(DateTime.now()) ??
                                false
                            ? const Text('Mã đã hết hạn. Hãy tạo mã mới.')
                            : QrImageView(
                                data: selected.code,
                                size: 204,
                                backgroundColor: Colors.white,
                                semanticsLabel:
                                    'QR nhận phòng hợp đồng ${selected.id}',
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: PT.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        selected.code,
                        style: PT.title(22).copyWith(letterSpacing: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (selected.codeExpiresAt != null)
                      Text(
                        '${selected.codeExpiresAt!.isBefore(DateTime.now()) ? 'Mã đã hết hạn' : 'Hạn sử dụng'}: ${selected.codeExpiresAt!.toString().substring(0, 16)}',
                        style: PT.body(
                          13,
                          selected.codeExpiresAt!.isBefore(DateTime.now())
                              ? PT.error
                              : PT.muted,
                        ),
                      ),
                    if (error != null)
                      Text(error!, style: PT.body(14, PT.error)),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      'Sao chép mã',
                      outline: true,
                      icon: LucideIcons.copy,
                      onTap: busy
                          ? null
                          : () async {
                              try {
                                await Clipboard.setData(
                                  ClipboardData(text: selected.code),
                                );
                                if (context.mounted) {
                                  message(
                                    context,
                                    'Đã sao chép mã nhận phòng.',
                                  );
                                }
                              } catch (_) {
                                if (mounted) {
                                  setState(
                                    () => error =
                                        'Chưa sao chép được. Hãy chọn và sao chép mã thủ công.',
                                  );
                                }
                              }
                            },
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      'Tạo mã mới (24 giờ)',
                      icon: LucideIcons.refreshCw,
                      busy: busy,
                      onTap: busy
                          ? null
                          : () async {
                              setState(() {
                                busy = true;
                                error = null;
                              });
                              try {
                                await widget.state.workflows.refreshCode(
                                  selected.id,
                                );
                              } catch (e) {
                                if (mounted) {
                                  setState(() => error = e.toString());
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => busy = false);
                                }
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'QR chứa mã của hợp đồng ${selected.id}; có thể quét bằng camera. Xác nhận nhận phòng vẫn được kiểm tra trong kho demo.',
                      style: PT.body(13, PT.muted),
                    ),
                  ] else
                    Text(
                      'Mã đã sử dụng và không thể nhận phòng lần nữa.',
                      style: PT.body(14, PT.muted),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
