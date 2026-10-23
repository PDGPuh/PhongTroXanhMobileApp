import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../api/http_admin_repository.dart';
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
  String reviewScope = 'SYSTEM'; // 'LANDLORD' or 'SYSTEM'
  int? selectedStarFilter;
  AdminDashboardData? _liveDashboard;
  bool _loadingDashboard = false;

  @override
  void initState() {
    super.initState();
    if (widget.state.adminRepository.hasAuthToken) {
      _refreshDashboard();
    }
  }

  Future<void> _refreshDashboard() async {
    if (_loadingDashboard || !mounted) return;
    setState(() => _loadingDashboard = true);
    try {
      final res = await widget.state.adminRepository.getDashboard();
      if (mounted) {
        setState(() {
          _liveDashboard = res;
          _loadingDashboard = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingDashboard = false);
      }
    }
  }

  String _formatVnd(num amount) {
    final v = amount.round();
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(2)}tr đ';
    }
    if (v >= 1000) {
      return '${(v / 1000).round()}k đ';
    }
    return '$v đ';
  }

  String _formatCategoryLabel(String cat) => switch (cat.toUpperCase()) {
    'UI_UX' => 'Giao diện (UI/UX)',
    'BUG' => 'Báo lỗi',
    'FEATURE' => 'Tính năng',
    'PERFORMANCE' => 'Hiệu năng',
    _ => 'Góp ý chung',
  };

  AdminDashboardData _buildDemoDashboard(AppState state) {
    final profiles = state.store.profiles.values
        .where((p) => !state.store.deleted.contains(p.user.id))
        .toList();
    final totalUsers = profiles.length;
    final totalLandlords = profiles
        .where((p) => p.user.role == UserRole.landlord)
        .length;
    final totalTenants = profiles
        .where((p) => p.user.role == UserRole.tenant)
        .length;
    final verifiedUsersCount = profiles
        .where(
          (p) =>
              state.store.workspace(p.user).verification == 'Đã xác minh' ||
              p.user.role != UserRole.tenant,
        )
        .length;

    final totalRooms = state.rooms.length;
    final activeRooms = state.rooms
        .where((r) => r.status == RoomStatus.available)
        .length;
    final pendingRooms = state.rooms
        .where((r) => r.status == RoomStatus.pending)
        .length;
    final hiddenRooms = state.rooms
        .where((r) => r.status == RoomStatus.hidden)
        .length;
    final rentedRooms = math.max(
      0,
      totalRooms - activeRooms - pendingRooms - hiddenRooms,
    );
    final boostedRooms = state.rooms.where((r) => r.isBoosted).length;

    final totalRentals = state.store.rentals.length;
    final activeRentals = state.store.rentals
        .where((r) => r.status == RentalStatus.active)
        .length;

    final pendingKyc = state.store.kyc
        .where((k) => k.status == 'Chờ duyệt')
        .length;
    final approvedKyc =
        state.store.kyc.where((k) => k.status == 'Đã xác minh').length + 14;
    final rejectedKyc =
        state.store.kyc.where((k) => k.status == 'Đã từ chối').length + 2;
    final totalKyc = pendingKyc + approvedKyc + rejectedKyc;
    final kycApprovalRate = totalKyc == 0
        ? 92.0
        : (approvedKyc * 100.0 / totalKyc);

    final pendingDisputes = state.store.reviewRecords
        .where((r) => r.disputeStatus == 'Chờ xử lý')
        .length;
    final pendingReports = state.store.reports
        .where((r) => r.status == 'Chờ xử lý')
        .length;

    final paidOrders = state.store.orders
        .where((o) => o.status == 'Thành công')
        .toList();
    final orderRevenue = paidOrders.fold<int>(0, (s, o) => s + o.amount);
    final totalRevenue = (14850000 + orderRevenue).toDouble();
    final totalTransactions = 28 + paidOrders.length;

    final matchPairs =
        18 +
        state.store.matches.values.fold<int>(0, (s, set) => s + set.length);
    final totalSwipes =
        245 +
        profiles.fold<int>(
          0,
          (s, p) =>
              s +
              state.store.workspace(p.user).saved.length +
              state.store.workspace(p.user).liked.length,
        );
    final totalSwapRequests = 6 + state.store.swaps.length;

    final recentReviews = <AdminRecentReview>[
      for (final r in state.store.reviewRecords.reversed)
        AdminRecentReview(
          id: r.id,
          reviewerName: r.authorName,
          reviewerRole: r.targetType == 'ROOM' ? 'TENANT' : 'LANDLORD',
          landlordName:
              state.roomById(r.targetId)?.landlordName ?? 'Chủ trọ PTX',
          isVerifiedStay: true,
          rating: r.rating,
          comment: r.comment,
          landlordReply: r.landlordReply,
          repliedAt: r.repliedAt?.toIso8601String(),
          roomTitle:
              state.roomById(r.targetId)?.title ?? 'Phòng trọ ${r.targetId}',
          createdAt: r.createdAt.toIso8601String().substring(0, 10),
        ),
      const AdminRecentReview(
        id: 'rev-demo-1',
        reviewerName: 'Nguyễn Hoài An',
        reviewerRole: 'TENANT',
        landlordName: 'Cô Hồng',
        isVerifiedStay: true,
        rating: 5,
        comment:
            'Phòng sạch thoáng đúng ảnh thực tế, chủ nhà hỗ trợ nhận phòng bằng QR rất nhanh.',
        landlordReply: 'Cảm ơn An đã giữ phòng sạch sẽ và đóng tiền đúng hạn!',
        repliedAt: '2026-10-14',
        roomTitle: 'Studio xanh gần Bách Khoa',
        createdAt: '2026-10-14',
      ),
      const AdminRecentReview(
        id: 'rev-demo-2',
        reviewerName: 'Lê Thu Hà',
        reviewerRole: 'TENANT',
        landlordName: 'Nguyễn Văn Hùng',
        isVerifiedStay: true,
        rating: 4,
        comment:
            'An ninh vân tay rất yên tâm, khu vực Thảo Điền yên tĩnh phù hợp làm việc.',
        roomTitle: 'Căn hộ mini Thảo Điền có ban công',
        createdAt: '2026-10-12',
      ),
    ];

    final avgLandlordRating = recentReviews.isEmpty
        ? 4.8
        : recentReviews.fold<int>(0, (s, r) => s + r.rating) /
              recentReviews.length;

    final sysFeedbacks = <AdminSystemFeedback>[
      for (final fb in state.store.systemFeedbacks)
        AdminSystemFeedback(
          id: fb.id,
          userId: fb.id,
          userName: fb.authorName,
          userRole: fb.roleLabel == 'Chủ trọ' ? 'LANDLORD' : 'TENANT',
          rating: fb.rating,
          category: fb.id == 'fb-1'
              ? 'UI_UX'
              : fb.id == 'fb-2'
              ? 'FEATURE'
              : 'PERFORMANCE',
          comment: fb.comment,
          createdAt: fb.createdAt.toIso8601String().substring(0, 10),
        ),
    ];

    final ratingDist = <AdminRatingBreakdown>[
      for (final star in [5, 4, 3, 2, 1])
        () {
          final cnt = recentReviews.where((r) => r.rating == star).length;
          final pct = recentReviews.isEmpty
              ? 0.0
              : (cnt * 100.0 / recentReviews.length);
          return AdminRatingBreakdown(star: star, count: cnt, percentage: pct);
        }(),
    ];

    final pkgStats = <AdminPackageStat>[
      const AdminPackageStat(
        planId: 'LANDLORD_PRO',
        planName: 'Gói Chủ Trọ Chuyên Nghiệp',
        revenue: 6450000,
        count: 11,
      ),
      const AdminPackageStat(
        planId: 'LANDLORD_VIP',
        planName: 'Gói Chủ Trọ VIP',
        revenue: 4280000,
        count: 9,
      ),
      const AdminPackageStat(
        planId: 'VIP_TENANT',
        planName: 'Gói VIP Ghép Đôi Siêu Tốc',
        revenue: 2650000,
        count: 8,
      ),
      AdminPackageStat(
        planId: 'PRO_TENANT',
        planName: 'Gói Pro Tìm Bạn & Thuê Phòng',
        revenue: (1470000 + orderRevenue).toDouble(),
        count: 6 + paidOrders.length,
      ),
    ];

    return AdminDashboardData(
      totalUsers: totalUsers,
      totalLandlords: totalLandlords,
      totalTenants: totalTenants,
      totalRooms: totalRooms,
      activeRooms: activeRooms,
      totalMatches: matchPairs,
      totalRentals: totalRentals,
      activeRentals: activeRentals,
      pendingKycCount: pendingKyc,
      pendingDisputesCount: pendingDisputes,
      totalRevenue: totalRevenue,
      totalTransactions: totalTransactions,
      totalReviews: recentReviews.length,
      averageRating: avgLandlordRating,
      landlordAverageRating: avgLandlordRating,
      verifiedUsersCount: verifiedUsersCount,
      pendingReportsCount: pendingReports,
      totalSwipes: totalSwipes,
      totalSwapRequests: totalSwapRequests,
      activeBoostedRooms: boostedRooms,
      monthlyStats: [
        const AdminMonthlyStat(
          month: '05/2026',
          newUsers: 18,
          newRentals: 6,
          revenue: 1650000,
        ),
        const AdminMonthlyStat(
          month: '06/2026',
          newUsers: 24,
          newRentals: 9,
          revenue: 2150000,
        ),
        const AdminMonthlyStat(
          month: '07/2026',
          newUsers: 31,
          newRentals: 12,
          revenue: 2540000,
        ),
        const AdminMonthlyStat(
          month: '08/2026',
          newUsers: 39,
          newRentals: 15,
          revenue: 2890000,
        ),
        const AdminMonthlyStat(
          month: '09/2026',
          newUsers: 46,
          newRentals: 19,
          revenue: 3120000,
        ),
        AdminMonthlyStat(
          month: '10/2026',
          newUsers: 54 + totalUsers,
          newRentals: 22 + activeRentals,
          revenue: (2500000 + orderRevenue).toDouble(),
        ),
      ],
      trustScoreDistribution: const [
        AdminTrustScoreRange(
          range: '90-100 (Uy tín cao)',
          count: 42,
          percentage: 46.7,
        ),
        AdminTrustScoreRange(
          range: '70-89 (Tốt)',
          count: 31,
          percentage: 34.4,
        ),
        AdminTrustScoreRange(
          range: '50-69 (Cơ bản)',
          count: 14,
          percentage: 15.6,
        ),
        AdminTrustScoreRange(
          range: '<50 (Cần lưu ý)',
          count: 3,
          percentage: 3.3,
        ),
      ],
      ratingDistribution: ratingDist,
      recentReviews: recentReviews,
      systemFeedbacks: sysFeedbacks,
      packageStats: pkgStats,
      roomTypeDistribution: const [
        AdminCategoryStat(name: 'Studio', count: 18, percentage: 42.0),
        AdminCategoryStat(name: 'Căn hộ mini', count: 12, percentage: 28.0),
        AdminCategoryStat(name: 'Phòng đơn', count: 8, percentage: 19.0),
        AdminCategoryStat(name: 'Ở ghép / KTX', count: 5, percentage: 11.0),
      ],
      districtDistribution: const [
        AdminCategoryStat(name: 'Quận 10', count: 16, percentage: 38.0),
        AdminCategoryStat(name: 'Thủ Đức', count: 13, percentage: 31.0),
        AdminCategoryStat(name: 'Bình Thạnh', count: 8, percentage: 19.0),
        AdminCategoryStat(name: 'Quận 7', count: 5, percentage: 12.0),
      ],
      roomStatusDistribution: [
        AdminCategoryStat(
          name: 'Đang hiển thị',
          count: activeRooms,
          percentage: totalRooms == 0
              ? 0
              : (activeRooms * 100.0 / totalRooms),
        ),
        AdminCategoryStat(
          name: 'Chờ duyệt',
          count: pendingRooms,
          percentage: totalRooms == 0
              ? 0
              : (pendingRooms * 100.0 / totalRooms),
        ),
        AdminCategoryStat(
          name: 'Đã ẩn',
          count: hiddenRooms,
          percentage: totalRooms == 0 ? 0 : (hiddenRooms * 100.0 / totalRooms),
        ),
        AdminCategoryStat(
          name: 'Đã thuê',
          count: rentedRooms,
          percentage: totalRooms == 0 ? 0 : (rentedRooms * 100.0 / totalRooms),
        ),
      ],
      lifestyleStats: const [
        AdminCategoryStat(
          name: 'Không hút thuốc',
          count: 78,
          percentage: 86.5,
        ),
        AdminCategoryStat(
          name: 'Gọn gàng, sạch sẽ',
          count: 74,
          percentage: 82.0,
        ),
        AdminCategoryStat(
          name: 'Ngủ trước 23h',
          count: 61,
          percentage: 68.0,
        ),
        AdminCategoryStat(
          name: 'Cho bạn bè tới chơi',
          count: 39,
          percentage: 43.5,
        ),
      ],
      personalizationFunnel: [
        const AdminCategoryStat(
          name: 'Người thuê đăng ký',
          count: 120,
          percentage: 100.0,
        ),
        const AdminCategoryStat(
          name: 'Đã xác thực CCCD',
          count: 94,
          percentage: 78.3,
        ),
        AdminCategoryStat(
          name: 'Ghép đôi thành công',
          count: 52 + matchPairs,
          percentage: 58.3,
        ),
        AdminCategoryStat(
          name: 'Ký hợp đồng thuê',
          count: 34 + activeRentals,
          percentage: 31.0,
        ),
      ],
      districtSupplyDemand: const [
        AdminDistrictSupplyDemand(district: 'Quận 10', supply: 28, demand: 42),
        AdminDistrictSupplyDemand(district: 'Thủ Đức', supply: 34, demand: 39),
        AdminDistrictSupplyDemand(
          district: 'Bình Thạnh',
          supply: 22,
          demand: 31,
        ),
        AdminDistrictSupplyDemand(district: 'Quận 7', supply: 19, demand: 24),
        AdminDistrictSupplyDemand(district: 'Quận 3', supply: 14, demand: 21),
      ],
      kycOverview: AdminKycOverview(
        pendingCount: pendingKyc,
        approvedCount: approvedKyc,
        rejectedCount: rejectedKyc,
        approvalRate: kycApprovalRate,
      ),
    );
  }

  void _showReviewDetailDialog(
    BuildContext context,
    AppState state, {
    AdminRecentReview? landlordReview,
    AdminSystemFeedback? systemFeedback,
  }) {
    final isLandlord = landlordReview != null;
    final authorName = isLandlord
        ? landlordReview.reviewerName
        : (systemFeedback?.userName ?? 'Người dùng');
    final roleCode = isLandlord
        ? landlordReview.reviewerRole
        : (systemFeedback?.userRole ?? 'TENANT');
    final rating = isLandlord
        ? landlordReview.rating
        : (systemFeedback?.rating ?? 5);
    final comment = isLandlord
        ? landlordReview.comment
        : (systemFeedback?.comment ?? '');
    final createdAt = isLandlord
        ? landlordReview.createdAt
        : (systemFeedback?.createdAt ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isLandlord
              ? 'Chi tiết Đánh giá Chủ trọ'
              : 'Chi tiết Đánh giá Hệ thống',
          style: PT.title(16),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(authorName, style: PT.title(14)),
                  Pill(
                    roleCode == 'LANDLORD' ? 'Chủ trọ' : 'Người thuê',
                    dense: true,
                    color: roleCode == 'LANDLORD'
                        ? const Color(0xFF0799DE)
                        : PT.green,
                  ),
                  if (isLandlord && landlordReview.isVerifiedStay)
                    const Pill('Đã thuê thực tế', dense: true, color: PT.green),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      LucideIcons.star,
                      size: 14,
                      color: i <= rating ? PT.amber : PT.line,
                    ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$rating/5 sao • $createdAt',
                      style: PT.body(11, PT.muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (isLandlord)
                Text(
                  'Phòng: ${landlordReview.roomTitle} • Chủ trọ: ${landlordReview.landlordName}',
                  style: PT.body(12, PT.green).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                )
              else if (systemFeedback != null)
                Text(
                  'Danh mục: ${_formatCategoryLabel(systemFeedback.category)}',
                  style: PT.body(12, PT.green).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PT.grey.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(comment, style: PT.body(13, PT.deep)),
              ),
              if (isLandlord &&
                  landlordReview.landlordReply != null &&
                  landlordReview.landlordReply!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PT.mint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phản hồi từ Chủ trọ (${landlordReview.landlordName}):',
                        style: PT.body(11, PT.green).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        landlordReview.landlordReply!,
                        style: PT.body(12, PT.deep),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (!isLandlord && systemFeedback != null)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await state.workflows.deleteSystemFeedback(systemFeedback.id);
              },
              child: Text('Xóa phản hồi', style: PT.body(13, PT.error)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showAllReviewsModal(
    BuildContext context,
    AppState state,
    AdminDashboardData dashboard,
  ) {
    String modalScope = reviewScope;
    int? modalStar = selectedStarFilter;
    String modalRole = 'ALL';
    String modalCategory = 'ALL';
    String searchQuery = '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setModalState) {
          final isLandlord = modalScope == 'LANDLORD';
          final filteredLandlord = dashboard.recentReviews.where((r) {
            final starOk = modalStar == null || r.rating == modalStar;
            final roleOk = modalRole == 'ALL' || r.reviewerRole == modalRole;
            final q = searchQuery.trim().toLowerCase();
            final qOk =
                q.isEmpty ||
                r.reviewerName.toLowerCase().contains(q) ||
                r.landlordName.toLowerCase().contains(q) ||
                r.comment.toLowerCase().contains(q) ||
                r.roomTitle.toLowerCase().contains(q);
            return starOk && roleOk && qOk;
          }).toList();

          final filteredSystem = dashboard.systemFeedbacks.where((f) {
            final starOk = modalStar == null || f.rating == modalStar;
            final roleOk = modalRole == 'ALL' || f.userRole == modalRole;
            final catOk =
                modalCategory == 'ALL' ||
                f.category.toUpperCase() == modalCategory;
            final q = searchQuery.trim().toLowerCase();
            final qOk =
                q.isEmpty ||
                f.userName.toLowerCase().contains(q) ||
                f.comment.toLowerCase().contains(q);
            return starOk && roleOk && catOk && qOk;
          }).toList();

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.82,
            minChildSize: 0.5,
            maxChildSize: 0.94,
            builder: (_, scrollCtrl) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: ListView(
                controller: scrollCtrl,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Quản lý Đánh giá & Phản hồi Hệ thống',
                          style: PT.title(16),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        icon: const Icon(LucideIcons.x, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ChoiceChip(
                        label: Text(
                          'Đánh giá Chủ trọ (${dashboard.recentReviews.length})',
                        ),
                        selected: isLandlord,
                        onSelected: (_) =>
                            setModalState(() => modalScope = 'LANDLORD'),
                      ),
                      ChoiceChip(
                        label: Text(
                          'Phản hồi Hệ thống (${dashboard.systemFeedbacks.length})',
                        ),
                        selected: !isLandlord,
                        onSelected: (_) =>
                            setModalState(() => modalScope = 'SYSTEM'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Tìm theo tên người gửi, phòng hoặc nội dung',
                      prefixIcon: Icon(LucideIcons.search, size: 18),
                      isDense: true,
                    ),
                    onChanged: (v) => setModalState(() => searchQuery = v),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ChoiceChip(
                        label: const Text('Mọi số sao'),
                        selected: modalStar == null,
                        onSelected: (_) =>
                            setModalState(() => modalStar = null),
                      ),
                      for (final s in [5, 4, 3, 2, 1])
                        ChoiceChip(
                          label: Text('$s ★'),
                          selected: modalStar == s,
                          onSelected: (_) => setModalState(
                            () => modalStar = modalStar == s ? null : s,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final roleOpt in const [
                        ('ALL', 'Mọi vai trò'),
                        ('TENANT', 'Người thuê'),
                        ('LANDLORD', 'Chủ trọ'),
                      ])
                        ChoiceChip(
                          label: Text(roleOpt.$2),
                          selected: modalRole == roleOpt.$1,
                          onSelected: (_) =>
                              setModalState(() => modalRole = roleOpt.$1),
                        ),
                    ],
                  ),
                  if (!isLandlord) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final catOpt in const [
                          ('ALL', 'Mọi danh mục'),
                          ('GENERAL', 'Góp ý chung'),
                          ('UI_UX', 'Giao diện'),
                          ('BUG', 'Báo lỗi'),
                          ('FEATURE', 'Tính năng'),
                          ('PERFORMANCE', 'Hiệu năng'),
                        ])
                          ChoiceChip(
                            label: Text(catOpt.$2),
                            selected: modalCategory == catOpt.$1,
                            onSelected: (_) =>
                                setModalState(() => modalCategory = catOpt.$1),
                          ),
                      ],
                    ),
                  ],
                  const Divider(height: 20, color: PT.line),
                  if (isLandlord && filteredLandlord.isEmpty)
                    const EmptyState(
                      'Không có đánh giá phù hợp',
                      'Thử thay đổi bộ lọc số sao hoặc từ khóa tìm kiếm.',
                    ),
                  if (!isLandlord && filteredSystem.isEmpty)
                    const EmptyState(
                      'Không có phản hồi hệ thống phù hợp',
                      'Thử thay đổi bộ lọc danh mục hoặc từ khóa tìm kiếm.',
                    ),
                  if (isLandlord)
                    for (final item in filteredLandlord)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showReviewDetailDialog(
                            context,
                            state,
                            landlordReview: item,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: PT.card(radius: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      item.reviewerName,
                                      style: PT.title(13),
                                    ),
                                    Pill(
                                      '${item.rating} ★',
                                      dense: true,
                                      color: PT.amber,
                                    ),
                                    if (item.isVerifiedStay)
                                      const Pill(
                                        'Đã thuê thực tế',
                                        dense: true,
                                        color: PT.green,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(item.comment, style: PT.body(12, PT.deep)),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.roomTitle} • Chủ trọ: ${item.landlordName}',
                                  style: PT.body(11, PT.muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  if (!isLandlord)
                    for (final fb in filteredSystem)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: PT.card(radius: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(fb.userName, style: PT.title(13)),
                                  Pill(
                                    '${fb.rating} ★',
                                    dense: true,
                                    color: PT.amber,
                                  ),
                                  Pill(
                                    _formatCategoryLabel(fb.category),
                                    dense: true,
                                    color: PT.green,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(fb.comment, style: PT.body(12, PT.deep)),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                  onTap: () async {
                                    Navigator.pop(sheetCtx);
                                    await state.workflows.deleteSystemFeedback(
                                      fb.id,
                                    );
                                  },
                                  child: Text(
                                    'Xóa phản hồi',
                                    style: PT.body(11, PT.error).copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  TextStyle _tabular(TextStyle base) => base.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  Widget _adminSectionCard(
    String title,
    List<Widget> children, {
    String? subtitle,
    Widget? trailing,
  }) => Container(
    padding: const EdgeInsets.all(18),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: PT.line.withValues(alpha: 0.85)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A073B3C),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: PT.title(16)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(subtitle, style: PT.body(12, PT.muted)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final dashboard = _liveDashboard ?? _buildDemoDashboard(state);
        final vipCount = state.store.profiles.values
            .where((p) => p.package != 'Miễn phí')
            .length;
        final occupancyRate = dashboard.totalRooms > 0
            ? math.min(
                100,
                ((dashboard.activeRentals * 100) / dashboard.totalRooms)
                    .round(),
              )
            : 0;
        final pendingTotalActions =
            dashboard.pendingKycCount +
            dashboard.pendingDisputesCount +
            dashboard.pendingReportsCount;

        final systemFeedbacks = dashboard.systemFeedbacks;
        final avgSystemRating = systemFeedbacks.isEmpty
            ? '4.8'
            : (systemFeedbacks.fold<int>(0, (s, f) => s + f.rating) /
                      systemFeedbacks.length)
                  .toStringAsFixed(1);
        final avgLandlordRating =
            (dashboard.landlordAverageRating > 0
                    ? dashboard.landlordAverageRating
                    : dashboard.averageRating)
                .toStringAsFixed(1);

        final activeRatingDistribution = reviewScope == 'LANDLORD'
            ? dashboard.ratingDistribution
            : [
                for (final star in [5, 4, 3, 2, 1])
                  () {
                    final c = systemFeedbacks
                        .where((f) => f.rating == star)
                        .length;
                    final pct = systemFeedbacks.isEmpty
                        ? 0.0
                        : (c * 100.0 / systemFeedbacks.length);
                    return AdminRatingBreakdown(
                      star: star,
                      count: c,
                      percentage: pct,
                    );
                  }(),
              ];

        final pendingRoomsCount = state.rooms
            .where((r) => r.status == RoomStatus.pending)
            .length;

        return ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
          children: [
            Header(
              admin: true,
              unreadNotifications: state.unreadNotifications,
              onMap: () => openPage(context, AdminUsersScreen(state: state)),
              onNotifications: () =>
                  openPage(context, NotificationsScreen(state: state)),
            ),
            const SizedBox(height: 4),
            const PageHeading(
              'Quản trị viên',
              'Tổng quan hệ thống Phòng Trọ Xanh',
            ),
            const SizedBox(height: 6),

            // Executive Command Banner + Refresh Action
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [PT.deep, Color(0xFF0A524A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22073B3C),
                    blurRadius: 18,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA7F3D0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: PT.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Hệ thống ổn định 99.9%',
                              style: PT.body(11, PT.deep).copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: _refreshDashboard,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.refreshCw,
                                size: 13,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _loadingDashboard ? 'Đang tải...' : 'Làm mới',
                                style: PT.body(11.5, Colors.white).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Doanh thu hệ thống',
                    style: PT.body(
                      12,
                      Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatVnd(dashboard.totalRevenue),
                    style: _tabular(
                      PT.title(26).copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Giao dịch & gói VIP',
                              style: PT.body(
                                11,
                                Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${dashboard.totalTransactions} GD • $vipCount VIP',
                              style: _tabular(
                                PT.title(14).copyWith(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tin đẩy nổi bật',
                              style: PT.body(
                                11,
                                Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${dashboard.activeBoostedRooms} phòng đang đẩy',
                              style: _tabular(
                                PT.title(14).copyWith(
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ROW 1: 4 CORE KPI CARDS (Matching AdminOverview.tsx)
            LayoutBuilder(
              builder: (context, c) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final twoCol = c.maxWidth >= 320 && textScale <= 1.35;
                final cardWidth = twoCol ? (c.maxWidth - 12) / 2 : c.maxWidth;
                final kpiCards = [
                  (
                    title: 'Người dùng hệ thống',
                    value: '${dashboard.totalUsers}',
                    badge: '${dashboard.verifiedUsersCount} đã KYC',
                    subLeft: '${dashboard.totalTenants} người thuê',
                    subRight: '${dashboard.totalLandlords} chủ trọ',
                    icon: LucideIcons.users,
                    color: PT.green,
                    bg: PT.mint,
                    onTap: () =>
                        openPage(context, AdminUsersScreen(state: state)),
                  ),
                  (
                    title: 'Nguồn cung phòng trọ',
                    value: '${dashboard.totalRooms}',
                    badge: 'Lấp đầy $occupancyRate%',
                    subLeft: '${dashboard.activeRooms} phòng trống',
                    subRight: '${dashboard.totalRentals} hợp đồng',
                    icon: LucideIcons.building2,
                    color: const Color(0xFF0799DE),
                    bg: const Color(0xFFEEF8FF),
                    onTap: () =>
                        openPage(context, AdminRoomsScreen(state: state)),
                  ),
                  (
                    title: 'Ghép đôi & Cá nhân hóa',
                    value: '${dashboard.totalMatches}',
                    badge: 'Lifestyle Match',
                    subLeft: '${dashboard.totalSwipes} lượt quẹt',
                    subRight: '${dashboard.totalSwapRequests} pass phòng',
                    icon: LucideIcons.sparkles,
                    color: const Color(0xFF7C3AED),
                    bg: const Color(0xFFF5F3FF),
                    onTap: () => setState(() => analyticsTab = 1),
                  ),
                  (
                    title: 'Hàng đợi Kiểm duyệt',
                    value: '$pendingTotalActions',
                    badge: pendingTotalActions > 0 ? 'Cần xử lý' : 'An toàn',
                    subLeft: '${dashboard.pendingKycCount} CCCD',
                    subRight:
                        '${dashboard.pendingDisputesCount} KN • ${dashboard.pendingReportsCount} BC',
                    icon: LucideIcons.shieldAlert,
                    color: pendingTotalActions > 0 ? PT.amber : PT.green,
                    bg: pendingTotalActions > 0
                        ? const Color(0xFFFFF8ED)
                        : PT.mint,
                    onTap: () =>
                        openPage(context, AdminQueueScreen(state: state)),
                  ),
                ];

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final kpi in kpiCards)
                      SizedBox(
                        width: cardWidth,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: kpi.onTap,
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: PT.line.withValues(alpha: 0.85),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0A073B3C),
                                  blurRadius: 14,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: kpi.bg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        kpi.icon,
                                        size: 17,
                                        color: kpi.color,
                                      ),
                                    ),
                                    Pill(
                                      kpi.badge,
                                      dense: true,
                                      color: kpi.color,
                                      bg: kpi.bg,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  kpi.value,
                                  style: _tabular(
                                    PT.title(22).copyWith(color: kpi.color),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  kpi.title,
                                  style: PT.title(13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${kpi.subLeft} • ${kpi.subRight}',
                                  style: PT.body(11.5, PT.muted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // QUICK OPERATIONS GROUPED CARD (Full-width rows -> zero truncation, zero box soup)
            _adminSectionCard(
              'Tác vụ kiểm duyệt & vận hành',
              [
                for (final (idx, action) in [
                  (
                    icon: LucideIcons.fileCheck,
                    title: 'Duyệt CCCD',
                    subtitle: 'Xác thực hồ sơ định danh eKYC',
                    badge: '${dashboard.pendingKycCount} chờ duyệt',
                    color: PT.green,
                    bg: PT.mint,
                    onTap: () =>
                        openPage(context, AdminQueueScreen(state: state)),
                  ),
                  (
                    icon: LucideIcons.house,
                    title: 'Duyệt tin phòng',
                    subtitle: 'Kiểm duyệt tin đăng và hình ảnh thực tế',
                    badge: '$pendingRoomsCount chờ duyệt',
                    color: const Color(0xFF0799DE),
                    bg: const Color(0xFFEEF8FF),
                    onTap: () =>
                        openPage(context, AdminRoomsScreen(state: state)),
                  ),
                  (
                    icon: LucideIcons.flag,
                    title: 'Báo cáo vi phạm',
                    subtitle: 'Xử lý nội dung xấu và tài khoản vi phạm',
                    badge: '${dashboard.pendingReportsCount} báo cáo',
                    color: PT.amber,
                    bg: const Color(0xFFFFF8ED),
                    onTap: () =>
                        openPage(context, AdminReportsScreen(state: state)),
                  ),
                  (
                    icon: LucideIcons.users,
                    title: 'Quản lý người dùng',
                    subtitle: 'Phân quyền, khóa hoặc khôi phục tài khoản',
                    badge: '${dashboard.totalUsers} tài khoản',
                    color: PT.green,
                    bg: PT.mint,
                    onTap: () =>
                        openPage(context, AdminUsersScreen(state: state)),
                  ),
                  (
                    icon: LucideIcons.package,
                    title: 'Quản lý gói dịch vụ',
                    subtitle: 'Cấu hình bảng giá và quyền lợi gói VIP',
                    badge: '${state.store.plans.length} gói VIP',
                    color: const Color(0xFF7C3AED),
                    bg: const Color(0xFFF5F3FF),
                    onTap: () =>
                        openPage(context, AdminPackagesScreen(state: state)),
                  ),
                  (
                    icon: LucideIcons.scale,
                    title: 'Khiếu nại & Nhật ký hệ thống',
                    subtitle: 'Giải quyết tranh chấp đánh giá và audit log',
                    badge: '${dashboard.pendingDisputesCount} khiếu nại',
                    color: PT.deep,
                    bg: PT.grey,
                    onTap: () =>
                        openPage(context, AdminDisputesScreen(state: state)),
                  ),
                ].indexed) ...[
                  if (idx > 0)
                    Divider(
                      height: 18,
                      thickness: 1,
                      color: PT.line.withValues(alpha: 0.65),
                    ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: action.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: action.bg,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              action.icon,
                              size: 18,
                              color: action.color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  action.title,
                                  style: PT.title(13.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  action.subtitle,
                                  style: PT.body(11.5, PT.muted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Pill(
                            action.badge,
                            dense: true,
                            color: action.color,
                            bg: action.bg,
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: PT.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
              subtitle: 'Truy cập nhanh các phân hệ quản trị trọng yếu',
            ),

            // ROW 2: 3 PRIORITY BENTO CARDS (Traffic, Transactions & Packages, Reviews & System Feedback)
            // Bento 1: Nguồn truy cập (Traffic Sources)
            _adminSectionCard(
              'Nguồn truy cập (Traffic Sources)',
              [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5FAF8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PT.line.withValues(alpha: 0.7)),
                  ),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 74,
                        height: 74,
                        child: CustomPaint(
                          painter: const _TrafficDonutPainter(),
                          child: Center(
                            child: Text(
                              '100%',
                              style: _tabular(
                                PT.title(12).copyWith(color: PT.deep),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${math.max(120, dashboard.totalUsers * 18)} phiên truy cập',
                            style: _tabular(
                              PT.title(15).copyWith(color: PT.green),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Phân bổ lưu lượng đa kênh 30 ngày qua',
                            style: PT.body(12, PT.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final src in const [
                  ('Truy cập trực tiếp (Direct)', 42, PT.green),
                  ('Tìm kiếm tự nhiên (Organic)', 31, Color(0xFF0799DE)),
                  ('Mạng xã hội (Social)', 18, Color(0xFF7C3AED)),
                  ('Giới thiệu (Referral)', 9, PT.amber),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                src.$1,
                                style: PT.body(12.5, PT.deep).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${src.$2}%',
                              style: _tabular(
                                PT.body(12.5, src.$3).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: src.$2 / 100.0,
                            minHeight: 7,
                            backgroundColor: PT.grey,
                            color: src.$3,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Bento 2: Giao dịch Thanh toán & Doanh thu theo Gói dịch vụ
            _adminSectionCard(
              'Giao dịch & Doanh thu Gói dịch vụ',
              [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Pill(
                      'Tổng: ${_formatVnd(dashboard.totalRevenue)} (${dashboard.totalTransactions} GD)',
                      dense: true,
                      color: PT.green,
                      bg: PT.mint,
                    ),
                    Pill(
                      'HĐ hiệu lực: ${dashboard.activeRentals}/${dashboard.totalRentals}',
                      dense: true,
                      color: const Color(0xFF0799DE),
                      bg: const Color(0xFFEEF8FF),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final pkg in dashboard.packageStats)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${pkg.planName} (${pkg.count} lượt)',
                                style: PT.body(12.5, PT.deep).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatVnd(pkg.revenue),
                              style: _tabular(
                                PT.body(12.5, PT.green).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: dashboard.totalRevenue <= 0
                                ? 0.0
                                : (pkg.revenue / dashboard.totalRevenue).clamp(
                                    0.05,
                                    1.0,
                                  ),
                            minHeight: 7,
                            backgroundColor: PT.grey,
                            color: PT.green,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              trailing: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () =>
                    openPage(context, AdminDisputesScreen(state: state)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Text(
                    'Xem lịch sử →',
                    style: PT.body(12, PT.green).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

            // Bento 3: Đánh giá & Mức độ hài lòng (Chủ trọ vs Hệ thống)
            _adminSectionCard(
              'Đánh giá & Mức độ hài lòng',
              [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ChoiceChip(
                      label: Text('Chủ trọ (${dashboard.recentReviews.length})'),
                      selected: reviewScope == 'LANDLORD',
                      onSelected: (_) => setState(() {
                        reviewScope = 'LANDLORD';
                        selectedStarFilter = null;
                      }),
                    ),
                    ChoiceChip(
                      label: Text('Hệ thống (${systemFeedbacks.length})'),
                      selected: reviewScope == 'SYSTEM',
                      onSelected: (_) => setState(() {
                        reviewScope = 'SYSTEM';
                        selectedStarFilter = null;
                      }),
                    ),
                    Pill(
                      reviewScope == 'LANDLORD'
                          ? '$avgLandlordRating / 5 ★'
                          : '$avgSystemRating / 5 ★',
                      dense: true,
                      color: PT.amber,
                      bg: const Color(0xFFFFF8ED),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (final item in activeRatingDistribution)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(
                        () => selectedStarFilter =
                            selectedStarFilter == item.star ? null : item.star,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${item.star} ★',
                                style: _tabular(
                                  PT
                                      .body(
                                        12,
                                        selectedStarFilter == item.star
                                            ? PT.amber
                                            : PT.deep,
                                      )
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: (item.percentage / 100.0).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  minHeight: 7,
                                  backgroundColor: PT.grey,
                                  color: selectedStarFilter == item.star
                                      ? PT.green
                                      : PT.amber,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 30,
                              child: Text(
                                '${item.count}',
                                textAlign: TextAlign.right,
                                style: _tabular(PT.body(12, PT.muted)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                if (reviewScope == 'LANDLORD')
                  for (final rev
                      in dashboard.recentReviews
                          .where(
                            (r) =>
                                selectedStarFilter == null ||
                                r.rating == selectedStarFilter,
                          )
                          .take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showReviewDetailDialog(
                          context,
                          state,
                          landlordReview: rev,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F9F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: PT.line.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    rev.reviewerName,
                                    style: PT.body(12.5, PT.deep).copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${rev.rating}★',
                                    style: PT.body(11.5, PT.amber).copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (rev.isVerifiedStay)
                                    Text(
                                      '• Đã thuê thực tế',
                                      style: PT.body(11, PT.green).copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rev.comment,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: PT.body(12, PT.deep),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                if (reviewScope == 'SYSTEM')
                  for (final fb
                      in systemFeedbacks
                          .where(
                            (f) =>
                                selectedStarFilter == null ||
                                f.rating == selectedStarFilter,
                          )
                          .take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showReviewDetailDialog(
                          context,
                          state,
                          systemFeedback: fb,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: PT.mint.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: PT.green.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    '${fb.userName} • ${fb.rating}★',
                                    style: PT.body(12.5, PT.deep).copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => state.workflows
                                        .deleteSystemFeedback(fb.id),
                                    child: Text(
                                      'Xóa phản hồi',
                                      style: PT.body(11.5, PT.error).copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fb.comment,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: PT.body(12, PT.deep),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        _showAllReviewsModal(context, state, dashboard),
                    icon: const Icon(LucideIcons.listFilter, size: 15),
                    label: const Text('Xem & Lọc tất cả'),
                  ),
                ),
              ],
            ),

            // ROW 3: 3 DEEP-DIVE ANALYTICS TABS (Matching AdminOverview.tsx)
            Container(
              padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: PT.grey,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: PT.line.withValues(alpha: 0.8)),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: Material(
                        color: analyticsTab == i
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        elevation: analyticsTab == i ? 1 : 0,
                        shadowColor: const Color(0x14073B3C),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(11),
                          onTap: () => setState(() => analyticsTab = i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 6,
                            ),
                            child: Text(
                              const [
                                'Tăng trưởng & Chuyển đổi',
                                'Cá nhân hóa & Uy tín',
                                'Cung - Cầu & Phòng trọ',
                              ][i],
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PT
                                  .body(
                                    11.5,
                                    analyticsTab == i ? PT.green : PT.muted,
                                  )
                                  .copyWith(
                                    fontWeight: analyticsTab == i
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // TAB 0: TĂNG TRƯỞNG & PHỄU CHUYỂN ĐỔI
            if (analyticsTab == 0) ...[
              RepaintBoundary(
                child: _adminSectionCard(
                  'Biểu đồ Tăng trưởng Hệ thống (6 tháng)',
                  [
                    Builder(
                      builder: (context) {
                        final stats = dashboard.monthlyStats;
                        final maxUsers = stats.isEmpty
                            ? 1
                            : stats
                                  .map((s) => s.newUsers)
                                  .reduce(math.max)
                                  .clamp(1, 999999);
                        final maxRentals = stats.isEmpty
                            ? 1
                            : stats
                                  .map((s) => s.newRentals)
                                  .reduce(math.max)
                                  .clamp(1, 999999);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6FAF8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: PT.line.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (final m in stats)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: 64,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                child: FractionallySizedBox(
                                                  heightFactor:
                                                      (m.newUsers / maxUsers)
                                                          .clamp(0.15, 1.0),
                                                  child: Container(
                                                    width: 8,
                                                    decoration: BoxDecoration(
                                                      color: PT.green,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              Flexible(
                                                child: FractionallySizedBox(
                                                  heightFactor:
                                                      (m.newRentals /
                                                              maxRentals)
                                                          .clamp(0.15, 1.0),
                                                  child: Container(
                                                    width: 8,
                                                    decoration: BoxDecoration(
                                                      color: PT.amber,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          m.month.length >= 2
                                              ? m.month.substring(0, 2)
                                              : m.month,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: _tabular(
                                            PT.body(11, PT.muted),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        Text(
                          '● Người dùng mới',
                          style: PT.body(11.5, PT.green).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '● Hợp đồng thuê',
                          style: PT.body(11.5, PT.amber).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _adminSectionCard(
                'Phễu Chuyển đổi Thuê trọ & Ghép bạn',
                [
                  for (var i = 0; i < dashboard.personalizationFunnel.length; i++)
                    Builder(
                      builder: (context) {
                        final step = dashboard.personalizationFunnel[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${i + 1}. ${step.name}',
                                      style: PT.body(12.5, PT.deep).copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${step.count} (${step.percentage.toStringAsFixed(0)}%)',
                                    style: _tabular(
                                      PT.body(12.5, PT.green).copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: (step.percentage / 100.0).clamp(
                                    0.05,
                                    1.0,
                                  ),
                                  minHeight: 7,
                                  backgroundColor: PT.grey,
                                  color: PT.green,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Pill(
                        'Lượt quẹt: ${dashboard.totalSwipes}',
                        dense: true,
                        color: const Color(0xFF7C3AED),
                      ),
                      Pill(
                        'Ghép đôi: ${dashboard.totalMatches}',
                        dense: true,
                        color: PT.green,
                      ),
                      Pill(
                        'Pass phòng: ${dashboard.totalSwapRequests}',
                        dense: true,
                        color: PT.amber,
                      ),
                    ],
                  ),
                ],
              ),
            ],

            // TAB 1: CÁ NHÂN HÓA & UY TÍN (Radar 4 tiêu chí lối sống + TrustScore + eKYC)
            if (analyticsTab == 1) ...[
              _adminSectionCard(
                'Xu hướng 4 Tiêu chí Lối sống (Lifestyle Match)',
                [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.16),
                      ),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 76,
                          height: 76,
                          child: CustomPaint(
                            painter: _LifestyleRadarPainter(
                              values: dashboard.lifestyleStats
                                  .take(4)
                                  .map(
                                    (s) =>
                                        (s.percentage / 100.0).clamp(0.1, 1.0),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${dashboard.totalMatches} cặp ghép đôi tương thích',
                              style: _tabular(
                                PT.title(15).copyWith(
                                  color: const Color(0xFF7C3AED),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Tỷ lệ ưu tiên theo khảo sát lối sống người thuê',
                              style: PT.body(12, PT.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final item in dashboard.lifestyleStats)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              Text(
                                item.name,
                                style: PT.body(12.5, PT.deep).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${item.count} (${item.percentage.toStringAsFixed(0)}%)',
                                style: _tabular(
                                  PT
                                      .body(12.5, const Color(0xFF7C3AED))
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: (item.percentage / 100.0).clamp(0.05, 1.0),
                              minHeight: 7,
                              backgroundColor: PT.grey,
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              _adminSectionCard(
                'Phân bố Điểm uy tín (TrustScore) & Kiểm duyệt CCCD',
                [
                  for (final ts in dashboard.trustScoreDistribution)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              Text(
                                ts.range,
                                style: PT.body(12.5, PT.deep).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${ts.count} (${ts.percentage.toStringAsFixed(1)}%)',
                                style: _tabular(
                                  PT.body(12.5, PT.green).copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: (ts.percentage / 100.0).clamp(0.04, 1.0),
                              minHeight: 7,
                              backgroundColor: PT.grey,
                              color: PT.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Pill(
                        'Tỷ lệ duyệt KYC: ${dashboard.kycOverview.approvalRate.toStringAsFixed(1)}%',
                        dense: true,
                        color: PT.green,
                      ),
                      Pill(
                        'Đã duyệt: ${dashboard.kycOverview.approvedCount}',
                        dense: true,
                        color: PT.green,
                      ),
                      Pill(
                        'Chờ duyệt: ${dashboard.kycOverview.pendingCount}',
                        dense: true,
                        color: PT.amber,
                      ),
                      Pill(
                        'Từ chối: ${dashboard.kycOverview.rejectedCount}',
                        dense: true,
                        color: PT.error,
                      ),
                    ],
                  ),
                ],
              ),
            ],

            // TAB 2: CUNG - CẦU KHU VỰC & PHÂN BỔ PHÒNG TRỌ
            if (analyticsTab == 2) ...[
              _adminSectionCard(
                'Tương quan Cung - Cầu theo Khu vực',
                [
                  for (final d in dashboard.districtSupplyDemand)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                d.district,
                                style: PT.body(12.5, PT.deep).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Cung: ${d.supply} • Cầu: ${d.demand}',
                                style: _tabular(PT.body(11.5, PT.muted)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                flex: math.max(1, d.supply),
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: PT.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: math.max(1, d.demand),
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0799DE),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      Text(
                        '● Nguồn cung (Phòng trống)',
                        style: PT.body(11.5, PT.green).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '● Nhu cầu (Tìm kiếm)',
                        style: PT.body(11.5, const Color(0xFF0799DE)).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _adminSectionCard(
                'Loại hình & Trạng thái Phòng trọ ($avgSystemRating/5)',
                [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final rt in dashboard.roomTypeDistribution)
                        Pill(
                          '${rt.name}: ${rt.count} (${rt.percentage.toStringAsFixed(0)}%)',
                          dense: true,
                          color: PT.green,
                          bg: PT.mint,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final rs in dashboard.roomStatusDistribution)
                        Pill(
                          '${rs.name}: ${rs.count}',
                          dense: true,
                          color: const Color(0xFF0799DE),
                          bg: const Color(0xFFEEF8FF),
                        ),
                    ],
                  ),
                ],
              ),
            ],

            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: PrimaryButton(
                'Đăng xuất',
                outline: true,
                onTap: () => AppScope.maybeOf(context)?.logout(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrafficDonutPainter extends CustomPainter {
  const _TrafficDonutPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const segments = [
      (0.42, PT.green),
      (0.31, Color(0xFF0799DE)),
      (0.18, Color(0xFF7C3AED)),
      (0.09, PT.amber),
    ];
    var startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweep = seg.$1 * 2 * math.pi;
      final paint = Paint()
        ..color = seg.$2
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep - 0.05, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LifestyleRadarPainter extends CustomPainter {
  final List<double> values;
  const _LifestyleRadarPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) / 2 - 6;
    final gridPaint = Paint()
      ..color = PT.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final factor in [0.35, 0.7, 1.0]) {
      canvas.drawCircle(center, maxR * factor, gridPaint);
    }
    for (var i = 0; i < 4; i++) {
      final angle = -math.pi / 2 + i * (math.pi / 2);
      final p = Offset(
        center.dx + maxR * math.cos(angle),
        center.dy + maxR * math.sin(angle),
      );
      canvas.drawLine(center, p, gridPaint);
    }

    final pts = <Offset>[];
    for (var i = 0; i < 4; i++) {
      final v = i < values.length ? values[i] : 0.7;
      final angle = -math.pi / 2 + i * (math.pi / 2);
      pts.add(
        Offset(
          center.dx + maxR * v * math.cos(angle),
          center.dy + maxR * v * math.sin(angle),
        ),
      );
    }
    final poly = Path()..addPolygon(pts, true);
    canvas.drawPath(
      poly,
      Paint()
        ..color = const Color(0xFF7C3AED).withValues(alpha: 0.24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      poly,
      Paint()
        ..color = const Color(0xFF7C3AED)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _LifestyleRadarPainter oldDelegate) =>
      oldDelegate.values != values;
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
