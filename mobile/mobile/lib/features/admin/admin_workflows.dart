import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../core/flow_page.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../domain/workflow_models.dart';
import '../account/account_screens.dart';
import '../rooms/room_screens.dart';

class AdminScreen extends StatefulWidget {
  final AppState state;
  const AdminScreen({super.key, required this.state});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int analyticsTab = 0;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final paidOrders = state.store.orders
            .where((o) => o.status == 'Thành công')
            .toList();
        final orderRevenue = paidOrders.fold<int>(0, (s, o) => s + o.amount);
        final totalRevenue = 14850000 + orderRevenue;
        final vipCount = state.store.profiles.values
            .where((p) => p.package != 'Miễn phí')
            .length;
        final boostedRooms = state.rooms.where((r) => r.isBoosted).length;
        final feedbacks = state.store.systemFeedbacks;
        final avgSatisfaction = feedbacks.isEmpty
            ? '4.8'
            : (feedbacks.map((f) => f.rating).reduce((a, b) => a + b) /
                      feedbacks.length)
                  .toStringAsFixed(1);

        return LayoutBuilder(
          builder: (context, viewport) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final lockScroll = viewport.maxHeight >= 520 && textScale <= 1.25;
            final minContentHeight = lockScroll
                ? math.max(0.0, viewport.maxHeight - 8)
                : 0.0;
            final showExtraGrowth =
                lockScroll && viewport.maxHeight >= 680 && analyticsTab == 0;
            return ListView(
              physics: lockScroll
                  ? const NeverScrollableScrollPhysics()
                  : const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minContentHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Header(
                            admin: true,
                            unreadNotifications: state.unreadNotifications,
                            onMap: () => openPage(
                              context,
                              AdminUsersScreen(state: state),
                            ),
                            onNotifications: () => openPage(
                              context,
                              NotificationsScreen(state: state),
                            ),
                          ),
                          const PageHeading(
                            'Quản trị viên',
                            'Tổng quan hệ thống Phòng Trọ Xanh',
                          ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [PT.deep, Color(0xFF0A4F48)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18073B3C),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Pill(
                            'Trung tâm điều hành Proptech',
                            dense: true,
                            color: Colors.white,
                            bg: Colors.white.withValues(alpha: 0.16),
                          ),
                          const Pill(
                            'Hệ thống ổn định 99.9%',
                            dense: true,
                            color: PT.deep,
                            bg: Color(0xFFA7F3D0),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Doanh thu hệ thống',
                                style: PT.body(
                                  10,
                                  Colors.white.withValues(alpha: 0.78),
                                ),
                              ),
                              Text(
                                '${(totalRevenue / 1000000).toStringAsFixed(2)}tr đ',
                                style: PT
                                    .title(17)
                                    .copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thành viên VIP',
                                style: PT.body(
                                  10,
                                  Colors.white.withValues(alpha: 0.78),
                                ),
                              ),
                              Text(
                                '$vipCount tài khoản',
                                style: PT
                                    .title(14)
                                    .copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tin đẩy nổi bật',
                                style: PT.body(
                                  10,
                                  Colors.white.withValues(alpha: 0.78),
                                ),
                              ),
                              Text(
                                '$boostedRooms phòng',
                                style: PT
                                    .title(14)
                                    .copyWith(color: const Color(0xFFFDE68A)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                LayoutBuilder(
                  builder: (context, c) => Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final stat in [
                        (
                          'Người dùng',
                          state.store.profiles.length,
                          '+12% tháng này',
                          LucideIcons.users,
                          PT.green,
                          PT.mint,
                        ),
                        (
                          'Phòng trọ',
                          state.rooms.length,
                          '${state.rooms.where((r) => r.status == RoomStatus.available).length} đang mở',
                          LucideIcons.building2,
                          const Color(0xFF0799DE),
                          const Color(0xFFEEF8FF),
                        ),
                        (
                          'Báo cáo chờ xử lý',
                          state.store.reports
                              .where((r) => r.status == 'Chờ xử lý')
                              .length,
                          'Ưu tiên kiểm duyệt',
                          LucideIcons.flag,
                          PT.error,
                          const Color(0xFFFEF2F2),
                        ),
                        (
                          'CCCD chờ duyệt',
                          state.store.kyc
                              .where((k) => k.status == 'Chờ duyệt')
                              .length,
                          'Hàng đợi eKYC',
                          LucideIcons.idCard,
                          PT.amber,
                          const Color(0xFFFFF8ED),
                        ),
                      ])
                        SizedBox(
                          width: (c.maxWidth - 6) / 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: PT.card(radius: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: stat.$6,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    stat.$4,
                                    size: 14,
                                    color: stat.$5,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${stat.$2}',
                                            style: PT
                                                .title(16)
                                                .copyWith(color: stat.$5),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              stat.$1,
                                              style: PT.title(11),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        stat.$3,
                                        style: PT.body(10, PT.muted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: PT.grey,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Expanded(
                          child: Material(
                            color: analyticsTab == i
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(9),
                              onTap: () => setState(() => analyticsTab = i),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text(
                                  const [
                                    'Điều hành',
                                    'Người thuê & Ghép đôi',
                                    'Chủ trọ & Nguồn cung',
                                  ][i],
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PT
                                      .body(
                                        11,
                                        analyticsTab == i ? PT.green : PT.muted,
                                      )
                                      .copyWith(
                                        fontWeight: analyticsTab == i
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                if (analyticsTab == 0)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final allItems = [
                        MenuRow(
                          spacious: false,
                          framed: false,
                          icon: LucideIcons.fileCheck,
                          title: 'Duyệt CCCD',
                          subtitle: 'Hồ sơ theo ID',
                          onTap: () => openPage(
                            context,
                            AdminQueueScreen(state: state),
                          ),
                        ),
                        MenuRow(
                          spacious: false,
                          framed: false,
                          icon: LucideIcons.house,
                          title: 'Duyệt tin phòng',
                          subtitle:
                              '${state.rooms.where((r) => r.status == RoomStatus.pending).length} tin chờ duyệt',
                          onTap: () => openPage(
                            context,
                            AdminRoomsScreen(state: state),
                          ),
                        ),
                        MenuRow(
                          spacious: false,
                          framed: false,
                          icon: LucideIcons.flag,
                          title: 'Báo cáo vi phạm',
                          subtitle: 'Nội dung & xử lý',
                          onTap: () => openPage(
                            context,
                            AdminReportsScreen(state: state),
                          ),
                        ),
                        MenuRow(
                          spacious: false,
                          framed: false,
                          icon: LucideIcons.users,
                          title: 'Quản lý người dùng',
                          subtitle: 'Khóa / mở khóa',
                          onTap: () => openPage(
                            context,
                            AdminUsersScreen(state: state),
                          ),
                        ),
                        MenuRow(
                          spacious: false,
                          framed: false,
                          icon: LucideIcons.package,
                          title: 'Quản lý gói dịch vụ',
                          subtitle: '${state.store.plans.length} gói VIP',
                          onTap: () => openPage(
                            context,
                            AdminPackagesScreen(state: state),
                          ),
                        ),
                        MenuRow(
                          spacious: false,
                          framed: false,
                          icon: LucideIcons.scale,
                          title: 'Khiếu nại & Nhật ký hệ thống',
                          subtitle: 'Tranh chấp & log',
                          onTap: () => openPage(
                            context,
                            AdminDisputesScreen(state: state),
                          ),
                        ),
                      ];
                      final twoCol =
                          constraints.maxWidth >= 320 &&
                          MediaQuery.textScalerOf(context).scale(12) <= 15;
                      if (!twoCol) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: PT.card(),
                          child: Column(children: allItems),
                        );
                      }
                      final cellWidth = (constraints.maxWidth - 6) / 2;
                      return Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: [
                          for (var i = 0; i < allItems.length; i++)
                            Container(
                              width: cellWidth,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 1,
                              ),
                              decoration: PT.card(radius: 11),
                              child: allItems[i],
                            ),
                        ],
                      );
                    },
                  ),
                if (analyticsTab == 1 || showExtraGrowth) ...[
                  if (showExtraGrowth) const SizedBox(height: 6),
                  RepaintBoundary(
                    child: flowCard('Tăng trưởng hệ thống 6 tháng', [
                      Container(
                        height: 62,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: PT.grey.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final m in const [
                              ('T5', 0.45, 0.35),
                              ('T6', 0.55, 0.48),
                              ('T7', 0.64, 0.52),
                              ('T8', 0.76, 0.68),
                              ('T9', 0.88, 0.78),
                              ('T10', 1.0, 0.92),
                            ])
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: FractionallySizedBox(
                                                heightFactor: m.$2,
                                                child: Container(
                                                  width: 7,
                                                  decoration: BoxDecoration(
                                                    color: PT.green,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          3,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            Flexible(
                                              child: FractionallySizedBox(
                                                heightFactor: m.$3,
                                                child: Container(
                                                  width: 7,
                                                  decoration: BoxDecoration(
                                                    color: PT.amber,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          3,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(m.$1, style: PT.body(10, PT.muted)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'TrustScore TB: 88/100 • Ghép đôi: 87% • eKYC: 92%',
                        style: PT
                            .body(11, PT.green)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
                ],
                if (analyticsTab == 2) ...[
                  flowCard(
                    'Nguồn cung & Đánh giá ($avgSatisfaction/5)',
                    [
                      Text(
                        'Tỷ lệ lấp đầy toàn hệ thống: 84% (Q.10 42% • Thủ Đức 35%)',
                        style: PT.body(11, PT.green).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      for (final fb in feedbacks.take(2))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: PT.mint.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${fb.authorName}: ${fb.comment}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: PT.body(11),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => state.workflows
                                      .deleteSystemFeedback(fb.id),
                                  child: Text(
                                    'Xóa phản hồi',
                                    style: PT.body(10, PT.error).copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: PrimaryButton(
                          'Đăng xuất',
                          outline: true,
                          onTap: () => AppScope.maybeOf(context)?.logout(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class AdminQueueScreen extends StatefulWidget {
  final AppState state;
  const AdminQueueScreen({super.key, required this.state});
  @override
  State<AdminQueueScreen> createState() => _AdminQueueScreenState();
}

class _AdminQueueScreenState extends State<AdminQueueScreen> {
  String filter = 'Chờ duyệt';
  String roleFilter = 'Tất cả vai trò';
  String query = '';

  @override
  Widget build(BuildContext context) => FlowPage(
    state: widget.state,
    title: 'Duyệt CCCD',
    content: (ctx, f) {
      final s = widget.state;
      final items = s.store.kyc.where((k) {
        final statusOk = filter == 'Tất cả' || k.status == filter;
        final userRole = s.store.profiles[k.userId]?.user.role;
        final roleOk =
            roleFilter == 'Tất cả vai trò' ||
            (roleFilter == 'Người thuê' && userRole == UserRole.tenant) ||
            (roleFilter == 'Chủ trọ' && userRole == UserRole.landlord);
        final name = s.store.workspaceById(k.userId).fullName.toLowerCase();
        final queryOk =
            query.isEmpty ||
            name.contains(query.toLowerCase()) ||
            k.number.contains(query) ||
            k.id.toLowerCase().contains(query.toLowerCase());
        return statusOk && roleOk && queryOk;
      }).toList();
      return [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Tìm theo tên, số CCCD hoặc mã hồ sơ',
            prefixIcon: Icon(LucideIcons.search),
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Chờ duyệt', 'Đã xác minh', 'Đã từ chối', 'Tất cả']
              .map(
                (v) => ChoiceChip(
                  label: Text(v),
                  selected: v == filter,
                  onSelected: (_) => setState(() => filter = v),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Tất cả vai trò', 'Người thuê', 'Chủ trọ']
              .map(
                (v) => ChoiceChip(
                  label: Text(v),
                  selected: v == roleFilter,
                  onSelected: (_) => setState(() => roleFilter = v),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const EmptyState(
            'Không có hồ sơ trong mục này',
            'Hồ sơ gửi từ người thuê hoặc chủ trọ sẽ xuất hiện tại đây.',
          ),
        for (final k in items.reversed)
          MenuRow(
            icon: LucideIcons.fileCheck,
            title: s.store.workspaceById(k.userId).fullName,
            subtitle: '${k.id} • CCCD ${k.number} • ${k.status}',
            onTap: () => openPage(
              ctx,
              AdminDecisionScreen(state: s, kind: 'kyc', id: k.id),
            ),
          ),
      ];
    },
  );
}

class AdminReportsScreen extends StatefulWidget {
  final AppState? state;
  const AdminReportsScreen({super.key, this.state});
  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String filter = 'Chờ xử lý';
  String severityFilter = 'Mọi mức độ';

  @override
  Widget build(BuildContext context) {
    final s = widget.state ?? AppScope.maybeOf(context)!.state;
    return FlowPage(
      state: s,
      title: 'Báo cáo vi phạm',
      content: (ctx, f) {
        final items = s.store.reports.where((r) {
          final statusOk = filter == 'Tất cả' || r.status == filter;
          final sevOk =
              severityFilter == 'Mọi mức độ' || r.severity == severityFilter;
          return statusOk && sevOk;
        }).toList();
        return [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Chờ xử lý', 'Đã xử lý', 'Đã bỏ qua', 'Tất cả']
                .map(
                  (v) => ChoiceChip(
                    label: Text(v),
                    selected: v == filter,
                    onSelected: (_) => setState(() => filter = v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Mọi mức độ', 'Nghiêm trọng', 'Trung bình', 'Thấp']
                .map(
                  (v) => ChoiceChip(
                    label: Text(v),
                    selected: v == severityFilter,
                    onSelected: (_) => setState(() => severityFilter = v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const EmptyState(
              'Không có báo cáo trong mục này',
              'Báo cáo từ app dùng chung hàng đợi này.',
            ),
          for (final r in items.reversed)
            MenuRow(
              icon: LucideIcons.flag,
              title: r.reason,
              subtitle:
                  '${r.id} • [${r.severity}] • ${r.targetType} ${r.targetId} • ${r.status}',
              onTap: () => openPage(
                ctx,
                AdminDecisionScreen(state: s, kind: 'report', id: r.id),
              ),
            ),
        ];
      },
    );
  }
}

class AdminUsersScreen extends StatefulWidget {
  final AppState? state;
  const AdminUsersScreen({super.key, this.state});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String query = '', filter = 'Tất cả', roleFilter = 'Mọi vai trò';
  @override
  Widget build(BuildContext context) {
    final s = widget.state ?? AppScope.maybeOf(context)!.state;
    return FlowPage(
      state: s,
      title: 'Người dùng',
      content: (ctx, f) {
        final items = s.store.profiles.values.where((p) {
          if (s.store.deleted.contains(p.user.id)) return false;
          final textMatch =
              '${s.store.workspace(p.user).fullName} ${p.user.email} ${p.user.phone}'
                  .toLowerCase()
                  .contains(query.toLowerCase());
          final isBlocked = s.store.blocked.contains(p.user.id);
          final statusMatch = switch (filter) {
            'Đã khóa' => isBlocked,
            'Hoạt động' => !isBlocked,
            'Đã cảnh cáo' => p.warned,
            _ => true,
          };
          final roleMatch =
              roleFilter == 'Mọi vai trò' || p.user.role.name == roleFilter;
          return textMatch && statusMatch && roleMatch;
        }).toList();
        return [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Tìm tên, email, số điện thoại',
              prefixIcon: Icon(LucideIcons.search),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Tất cả', 'Hoạt động', 'Đã khóa', 'Đã cảnh cáo']
                .map(
                  (v) => ChoiceChip(
                    label: Text(v),
                    selected: v == filter,
                    onSelected: (_) => setState(() => filter = v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('Mọi vai trò', 'Mọi vai trò'),
              ('tenant', 'Người thuê'),
              ('landlord', 'Chủ trọ'),
              ('admin', 'Quản trị'),
            ]
                .map(
                  (v) => ChoiceChip(
                    label: Text(v.$2),
                    selected: v.$1 == roleFilter,
                    onSelected: (_) => setState(() => roleFilter = v.$1),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const EmptyState(
              'Không có người dùng phù hợp',
              'Thay đổi từ khóa hoặc trạng thái.',
            ),
          for (final p in items)
            MenuRow(
              icon: LucideIcons.user,
              title: s.store.workspace(p.user).fullName,
              subtitle:
                  '${p.user.email} • ${p.user.role.name} • Trust ${p.trustScore} • ${s.store.blocked.contains(p.user.id) ? 'Đã khóa' : p.warned ? 'Đã cảnh cáo' : 'Hoạt động'}',
              onTap: () => openPage(
                ctx,
                AdminDecisionScreen(state: s, kind: 'user', id: p.user.id),
              ),
            ),
        ];
      },
    );
  }
}

class AdminDecisionScreen extends StatefulWidget {
  final AppState state;
  final String kind, id;
  const AdminDecisionScreen({
    super.key,
    required this.state,
    required this.kind,
    required this.id,
  });
  @override
  State<AdminDecisionScreen> createState() => _AdminDecisionScreenState();
}

class _AdminDecisionScreenState extends State<AdminDecisionScreen> {
  final note = TextEditingController();
  String action = 'resolve';
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FlowPage(
    state: widget.state,
    title: 'Chi tiết ${widget.id}',
    content: (ctx, f) {
      final s = widget.state;
      if (widget.kind == 'kyc') {
        final k = s.store.kyc.where((k) => k.id == widget.id).firstOrNull;
        if (k == null) {
          return [
            const EmptyState(
              'Hồ sơ không tồn tại',
              'Quay lại danh sách để tải lại.',
            ),
          ];
        }
        return [
          flowCard(s.store.workspaceById(k.userId).fullName, [
            Text('${k.id} • ${k.status}'),
            Text('Số CCCD: ${k.number}'),
            if (k.note.isNotEmpty) Text(k.note),
            TextButton.icon(
              icon: const Icon(LucideIcons.zoomIn, size: 16),
              onPressed: () => showDialog<void>(
                context: ctx,
                builder: (d) => AlertDialog(
                  title: Text('Đối chiếu CCCD • ${k.number}'),
                  content: SizedBox(
                    width: 300,
                    height: 320,
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            VerificationDocument(
                              state: s,
                              userId: k.userId,
                              reference: k.front,
                              side: 'Mặt trước (Zoom)',
                            ),
                            const SizedBox(height: 12),
                            VerificationDocument(
                              state: s,
                              userId: k.userId,
                              reference: k.back,
                              side: 'Mặt sau (Zoom)',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(d),
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
              ),
              label: const Text('Phóng to đối chiếu ảnh CCCD'),
            ),
          ]),
          VerificationDocument(
            state: s,
            userId: k.userId,
            reference: k.front,
            side: 'Mặt trước',
          ),
          const SizedBox(height: 16),
          VerificationDocument(
            state: s,
            userId: k.userId,
            reference: k.back,
            side: 'Mặt sau',
          ),
          const SizedBox(height: 16),
          if (k.status == 'Chờ duyệt') ...[
            TextField(
              controller: note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú / lý do từ chối',
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              'Duyệt hồ sơ',
              busy: f.busy,
              onTap: f.busy
                  ? null
                  : () => f.perform(
                      () => s.workflows.decideKyc(k.id, true, note.text),
                    ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              'Từ chối hồ sơ',
              outline: true,
              onTap: f.busy
                  ? null
                  : () => f.perform(
                      () => s.workflows.decideKyc(k.id, false, note.text),
                    ),
            ),
          ],
        ];
      }
      if (widget.kind == 'report') {
        final r = s.store.reports.where((r) => r.id == widget.id).firstOrNull;
        if (r == null) {
          return [
            const EmptyState('Không tìm thấy báo cáo', 'Quay lại danh sách.'),
          ];
        }
        return [
          flowCard('${r.id} • ${r.status}', [
            Text(r.reason, style: PT.title(22)),
            const SizedBox(height: 6),
            Pill(
              'Mức độ: ${r.severity}',
              color: r.severity == 'Nghiêm trọng' ? PT.error : PT.amber,
            ),
            const SizedBox(height: 8),
            Text(r.details),
            Text('Đối tượng: ${r.targetType} ${r.targetId}'),
            Text('Người gửi: ${s.store.workspaceById(r.reporterId).fullName}'),
            if (r.evidence.isNotEmpty)
              Text('Bằng chứng: ${r.evidence.join(', ')}'),
            ...r.history.map(Text.new),
          ]),
          if (r.status == 'Chờ xử lý') ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: action,
              decoration: const InputDecoration(labelText: 'Hành động'),
              items: const [
                DropdownMenuItem(
                  value: 'resolve',
                  child: Text('Đánh dấu đã xử lý'),
                ),
                DropdownMenuItem(
                  value: 'warn',
                  child: Text('Cảnh báo / ghi nhận'),
                ),
                DropdownMenuItem(
                  value: 'remove_content',
                  child: Text('Ẩn tin phòng'),
                ),
                DropdownMenuItem(
                  value: 'ban',
                  child: Text('Khóa tài khoản đối tượng'),
                ),
                DropdownMenuItem(
                  value: 'dismiss',
                  child: Text('Bỏ qua báo cáo'),
                ),
              ],
              onChanged: (v) => setState(() => action = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú xử lý (bắt buộc)',
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              'Xác nhận xử lý',
              busy: f.busy,
              onTap: f.busy
                  ? null
                  : () async {
                      if (await confirmAction(
                        ctx,
                        'Xử lý ${r.id}?',
                        'Hành động được lưu vào lịch sử. Ẩn tin hoặc khóa tài khoản sẽ cập nhật dữ liệu demo tương ứng.',
                      )) {
                        await f.perform(
                          () => s.workflows.resolveReport(
                            r.id,
                            action,
                            note.text,
                          ),
                        );
                      }
                    },
            ),
          ],
        ];
      }
      final p = s.store.profiles[widget.id];
      if (p == null) {
        return [
          const EmptyState('Không tìm thấy tài khoản', 'Quay lại danh sách.'),
        ];
      }
      final blocked = s.store.blocked.contains(widget.id);
      final verified =
          s.store.workspace(p.user).verification == 'Đã xác minh';
      return [
        flowCard(s.store.workspace(p.user).fullName, [
          Text(p.user.email),
          Text(p.user.phone),
          Text('Vai trò: ${p.user.role.name}'),
          Text(blocked ? 'Đã khóa' : 'Hoạt động'),
          Text('Xác minh: ${s.store.workspace(p.user).verification}'),
          Text('TrustScore: ${p.trustScore}/100 • Gói: ${p.package}'),
          if (p.warned && p.warningNote.isNotEmpty)
            Text(
              'Cảnh cáo gần nhất: ${p.warningNote}',
              style: PT.body(13, PT.error),
            ),
        ]),
        if (p.user.id != s.userId) ...[
          TextField(
            controller: note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Lý do thay đổi trạng thái',
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            blocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
            busy: f.busy,
            onTap: f.busy
                ? null
                : () async {
                    if (await confirmAction(
                      ctx,
                      'Thay đổi trạng thái tài khoản?',
                      p.user.email,
                    )) {
                      await f.perform(
                        () => s.workflows.userStatus(
                          p.user.id,
                          !blocked,
                          note.text,
                        ),
                      );
                    }
                  },
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            'Cảnh cáo người dùng',
            outline: true,
            busy: f.busy,
            onTap: f.busy
                ? null
                : () => f.perform(
                    () => s.workflows.warnUser(
                      p.user.id,
                      note.text.trim().isEmpty
                          ? 'Nhắc nhở tuân thủ quy tắc cộng đồng'
                          : note.text,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            verified ? 'Thu hồi xác minh CCCD' : 'Cấp tích xanh xác minh',
            outline: true,
            busy: f.busy,
            onTap: f.busy
                ? null
                : () => f.perform(
                    () => s.workflows.toggleUserVerification(
                      p.user.id,
                      !verified,
                      note.text,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            'Đặt lại mật khẩu mặc định',
            outline: true,
            busy: f.busy,
            onTap: f.busy
                ? null
                : () => f.perform(
                    () => s.workflows.adminResetPassword(p.user.id),
                  ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            'Gửi thông báo trực tiếp',
            outline: true,
            busy: f.busy,
            onTap: f.busy
                ? null
                : () async {
                    final titleCtrl = TextEditingController(
                      text: 'Thông báo từ Quản trị viên',
                    );
                    final bodyCtrl = TextEditingController(
                      text: note.text.trim().isEmpty
                          ? 'Vui lòng cập nhật đầy đủ thông tin tài khoản.'
                          : note.text,
                    );
                    final send = await showDialog<bool>(
                      context: ctx,
                      builder: (d) => AlertDialog(
                        title: const Text('Gửi thông báo trực tiếp'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: titleCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Tiêu đề',
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: bodyCtrl,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Nội dung',
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(d, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(d, true),
                            child: const Text('Gửi'),
                          ),
                        ],
                      ),
                    );
                    if (send == true) {
                      await f.perform(
                        () => s.workflows.notifyUser(
                          p.user.id,
                          titleCtrl.text,
                          bodyCtrl.text,
                        ),
                      );
                    }
                  },
          ),
        ],
      ];
    },
  );
}

class AdminRoomsScreen extends StatefulWidget {
  final AppState state;
  const AdminRoomsScreen({super.key, required this.state});
  @override
  State<AdminRoomsScreen> createState() => _AdminRoomsScreenState();
}

class _AdminRoomsScreenState extends State<AdminRoomsScreen> {
  String filter = 'Chờ duyệt';

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return FlowPage(
      state: state,
      title: 'Duyệt tin phòng',
      content: (ctx, f) {
        final items = state.rooms.where((r) {
          if (filter == 'Chờ duyệt') return r.status == RoomStatus.pending;
          if (filter == 'Đang hiển thị') return r.status == RoomStatus.available;
          if (filter == 'Đã ẩn') return r.status == RoomStatus.hidden;
          return true;
        }).toList();

        return [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Chờ duyệt', 'Đang hiển thị', 'Đã ẩn', 'Tất cả']
                .map(
                  (v) => ChoiceChip(
                    label: Text(v),
                    selected: filter == v,
                    onSelected: (_) => setState(() => filter = v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const EmptyState(
              'Không có tin chờ duyệt',
              'Tin mới / tin sửa của chủ trọ sẽ xuất hiện ở đây.',
            ),
          for (final r in items)
            flowCard(r.title, [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Pill(
                    r.status.label,
                    dense: true,
                    color: r.status == RoomStatus.pending
                        ? PT.amber
                        : r.status == RoomStatus.hidden
                        ? PT.muted
                        : PT.green,
                  ),
                  Pill(
                    '${r.price}đ/tháng',
                    dense: true,
                    color: PT.green,
                  ),
                  Pill(
                    '${r.area}m² • Tầng ${r.floor}',
                    dense: true,
                    color: PT.green,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(r.address, style: PT.body(14, PT.deep)),
              const SizedBox(height: 4),
              Text(
                'Cọc: ${r.depositLabel} • Điện: ${r.electricity} • Nước: ${r.water}',
                style: PT.body(12, PT.muted),
              ),
              const SizedBox(height: 4),
              Text(
                'Chủ trọ: ${r.landlordName}',
                style: PT.body(13, PT.green).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(r.description, style: PT.body(13, PT.muted)),
              const SizedBox(height: 12),
              PrimaryButton(
                'Xem chi tiết tin',
                outline: true,
                icon: LucideIcons.externalLink,
                onTap: () =>
                    openPage(ctx, RoomDetailScreen(state: state, room: r)),
              ),
              const SizedBox(height: 10),
              if (r.status != RoomStatus.available)
                PrimaryButton(
                  'Duyệt tin phòng',
                  icon: LucideIcons.check,
                  busy: f.busy,
                  onTap: f.busy
                      ? null
                      : () => f.perform(
                          () => state.workflows.moderateRoom(r.id, true),
                        ),
                ),
              if (r.status != RoomStatus.hidden)
                TextButton(
                  onPressed: f.busy
                      ? null
                      : () => f.perform(
                          () => state.workflows.moderateRoom(r.id, false),
                        ),
                  child: const Text('Từ chối / ẩn tin'),
                ),
            ]),
        ];
      },
    );
  }
}

class AdminPackagesScreen extends StatefulWidget {
  final AppState state;
  const AdminPackagesScreen({super.key, required this.state});
  @override
  State<AdminPackagesScreen> createState() => _AdminPackagesScreenState();
}

class _AdminPackagesScreenState extends State<AdminPackagesScreen> {
  String roleFilter = 'Tất cả';

  Future<void> _openEditor(
    BuildContext ctx,
    FlowPageState f, [
    ServicePlan? existing,
  ]) async {
    final idCtrl = TextEditingController(
      text:
          existing?.id ??
          'plan-${DateTime.now().millisecondsSinceEpoch % 10000}',
    );
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final headlineCtrl = TextEditingController(
      text: existing?.description ?? '',
    );
    final monthlyCtrl = TextEditingController(
      text: '${existing?.monthly ?? 99000}',
    );
    final yearlyCtrl = TextEditingController(
      text: '${existing?.yearly ?? 990000}',
    );
    final featuresCtrl = TextEditingController(
      text: existing?.features.join(', ') ?? 'Ưu tiên hiển thị, Huy hiệu VIP',
    );
    UserRole selectedRole = (existing?.landlord ?? true)
        ? UserRole.landlord
        : UserRole.tenant;

    final saved = await showDialog<ServicePlan>(
      context: ctx,
      builder: (d) => StatefulBuilder(
        builder: (d, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Tạo gói dịch vụ' : 'Chỉnh sửa gói'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (existing == null)
                  TextField(
                    controller: idCtrl,
                    decoration: const InputDecoration(labelText: 'Mã gói (ID)'),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên gói cước'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<UserRole>(
                  isExpanded: true,
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Đối tượng áp dụng',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: UserRole.tenant,
                      child: Text('Người thuê'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.landlord,
                      child: Text('Chủ trọ'),
                    ),
                  ],
                  onChanged: (v) => setModalState(() => selectedRole = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: monthlyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giá tháng (VNĐ)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: yearlyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giá năm (VNĐ)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: headlineCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả ngắn / Quyền lợi chính',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: featuresCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Danh sách tính năng (cách nhau dấu phẩy)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                d,
                ServicePlan(
                  idCtrl.text.trim(),
                  nameCtrl.text.trim(),
                  int.tryParse(monthlyCtrl.text) ?? 99000,
                  headlineCtrl.text.trim().isEmpty
                      ? 'Quyền lợi nâng cao'
                      : headlineCtrl.text.trim(),
                  yearly: int.tryParse(yearlyCtrl.text) ?? 990000,
                  extraSwipes: existing?.extraSwipes ?? 0,
                  boosts: existing?.boosts ?? 5,
                  superMatches: existing?.superMatches ?? 0,
                  landlord: selectedRole == UserRole.landlord,
                  features: featuresCtrl.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                ),
              ),
              child: const Text('Lưu gói'),
            ),
          ],
        ),
      ),
    );
    if (saved != null) {
      await f.perform(() => widget.state.workflows.adminSavePlan(saved));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return FlowPage(
      state: s,
      title: 'Quản lý gói dịch vụ',
      content: (ctx, f) {
        final plans = s.store.plans.where((p) {
          if (roleFilter == 'Người thuê') return !p.landlord;
          if (roleFilter == 'Chủ trọ') return p.landlord;
          return true;
        }).toList();

        return [
          PrimaryButton(
            'Thêm gói dịch vụ mới',
            icon: LucideIcons.plus,
            busy: f.busy,
            onTap: f.busy ? null : () => _openEditor(ctx, f),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Tất cả', 'Người thuê', 'Chủ trọ']
                .map(
                  (v) => ChoiceChip(
                    label: Text(v),
                    selected: roleFilter == v,
                    onSelected: (_) => setState(() => roleFilter = v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          for (final plan in plans)
            flowCard('${plan.name} (${plan.id})', [
              Pill(
                plan.landlord ? 'Dành cho Chủ trọ' : 'Dành cho Người thuê',
                dense: true,
                color: PT.green,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PT.mint.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giá tháng: ${plan.monthly}đ${plan.yearly > 0 ? ' • Giá năm: ${plan.yearly}đ' : ''}',
                      style: PT.title(17).copyWith(color: PT.green),
                    ),
                    const SizedBox(height: 4),
                    Text(plan.description, style: PT.body(13, PT.deep)),
                  ],
                ),
              ),
              if (plan.features.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final ft in plan.features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            LucideIcons.circleCheck,
                            size: 14,
                            color: PT.green,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(ft, style: PT.body(13, PT.muted)),
                        ),
                      ],
                    ),
                  ),
              ],
              const Divider(height: 20, color: PT.line),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  TextButton.icon(
                    icon: const Icon(LucideIcons.pencil, size: 15),
                    onPressed: f.busy ? null : () => _openEditor(ctx, f, plan),
                    label: const Text('Chỉnh sửa'),
                  ),
                  TextButton.icon(
                    icon: const Icon(
                      LucideIcons.trash2,
                      size: 15,
                      color: PT.error,
                    ),
                    onPressed: f.busy
                        ? null
                        : () => f.perform(
                            () => s.workflows.adminDeletePlan(plan.id),
                          ),
                    label: Text('Xóa gói', style: PT.body(13, PT.error)),
                  ),
                ],
              ),
            ]),
        ];
      },
    );
  }
}

class AdminDisputesScreen extends StatefulWidget {
  final AppState state;
  const AdminDisputesScreen({super.key, required this.state});
  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return FlowPage(
      state: s,
      title: 'Khiếu nại & Nhật ký',
      content: (ctx, f) {
        final disputedReviews = s.store.reviewRecords
            .where((r) => r.disputeStatus != null)
            .toList();

        return [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < 3; i++)
                ChoiceChip(
                  label: Text(
                    [
                      'Khiếu nại đánh giá',
                      'Giao dịch gói cước',
                      'Nhật ký bảo mật',
                    ][i],
                  ),
                  selected: tab == i,
                  onSelected: (_) => setState(() => tab = i),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (tab == 0) ...[
            if (disputedReviews.isEmpty)
              const EmptyState(
                'Không có khiếu nại đánh giá',
                'Khi chủ trọ khiếu nại đánh giá không đúng sự thật, yêu cầu sẽ hiển thị tại đây.',
              ),
            for (final r in disputedReviews)
              flowCard('Đánh giá ${r.id} • ${r.rating}/5 sao', [
                Pill('Trạng thái: ${r.disputeStatus}', color: PT.amber),
                const SizedBox(height: 8),
                Text(
                  'Người viết: ${r.authorName} • Phòng: ${r.targetId}',
                  style: PT.body(13, PT.muted),
                ),
                const SizedBox(height: 4),
                Text('Nội dung đánh giá: ${r.comment}', style: PT.body(14)),
                if (r.disputeReason != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: PT.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Lý do chủ trọ khiếu nại: ${r.disputeReason}',
                      style: PT.body(13, PT.error),
                    ),
                  ),
                ],
                if (r.disputeResolutionNote != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: PT.mint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Kết luận Admin: ${r.disputeResolutionNote}',
                      style: PT.body(13, PT.green),
                    ),
                  ),
                ],
                if (r.disputeStatus == 'Chờ xử lý') ...[
                  const SizedBox(height: 12),
                  PrimaryButton(
                    'Gỡ đánh giá vi phạm',
                    icon: LucideIcons.trash2,
                    busy: f.busy,
                    onTap: f.busy
                        ? null
                        : () => f.perform(
                            () => s.workflows.resolveDispute(
                              r.id,
                              true,
                              'Đánh giá vi phạm tiêu chuẩn cộng đồng, đã gỡ.',
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    'Giữ nguyên đánh giá (Bác bỏ khiếu nại)',
                    outline: true,
                    icon: LucideIcons.shieldCheck,
                    busy: f.busy,
                    onTap: f.busy
                        ? null
                        : () => f.perform(
                            () => s.workflows.resolveDispute(
                              r.id,
                              false,
                              'Đánh giá hợp lệ từ hợp đồng thực tế.',
                            ),
                          ),
                  ),
                ],
              ]),
          ],
          if (tab == 1) ...[
            if (s.store.orders.isEmpty)
              const EmptyState(
                'Chưa có giao dịch phát sinh',
                'Giao dịch mua gói VIP hoặc lượt đẩy tin sẽ hiển thị ở đây.',
              ),
            for (final o in s.store.orders.reversed)
              flowCard('${o.plan.name} • ${o.amount}đ', [
                Text('Mã đơn: ${o.id} • Khách hàng: ${o.userId}'),
                const SizedBox(height: 4),
                Text(
                  'Phương thức: ${o.method} • Chu kỳ: ${o.yearly ? 'Năm' : 'Tháng'}',
                  style: PT.body(13, PT.muted),
                ),
                const SizedBox(height: 8),
                Pill(
                  o.status,
                  dense: true,
                  color: o.status == 'Thành công' ? PT.green : PT.amber,
                ),
              ]),
          ],
          if (tab == 2) ...[
            for (final log in s.store.auditLogs)
              flowCard('${log.action} • ${log.target}', [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.shield,
                      size: 15,
                      color: PT.green,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'IP: ${log.ipAddress}',
                        style: PT.body(13, PT.deep).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Quản trị viên: ${log.actorName} • Thời gian: ${log.timestamp.toIso8601String().substring(0, 16)}',
                  style: PT.body(12, PT.muted),
                ),
              ]),
          ],
        ];
      },
    );
  }
}
