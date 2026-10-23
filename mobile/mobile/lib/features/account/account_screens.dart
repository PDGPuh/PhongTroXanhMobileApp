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
import '../../api/http_user_repository.dart';

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
  void initState() {
    super.initState();
    widget.state.loadUserProfile();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final lockViewport = constraints.maxHeight >= 520 && textScale <= 1.25;
      final minContentHeight = lockViewport
          ? math.max(0.0, constraints.maxHeight - 10)
          : 0.0;
      final showTrustBanner = lockViewport && constraints.maxHeight >= 660;
      return RefreshIndicator(
        onRefresh: () async {
          await widget.state.loadUserProfile();
          if (mounted) setState(() {});
        },
        color: PT.green,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                                name: state.fullName,
                                imageUrl: state.avatarUrl ?? state.session.user?.avatarUrl,
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
                            subtitle:
                                'Điểm hiện tại: ${state.store.profiles[state.userId]?.trustScore ?? 50}/100',
                            onTap: () {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(
                                      builder: (_) =>
                                          TrustScreen(state: state)))
                                  .then((_) {
                                if (mounted) setState(() {});
                              });
                            },
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
      ),
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

class TrustScreen extends StatefulWidget {
  final AppState state;
  const TrustScreen({super.key, required this.state});
  @override
  State<TrustScreen> createState() => _TrustScreenState();
}

class _TrustScreenState extends State<TrustScreen> {
  TrustScoreDTO? _scoreData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTrustScore();
  }

  Future<void> _loadTrustScore() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await widget.state.userRepository.getTrustScore();
      if (mounted) {
        setState(() {
          _scoreData = data;
          _isLoading = false;
        });
        final p = widget.state.store.profiles[widget.state.userId];
        if (p != null) p.trustScore = data.currentScore;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  Widget _buildCriterionItem({
    required IconData icon,
    required String label,
    required int value,
    required int max,
    required String desc,
  }) {
    final percent = (value / max).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: PT.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: PT.title(13).copyWith(color: const Color(0xFF1E293B)),
                ),
              ),
              RichText(
                text: TextSpan(
                  style: PT.title(14).copyWith(color: const Color(0xFF0F172A)),
                  children: [
                    TextSpan(text: '$value '),
                    TextSpan(
                      text: '/ $max điểm',
                      style: PT.body(11, PT.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                value > 0 ? PT.green : const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: PT.body(11, const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem({
    required String label,
    required String desc,
    required bool on,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: on ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: on ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: on ? PT.green : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              on ? LucideIcons.check : LucideIcons.award,
              size: 18,
              color: on ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: PT.title(13).copyWith(
                    color: on ? const Color(0xFF064E3B) : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: PT.body(11, const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandlord = widget.state.role == UserRole.landlord;
    final score = _scoreData?.currentScore ??
        (widget.state.store.profiles[widget.state.userId]?.trustScore ?? 50);
    final isVerified = _scoreData?.isVerified ??
        (widget.state.verification == 'Đã duyệt' ||
            widget.state.verification == 'Đã xác minh');
    final kycScore = _scoreData?.kycScore ?? (isVerified ? 30 : 0);
    final reviewScore = _scoreData?.reviewScore ?? 0;
    final rentalScore = _scoreData?.rentalDurationScore ?? 0;
    final responseScore = _scoreData?.responseRateScore ?? 20;
    final userBadges = _scoreData?.badges ?? <String>[];
    final history = _scoreData?.history ?? <TrustScoreLogDTO>[];
    final pillarTotal = kycScore + reviewScore + rentalScore + responseScore;

    return BasicPage(
      title: 'Điểm uy tín',
      child: RefreshIndicator(
        onRefresh: _loadTrustScore,
        color: PT.green,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoading && _scoreData == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: PT.green),
                ),
              )
            else if (_errorMessage != null && _scoreData == null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                child: Column(
                  children: [
                    const Icon(LucideIcons.alertCircle,
                        size: 40, color: Color(0xFFD97706)),
                    const SizedBox(height: 12),
                    Text(_errorMessage!,
                        textAlign: TextAlign.center, style: PT.body(13)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: _loadTrustScore,
                        child: const Text('Thử lại')),
                  ],
                ),
              )
            else ...[
              // KYC Status Banner
              if (!isVerified)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.shieldAlert,
                            size: 20, color: Color(0xFFB45309)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tài khoản chưa xác thực CCCD',
                              style: PT.title(13)
                                  .copyWith(color: const Color(0xFF78350F)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Nộp CCCD 2 mặt để nhận huy hiệu Đã xác minh và cộng ngay +30 điểm uy tín.',
                              style: PT.body(11, const Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => openPage(
                            context, VerificationScreen(state: widget.state)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Xác minh',
                                style: PT.caption(Colors.white)
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Icon(LucideIcons.arrowRight,
                                  size: 12, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.shieldCheck,
                            size: 20, color: PT.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tài khoản đã xác minh CCCD',
                              style: PT.title(13)
                                  .copyWith(color: const Color(0xFF064E3B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hồ sơ của bạn hiển thị dấu tích xanh và được ưu tiên khi tìm bạn ghép phòng.',
                              style: PT.body(11, const Color(0xFF047857)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Donut Score Card
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: PT.card(),
                child: Column(
                  children: [
                    Text(
                      'ĐIỂM HIỆN TẠI',
                      style: PT.title(12).copyWith(
                        color: const Color(0xFF64748B),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: CircularProgressIndicator(
                              value: (score / 100.0).clamp(0.0, 1.0),
                              strokeWidth: 12,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                score >= 70
                                    ? PT.green
                                    : score >= 50
                                        ? const Color(0xFF0284C7)
                                        : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$score',
                                style: PT.title(38).copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '/ 100',
                                style: PT.caption(const Color(0xFF64748B))
                                    .copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: score >= 70
                            ? PT.green
                            : score >= 50
                                ? const Color(0xFF0284C7)
                                : const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.award,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            score >= 80
                                ? 'Uy tín xuất sắc'
                                : score >= 70
                                    ? 'Uy tín cao'
                                    : score >= 50
                                        ? 'Uy tín trung bình'
                                        : 'Cần cải thiện',
                            style: PT.title(12).copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),
                    Text(
                      score >= 70
                          ? 'Tài khoản có độ tin cậy tốt, dễ dàng tạo thiện cảm khi liên hệ chủ trọ và tìm bạn ở ghép.'
                          : 'Hoàn tất xác thực CCCD và cập nhật hồ sơ để gia tăng độ uy tín cho tài khoản của bạn.',
                      textAlign: TextAlign.center,
                      style: PT.body(12, const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Breakdown Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: PT.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Chi tiết điểm số', style: PT.title(16)),
                              const SizedBox(height: 2),
                              Text(
                                'Đánh giá trực tiếp từ dữ liệu hồ sơ, hợp đồng và đánh giá',
                                style: PT.body(11, PT.muted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            'Tổng tiêu chí: $pillarTotal/100',
                            style: PT.caption(const Color(0xFF334155))
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCriterionItem(
                      icon: LucideIcons.shieldCheck,
                      label: 'Xác thực danh tính CCCD',
                      value: kycScore,
                      max: 30,
                      desc:
                          'Cộng 30 điểm khi hồ sơ xác thực CCCD được phê duyệt thành công.',
                    ),
                    const SizedBox(height: 12),
                    _buildCriterionItem(
                      icon: LucideIcons.star,
                      label: 'Đánh giá nhận được',
                      value: reviewScore,
                      max: 30,
                      desc: isLandlord
                          ? 'Tính toán từ các lượt đánh giá nhận được từ khách thuê đã ở phòng thực tế.'
                          : 'Tính toán từ các lượt đánh giá nhận được từ chủ trọ và bạn cùng phòng.',
                    ),
                    const SizedBox(height: 12),
                    _buildCriterionItem(
                      icon: LucideIcons.house,
                      label: isLandlord
                          ? 'Lịch sử cho thuê phòng'
                          : 'Lịch sử thuê trọ',
                      value: rentalScore,
                      max: 20,
                      desc: isLandlord
                          ? 'Tính theo số hợp đồng cho thuê phòng đã xác nhận bàn giao thành công trên hệ thống (10 điểm/hợp đồng, tối đa 20 điểm).'
                          : 'Tính theo số hợp đồng thuê phòng đã xác nhận bàn giao trên hệ thống (10 điểm/hợp đồng, tối đa 20 điểm).',
                    ),
                    const SizedBox(height: 12),
                    _buildCriterionItem(
                      icon: LucideIcons.messageCircle,
                      label: 'Mức độ hoàn thiện hồ sơ',
                      value: responseScore,
                      max: 20,
                      desc: isLandlord
                          ? 'Cập nhật đầy đủ thông tin chủ trọ, địa chỉ liên hệ và danh mục phòng trọ.'
                          : 'Cập nhật đầy đủ lời giới thiệu, trường học hoặc nơi làm việc, ngân sách dự kiến.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Badges Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: PT.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Huy hiệu', style: PT.title(16)),
                    const SizedBox(height: 14),
                    _buildBadgeItem(
                      label: 'Đã xác minh',
                      desc: isVerified
                          ? 'CCCD đã được duyệt'
                          : 'Chưa hoàn tất xác thực CCCD',
                      on: isVerified ||
                          userBadges.contains('ĐÃ_XÁC_MINH_CCCD') ||
                          userBadges.contains('VERIFIED'),
                    ),
                    const SizedBox(height: 10),
                    _buildBadgeItem(
                      label: isLandlord
                          ? 'Chủ trọ uy tín'
                          : 'Người thuê uy tín',
                      desc: 'Đạt mốc điểm uy tín từ 80+',
                      on: score >= 80 ||
                          userBadges.contains('NGƯỜI_DÙNG_UY_TÍN_CAO') ||
                          userBadges.contains('RELIABLE_TENANT'),
                    ),
                    const SizedBox(height: 10),
                    _buildBadgeItem(
                      label: isLandlord
                          ? 'Hồ sơ chủ trọ chuẩn mực'
                          : 'Hồ sơ chuẩn mực',
                      desc: isLandlord
                          ? 'Hoàn thiện thông tin cơ sở & tương tác thường xuyên'
                          : 'Hoàn thiện hồ sơ & tương tác thường xuyên',
                      on: responseScore >= 15 ||
                          userBadges.contains('FAST_RESPONDER'),
                    ),
                    const SizedBox(height: 10),
                    _buildBadgeItem(
                      label: isLandlord
                          ? 'Chủ trọ tích cực'
                          : 'Người thuê tích cực',
                      desc: isLandlord
                          ? 'Có lịch sử bàn giao hợp đồng cho thuê'
                          : 'Có lịch sử hợp đồng thuê phòng',
                      on: rentalScore >= 20 ||
                          userBadges.contains('LONG_TERM'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // History Logs Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: PT.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.history,
                                size: 18, color: PT.green),
                            const SizedBox(width: 8),
                            Text('Lịch sử biến động',
                                style: PT.title(16)),
                          ],
                        ),
                        Text('Ghi nhận hệ thống',
                            style: PT.body(11, PT.muted)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (history.isNotEmpty)
                      Column(
                        children: history.map((item) {
                          final isPositive = item.delta > 0;
                          final isNegative = item.delta < 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.reason, style: PT.title(13)),
                                      if (item.createdAt != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatDate(item.createdAt),
                                          style: PT.caption(PT.muted),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isPositive
                                            ? const Color(0xFFD1FAE5)
                                            : isNegative
                                                ? const Color(0xFFFFE4E6)
                                                : const Color(0xFFF1F5F9),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isPositive
                                            ? '+${item.delta} điểm'
                                            : '${item.delta} điểm',
                                        style: PT.caption(
                                          isPositive
                                              ? const Color(0xFF065F46)
                                              : isNegative
                                                  ? const Color(0xFF9F1239)
                                                  : const Color(0xFF334155),
                                        ).copyWith(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Sau đổi: ${item.finalScore}',
                                      style: PT.caption(PT.muted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Chưa ghi nhận biến động điểm số nào.',
                              style: PT.body(12, const Color(0xFF64748B)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Điểm ban đầu mặc định là 50/100. Biến động điểm sẽ được tự động ghi nhận khi bạn xác thực CCCD, hoàn tất hợp đồng thuê hoặc nhận đánh giá.',
                              style: PT.caption(PT.muted),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
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
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(item.title, style: PT.title(16)),
          content: Text(item.description, style: PT.body(14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
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
