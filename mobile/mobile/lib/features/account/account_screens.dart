import 'dart:math' as math;

import 'account_workflows.dart';
import 'support_screens.dart';
import 'payment_screens.dart';
export 'account_workflows.dart';
export 'payment_screens.dart';
export 'support_screens.dart';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../domain/models.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../rooms/room_screens.dart';
import '../chat/chat_screens.dart';
import '../rentals/rental_screens.dart';

class ProfileScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.state, required this.onLogout});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int sectionTab = 0;
  AppState get state => widget.state;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final lockViewport = constraints.maxHeight >= 520 && textScale <= 1.25;
      final minContentHeight = lockViewport
          ? math.max(0.0, constraints.maxHeight - 10)
          : 0.0;
      final showTrustBanner = lockViewport && constraints.maxHeight >= 660;
      return ListView(
        physics: lockViewport
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
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
                      unreadNotifications: state.unreadNotifications,
                      onMap: () => openPage(context, MapScreen(state: state)),
                      onNotifications: () => openPage(
                        context,
                        NotificationsScreen(state: state),
                      ),
                    ),
                    const PageHeading(
                      'Cá nhân',
                      'Quản lý thông tin và hành trình của bạn',
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: PT.card(radius: 14),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AvatarPhoto(
                                kind: state.store.profiles[state.userId]!.avatar,
                                photo: state
                                    .store
                                    .profiles[state.userId]!
                                    .avatarPhoto,
                                size: 48,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            state.fullName,
                                            style: PT.title(15),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Chỉnh sửa hồ sơ',
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 28,
                                            minHeight: 28,
                                          ),
                                          onPressed: () => openPage(
                                            context,
                                            EditProfileScreen(state: state),
                                          ),
                                          icon: const Icon(
                                            LucideIcons.pencil,
                                            size: 15,
                                            color: PT.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      state.email,
                                      style: PT.body(11, PT.muted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Pill(
                                      state.verification,
                                      icon: LucideIcons.shieldCheck,
                                      color: PT.green,
                                      dense: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _ProfileStat(
                                LucideIcons.eye,
                                '${state.store.workspace(state.session.user!).viewed.length}',
                                'Phòng đã xem',
                              ),
                              const SizedBox(width: 6),
                              _ProfileStat(
                                LucideIcons.heart,
                                '${state.saved.length}',
                                'Phòng đã lưu',
                              ),
                              const SizedBox(width: 6),
                              _ProfileStat(
                                LucideIcons.users,
                                '${state.store.matches[state.userId]?.length ?? 0}',
                                'Bạn đã match',
                              ),
                            ],
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
                                color: sectionTab == i
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(9),
                                  onTap: () => setState(() => sectionTab = i),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 7,
                                    ),
                                    child: Text(
                                      ['Tài khoản', 'Hoạt động', 'Cài đặt'][i],
                                      textAlign: TextAlign.center,
                                      style: PT.caption(
                                        sectionTab == i ? PT.green : PT.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (sectionTab == 0)
                      _ProfileSection(
                        title: 'Tài khoản',
                        children: [
                          MenuRow(
                            spacious: true,
                            framed: false,
                            icon: LucideIcons.user,
                            title: 'Hồ sơ của tôi',
                            subtitle: 'Xem và chỉnh sửa thông tin cá nhân',
                            onTap: () => openPage(
                              context,
                              EditProfileScreen(state: state),
                            ),
                          ),
                          MenuRow(
                            spacious: true,
                            framed: false,
                            icon: LucideIcons.eye,
                            title: 'Hồ sơ công khai',
                            subtitle: 'Xem trước thông tin đã lưu',
                            onTap: () => openPage(
                              context,
                              PublicProfileScreen(state: state),
                            ),
                          ),
                          MenuRow(
                            spacious: true,
                            framed: false,
                            icon: LucideIcons.clipboardList,
                            title: 'Hoàn thiện hồ sơ',
                            subtitle: 'Tiếp tục onboarding và bản nháp',
                            onTap: () => openPage(
                              context,
                              ProfileSetupScreen(
                                state: state,
                                onComplete: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                          MenuRow(
                            spacious: true,
                            framed: false,
                            icon: LucideIcons.shieldCheck,
                            title: 'Xác minh tài khoản',
                            subtitle: state.verification,
                            onTap: () => openPage(
                              context,
                              VerificationScreen(state: state),
                            ),
                          ),
                          MenuRow(
                            spacious: true,
                            framed: false,
                            icon: LucideIcons.award,
                            title: 'Điểm uy tín',
                            subtitle: 'Đánh giá và hành trình thuê của bạn',
                            onTap: () =>
                                openPage(context, TrustScreen(state: state)),
                          ),
                          MenuRow(
                            spacious: true,
                            framed: false,
                            icon: LucideIcons.gem,
                            title: 'Gói dịch vụ',
                            subtitle: 'Quyền lợi và lịch sử giao dịch',
                            onTap: () => openPage(
                              context,
                              PackagesScreen(state: state),
                            ),
                          ),
                        ],
                      ),
                    if (sectionTab == 1)
                      _ProfileSection(
                        title: 'Hoạt động của bạn',
                        children: [
                          MenuRow(
                            spacious: true,
                            framed: false,
                            icon: LucideIcons.heart,
                            title: 'Phòng đã lưu',
                            subtitle: 'Xem lại danh sách phòng yêu thích',
                            onTap: () => openPage(
                              context,
                              SavedRoomsScreen(state: state),
                            ),
                          ),
                          MenuRow(
                            spacious: true,
                            framed: false,
                            icon: LucideIcons.users,
                            title: 'Bạn đã match',
                            subtitle: 'Những người bạn đã ghép',
                            onTap: () =>
                                openPage(context, MatchesScreen(state: state)),
                          ),
                          MenuRow(
                            spacious: true,
                            framed: false,
                            icon: LucideIcons.clock,
                            title: 'Lịch sử nhận phòng',
                            subtitle: 'Các phòng bạn đang và đã thuê',
                            onTap: () =>
                                openPage(context, RentalsScreen(state: state)),
                          ),
                          MenuRow(
                            spacious: true,
                            framed: false,
                            icon: LucideIcons.star,
                            title: 'Lịch sử đánh giá',
                            subtitle: 'Đánh giá đã gửi và nhận được',
                            onTap: () => openPage(
                              context,
                              ReviewHistoryScreen(state: state),
                            ),
                          ),
                          MenuRow(
                            spacious: true,
                            framed: false,
                            icon: LucideIcons.flag,
                            title: 'Báo cáo của tôi',
                            subtitle: 'Theo dõi kết quả xử lý',
                            onTap: () => openPage(
                              context,
                              MyReportsScreen(state: state),
                            ),
                          ),
                          MenuRow(
                            spacious: true,
                            framed: false,
                            icon: LucideIcons.arrowLeftRight,
                            title: 'Đổi phòng',
                            subtitle: 'Tạo và theo dõi yêu cầu đổi phòng',
                            onTap: () =>
                                openPage(context, SwapScreen(state: state)),
                          ),
                        ],
                      ),
                    if (sectionTab == 2)
                      _ProfileSection(
                        title: 'Cài đặt & hỗ trợ',
                        children: [
                          MenuRow(
                            spacious: true,
                            framed: false,
                            icon: LucideIcons.settings,
                            title: 'Cài đặt',
                            subtitle: 'Thông báo, quyền riêng tư',
                            onTap: () =>
                                openPage(context, SettingsScreen(state: state)),
                          ),
                          MenuRow(
                            spacious: true,
                            framed: false,
                            icon: LucideIcons.circleHelp,
                            title: 'Trung tâm hỗ trợ',
                            subtitle: 'Câu hỏi thường gặp và liên hệ hỗ trợ',
                            onTap: () => openPage(context, HelpScreen()),
                          ),
                        ],
                      ),
                  ],
                ),
                if (showTrustBanner)
                  Material(
                    color: PT.mint,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () =>
                          openPage(context, PackagesScreen(state: state)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                LucideIcons.gem,
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
                                    'Gói hiện tại: ${state.store.profiles[state.userId]!.package}',
                                    style: PT.title(13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Mở khóa quẹt không giới hạn & ưu tiên ghép đôi hợp gu',
                                    style: PT.body(11, PT.muted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: PT.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                PrimaryButton(
                  'Đăng xuất',
                  outline: true,
                  icon: LucideIcons.logOut,
                  onTap: () {
                    final scope = AppScope.maybeOf(context);
                    if (scope != null) {
                      scope.logout();
                    } else {
                      widget.onLogout();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _ProfileSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(header: true, child: Text(title, style: PT.title(17))),
      const SizedBox(height: 6),
      LayoutBuilder(
        builder: (context, constraints) {
          final twoCol =
              constraints.maxWidth >= 335 &&
              MediaQuery.textScalerOf(context).scale(12) <= 15;
          if (!twoCol) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: PT.card(),
              child: Column(children: children),
            );
          }
          final cellWidth = (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final child in children)
                Container(
                  width: cellWidth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 1,
                  ),
                  decoration: PT.card(radius: 13),
                  child: child,
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _ProfileStat(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: PT.mint,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Icon(icon, color: PT.green, size: 18),
          const SizedBox(height: 3),
          Text(value, style: PT.title(17)),
          const SizedBox(height: 2),
          Text(label, style: PT.body(10), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class TrustScreen extends StatelessWidget {
  final AppState state;
  const TrustScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) => BasicPage(
    title: 'Điểm uy tín',
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: PT.card(color: PT.mint),
          child: Column(
            children: [
              const Icon(LucideIcons.shieldCheck, size: 36, color: PT.green),
              const SizedBox(height: 10),
              Text('78 / 100', style: PT.title(32)),
              const SizedBox(height: 6),
              const Pill('Đáng tin cậy', color: PT.green, dense: true),
              const SizedBox(height: 10),
              RepaintBoundary(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: const LinearProgressIndicator(
                    value: 0.78,
                    minHeight: 7,
                    backgroundColor: Colors.white,
                    color: PT.green,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  Pill('CCCD +40đ', color: PT.green, dense: true),
                  Pill('Hồ sơ +20đ', color: PT.green, dense: true),
                  Pill('Thuê tốt +18đ', color: PT.green, dense: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('Hành trình xây dựng uy tín', style: PT.title(19)),
        const SizedBox(height: 10),
        MenuRow(
          icon: LucideIcons.badgeCheck,
          title: 'Xác minh danh tính',
          subtitle: state.verification,
          onTap: () => openPage(context, VerificationScreen(state: state)),
        ),
        MenuRow(
          icon: LucideIcons.house,
          title: 'Lịch sử thuê',
          subtitle:
              '${state.rentals.where((r) => r.checkedIn).length} phòng đã nhận',
          onTap: () => openPage(context, RentalsScreen(state: state)),
        ),
        Text(
          'Điểm hiển thị là dữ liệu minh họa của bản UI.',
          style: PT.body(12, PT.muted),
        ),
      ],
    ),
  );
}

class NotificationsScreen extends StatelessWidget {
  final AppState state;
  const NotificationsScreen({super.key, required this.state});
  void openNotification(BuildContext context, AppNotification item) {
    state.readNotification(item.id);
    if (item.verification) {
      openPage(context, VerificationScreen(state: state));
      return;
    }
    final target = item.target;
    if (target == null || !state.resourceExists(target)) {
      openPage(context, const AccessNotice(result: AccessResult.missing));
      return;
    }
    switch (target.kind) {
      case ResourceKind.room:
        openPage(
          context,
          RoomDetailScreen(state: state, room: state.roomById(target.id)!),
        );
      case ResourceKind.conversation:
        openPage(
          context,
          ChatScreen(
            state: state,
            conversation: state.conversationById(target.id)!,
          ),
        );
      case ResourceKind.person:
        openPage(
          context,
          PersonDetailScreen(
            state: state,
            person: state.personById(target.id)!,
          ),
        );
      case ResourceKind.rental:
        openPage(context, RentalsScreen(state: state, rentalId: target.id));
      case ResourceKind.order:
        openPage(context, PaymentHistoryScreen(state: state));
      default:
        openPage(context, const AccessNotice(result: AccessResult.missing));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => BasicPage(
      title: 'Thông báo',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            state.notifications.isEmpty
                ? 'Bạn chưa có thông báo nào'
                : state.unreadNotifications == 0
                ? 'Bạn đã đọc tất cả thông báo'
                : 'Bạn có ${state.unreadNotifications} thông báo chưa đọc',
            style: PT.body(15, PT.muted),
          ),
          const SizedBox(height: 8),
          if (state.notifications.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  minimumSize: const Size(48, 48),
                ),
                onPressed: state.unreadNotifications == 0
                    ? null
                    : state.markNotificationsRead,
                child: const Text('Đánh dấu đã đọc'),
              ),
            ),
          const SizedBox(height: 16),
          if (state.notifications.isEmpty)
            const EmptyState(
              'Chưa có thông báo',
              'Thông báo mới sẽ xuất hiện tại đây.',
              icon: LucideIcons.bell,
            ),
          for (final (index, item) in state.notifications.indexed) ...[
            _NotificationRow(
              item: item,
              onTap: () => openNotification(context, item),
            ),
            if (index < state.notifications.length - 1)
              const Divider(height: 16),
          ],
        ],
      ),
    ),
  );
}

class _NotificationRow extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;
  const _NotificationRow({required this.item, required this.onTap});

  IconData get icon => item.verification
      ? LucideIcons.shieldCheck
      : switch (item.target?.kind) {
          ResourceKind.room => LucideIcons.house,
          ResourceKind.person => LucideIcons.users,
          ResourceKind.rental => LucideIcons.keyRound,
          ResourceKind.order => LucideIcons.creditCard,
          ResourceKind.conversation => LucideIcons.messageCircle,
          _ => LucideIcons.bell,
        };

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.read ? PT.grey : PT.mint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: item.read ? PT.muted : PT.green,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: PT
                          .title(16)
                          .copyWith(
                            fontWeight: item.read
                                ? FontWeight.w500
                                : FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(item.description, style: PT.body(15, PT.muted)),
                    const SizedBox(height: 10),
                    Text(
                      item.read ? 'Đã đọc' : 'Chưa đọc',
                      style: PT
                          .body(12, item.read ? PT.muted : PT.green)
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const ExcludeSemantics(
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: PT.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SettingsScreen extends StatefulWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool get notifications => widget.state.settings['notifications'] ?? true;
  bool get messages => widget.state.settings['messages'] ?? true;
  bool get public => widget.state.settings['public'] ?? true;
  @override
  Widget build(BuildContext context) => BasicPage(
    title: 'Cài đặt',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Thông báo', style: PT.title(23)),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Phòng mới phù hợp'),
          value: notifications,
          onChanged: (v) =>
              setState(() => widget.state.setSetting('notifications', v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Tin nhắn mới'),
          value: messages,
          onChanged: (v) =>
              setState(() => widget.state.setSetting('messages', v)),
        ),
        const Divider(),
        const SizedBox(height: 16),
        Text('Quyền riêng tư', style: PT.title(23)),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Hiển thị hồ sơ ghép bạn'),
          value: public,
          onChanged: (v) =>
              setState(() => widget.state.setSetting('public', v)),
        ),
        const SizedBox(height: 20),
        const Text('Ngôn ngữ: Tiếng Việt'),
        TextButton(
          onPressed: () =>
              openPage(context, DeleteAccountScreen(state: widget.state)),
          child: const Text('Xóa tài khoản demo'),
        ),
        const SizedBox(height: 12),
        Text(
          'Cài đặt được lưu theo tài khoản trong bản demo.',
          style: PT.body(12, PT.muted),
        ),
      ],
    ),
  );
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => BasicPage(
    title: 'Trung tâm hỗ trợ',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Chúng tôi luôn sẵn sàng hỗ trợ', style: PT.title(27)),
        const SizedBox(height: 20),
        for (final faq in [
          (
            'Làm thế nào để lưu phòng?',
            'Bấm biểu tượng trái tim hoặc vuốt thẻ phòng sang phải. Bạn có thể xem lại tại Cá nhân → Phòng đã lưu.',
          ),
          (
            'Khi nào được đánh giá?',
            'Bạn có thể đánh giá sau khi hoàn thành nhận phòng và được liên kết với phòng thuê.',
          ),
          (
            'Đổi phòng thuê như thế nào?',
            'Tạo yêu cầu từ hợp đồng đã nhận phòng. Người ký chính cần chủ trọ duyệt trước khi mở tin; người ở ghép bắt đầu tìm phòng phù hợp. Chấp nhận đề nghị chưa tự thay thế hợp đồng.',
          ),
        ])
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(faq.$1, style: PT.body(15)),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(faq.$2, style: PT.body(14, PT.muted)),
              ),
            ],
          ),
        const SizedBox(height: 24),
        const Text('Email: hotro@phongtroxanh.vn'),
        const SizedBox(height: 16),
        PrimaryButton(
          'Liên hệ hỗ trợ',
          onTap: () => withSession(
            context,
            () => openPage(
              context,
              SupportScreen(state: AppScope.maybeOf(context)!.state),
            ),
          ),
        ),
      ],
    ),
  );
}
