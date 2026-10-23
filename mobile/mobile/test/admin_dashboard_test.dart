import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phong_tro_xanh_mobile/api/http_admin_repository.dart';
import 'package:phong_tro_xanh_mobile/app/app.dart';
import 'package:phong_tro_xanh_mobile/app/app_state.dart';
import 'package:phong_tro_xanh_mobile/domain/models.dart';
import 'package:phong_tro_xanh_mobile/mock/auth_repository.dart';
import 'package:phong_tro_xanh_mobile/mock/transport.dart';

AppState adminDemoState() => AppState(
  role: UserRole.admin,
  transport: DemoTransport(delay: Duration.zero),
  auth: DemoAuthRepository(transport: DemoTransport(delay: Duration.zero)),
);

void main() {
  test(
    'AdminDashboardData.fromJson parses all 20 scalar fields and 13 analytical collections from Backend AdminDashboardResponse',
    () {
      final sampleJson = <String, dynamic>{
        'totalUsers': 120,
        'totalLandlords': 35,
        'totalTenants': 85,
        'totalRooms': 64,
        'activeRooms': 42,
        'totalMatches': 28,
        'totalRentals': 31,
        'activeRentals': 24,
        'pendingKycCount': 4,
        'pendingDisputesCount': 2,
        'totalRevenue': 18450000.0,
        'totalTransactions': 39,
        'totalReviews': 19,
        'averageRating': 4.7,
        'landlordAverageRating': 4.8,
        'verifiedUsersCount': 92,
        'pendingReportsCount': 3,
        'totalSwipes': 640,
        'totalSwapRequests': 9,
        'activeBoostedRooms': 11,
        'monthlyStats': [
          {
            'month': '09/2026',
            'newUsers': 46,
            'newRentals': 19,
            'revenue': 3120000,
          },
          {
            'month': '10/2026',
            'newUsers': 58,
            'newRentals': 24,
            'revenue': 4250000,
          },
        ],
        'trustScoreDistribution': [
          {'range': '90-100', 'count': 42, 'percentage': 46.7},
          {'range': '70-89', 'count': 31, 'percentage': 34.4},
        ],
        'ratingDistribution': [
          {'star': 5, 'count': 15, 'percentage': 78.9},
          {'star': 4, 'count': 4, 'percentage': 21.1},
        ],
        'recentReviews': [
          {
            'id': 'rev-1',
            'reviewerName': 'Nguyễn Hoài An',
            'reviewerRole': 'TENANT',
            'landlordName': 'Cô Hồng',
            'isVerifiedStay': true,
            'rating': 5,
            'comment': 'Phòng rất sạch sẽ',
            'landlordReply': 'Cảm ơn cháu',
            'repliedAt': '2026-10-15',
            'roomTitle': 'Studio xanh gần Bách Khoa',
            'createdAt': '2026-10-14',
          },
        ],
        'systemFeedbacks': [
          {
            'id': 'sfb-1',
            'userId': 'u-1',
            'userName': 'Lê Thu Hà',
            'userRole': 'TENANT',
            'rating': 5,
            'category': 'UI_UX',
            'comment': 'Giao diện mượt mà',
            'createdAt': '2026-10-15',
          },
        ],
        'packageStats': [
          {
            'planId': 'LANDLORD_PRO',
            'planName': 'Gói Chủ Trọ Chuyên Nghiệp',
            'revenue': 6450000,
            'count': 11,
          },
        ],
        'roomTypeDistribution': [
          {'name': 'Studio', 'count': 18, 'percentage': 42.0},
        ],
        'districtDistribution': [
          {'name': 'Quận 10', 'count': 16, 'percentage': 38.0},
        ],
        'roomStatusDistribution': [
          {'name': 'AVAILABLE', 'count': 42, 'percentage': 65.6},
        ],
        'lifestyleStats': [
          {'name': 'Không hút thuốc', 'count': 78, 'percentage': 86.5},
        ],
        'personalizationFunnel': [
          {'name': 'Người thuê đăng ký', 'count': 120, 'percentage': 100.0},
          {'name': 'Đã xác thực CCCD', 'count': 92, 'percentage': 76.7},
        ],
        'districtSupplyDemand': [
          {'district': 'Quận 10', 'supply': 28, 'demand': 42},
        ],
        'kycOverview': {
          'pendingCount': 4,
          'approvedCount': 92,
          'rejectedCount': 5,
          'approvalRate': 94.8,
        },
      };

      final data = AdminDashboardData.fromJson(sampleJson);
      expect(data.totalUsers, 120);
      expect(data.totalLandlords, 35);
      expect(data.totalTenants, 85);
      expect(data.totalRooms, 64);
      expect(data.activeRooms, 42);
      expect(data.totalMatches, 28);
      expect(data.totalRentals, 31);
      expect(data.activeRentals, 24);
      expect(data.pendingKycCount, 4);
      expect(data.pendingDisputesCount, 2);
      expect(data.totalRevenue, 18450000.0);
      expect(data.totalTransactions, 39);
      expect(data.totalReviews, 19);
      expect(data.averageRating, 4.7);
      expect(data.landlordAverageRating, 4.8);
      expect(data.verifiedUsersCount, 92);
      expect(data.pendingReportsCount, 3);
      expect(data.totalSwipes, 640);
      expect(data.totalSwapRequests, 9);
      expect(data.activeBoostedRooms, 11);
      expect(data.monthlyStats.length, 2);
      expect(data.monthlyStats.last.month, '10/2026');
      expect(data.trustScoreDistribution.first.range, '90-100');
      expect(data.ratingDistribution.first.star, 5);
      expect(data.recentReviews.single.isVerifiedStay, isTrue);
      expect(data.recentReviews.single.landlordReply, 'Cảm ơn cháu');
      expect(data.systemFeedbacks.single.category, 'UI_UX');
      expect(data.packageStats.single.planId, 'LANDLORD_PRO');
      expect(data.roomTypeDistribution.single.name, 'Studio');
      expect(data.districtDistribution.single.name, 'Quận 10');
      expect(data.roomStatusDistribution.single.count, 42);
      expect(data.lifestyleStats.single.name, 'Không hút thuốc');
      expect(data.personalizationFunnel.length, 2);
      expect(data.districtSupplyDemand.single.demand, 42);
      expect(data.kycOverview.approvalRate, 94.8);
    },
  );

  test(
    'HttpAdminRepository calls dashboard, user governance, disputes, transactions, audit logs and feedback endpoints',
    () async {
      final requestedPaths = <String>[];
      final mockClient = MockClient((request) async {
        requestedPaths.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/admin/dashboard')) {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'success': true,
                'data': {
                  'totalUsers': 50,
                  'totalLandlords': 15,
                  'totalTenants': 35,
                  'totalRooms': 30,
                  'activeRooms': 22,
                  'pendingKycCount': 2,
                  'pendingDisputesCount': 1,
                  'totalRevenue': 9500000,
                  'totalMatches': 14,
                },
              }),
            ),
            200,
          );
        }
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'success': true,
              'data': {
                'content': [
                  {'id': 'item-1'},
                ],
              },
            }),
          ),
          200,
        );
      });

      final repo = HttpAdminRepository(
        baseUrl: 'http://localhost:8080/api/v1',
        client: mockClient,
        tokenProvider: () => 'test-jwt-token',
      );

      expect(repo.hasAuthToken, isTrue);
      final dash = await repo.getDashboard();
      expect(dash.totalUsers, 50);
      expect(dash.totalRevenue, 9500000);

      await repo.resetUserPassword('u-1');
      await repo.notifyUser('u-1', title: 'Tiêu đề', message: 'Nội dung');
      final disputes = await repo.getDisputes();
      expect(disputes.length, 1);
      await repo.resolveDispute(
        'd-1',
        status: 'RESOLVED',
        adminNotes: 'Đã kiểm tra',
      );
      final txs = await repo.getTransactions();
      expect(txs.length, 1);
      final logs = await repo.getAuditLogs();
      expect(logs.length, 1);
      await repo.deleteSystemFeedback('fb-1');

      expect(
        requestedPaths,
        containsAll([
          'GET /api/v1/admin/dashboard',
          'POST /api/v1/admin/users/u-1/reset-password',
          'POST /api/v1/admin/users/u-1/notify',
          'GET /api/v1/admin/reviews/disputes',
          'POST /api/v1/admin/reviews/disputes/d-1/resolve',
          'GET /api/v1/admin/transactions',
          'GET /api/v1/admin/audit-logs',
          'DELETE /api/v1/reviews/system-feedback/fb-1',
        ]),
      );
    },
  );

  testWidgets(
    'AdminScreen renders 4 KPI cards, 3 Priority Bento cards, Review filter modal, and 3 Deep-Dive Analytics Tabs without overflow at 320px/1.6x scale',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = adminDemoState();
      addTearDown(state.dispose);

      await tester.pumpWidget(
        PhongTroXanhApp(state: state, initialScreen: 'admin'),
      );
      await tester.pumpAndSettle();

      // Verify 4 KPI cards & Quick Actions
      expect(find.text('Quản trị viên'), findsOneWidget);
      expect(find.text('Người dùng hệ thống'), findsOneWidget);
      expect(find.text('Nguồn cung phòng trọ'), findsOneWidget);
      expect(find.text('Ghép đôi & Cá nhân hóa'), findsOneWidget);
      expect(find.text('Hàng đợi Kiểm duyệt'), findsOneWidget);
      expect(find.text('Duyệt CCCD'), findsWidgets);

      // Verify 3 Priority Bento Cards
      await tester.scrollUntilVisible(
        find.text('Nguồn truy cập (Traffic Sources)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Nguồn truy cập (Traffic Sources)'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Giao dịch & Doanh thu Gói dịch vụ'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Giao dịch & Doanh thu Gói dịch vụ'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Đánh giá & Mức độ hài lòng'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Đánh giá & Mức độ hài lòng'), findsOneWidget);

      // Open Review & System Feedback Filter Modal
      await tester.scrollUntilVisible(
        find.text('Xem & Lọc tất cả'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Xem & Lọc tất cả'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem & Lọc tất cả'));
      await tester.pumpAndSettle();
      expect(
        find.text('Quản lý Đánh giá & Phản hồi Hệ thống'),
        findsOneWidget,
      );
      await tester.tap(find.byIcon( Icons.close ).evaluate().isNotEmpty
          ? find.byIcon(Icons.close)
          : find.byType(IconButton).first);
      await tester.pumpAndSettle();

      // Verify 3 Deep-Dive Analytics Tabs
      await tester.scrollUntilVisible(
        find.text('Phễu Chuyển đổi Thuê trọ & Ghép bạn'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Biểu đồ Tăng trưởng Hệ thống (6 tháng)'),
        findsOneWidget,
      );
      expect(
        find.text('Phễu Chuyển đổi Thuê trọ & Ghép bạn'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Cá nhân hóa & Uy tín'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cá nhân hóa & Uy tín'));
      await tester.pumpAndSettle();
      expect(
        find.text('Xu hướng 4 Tiêu chí Lối sống (Lifestyle Match)'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Cung - Cầu & Phòng trọ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cung - Cầu & Phòng trọ'));
      await tester.pumpAndSettle();
      expect(find.text('Tương quan Cung - Cầu theo Khu vực'), findsOneWidget);

      // Test narrow phone 320px + 1.6x text scale + landscape 812x375
      tester.view.physicalSize = const Size(320, 740);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(812, 375);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
