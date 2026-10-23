import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phong_tro_xanh_mobile/app/app_state.dart';
import 'package:phong_tro_xanh_mobile/app/navigation.dart';
import 'package:phong_tro_xanh_mobile/core/async_resource.dart';
import 'package:phong_tro_xanh_mobile/core/flow_page.dart';
import 'package:phong_tro_xanh_mobile/core/theme.dart';
import 'package:phong_tro_xanh_mobile/demo/models.dart';
import 'package:phong_tro_xanh_mobile/demo/workflow_models.dart';
import 'package:phong_tro_xanh_mobile/features/account/account_screens.dart';
import 'package:phong_tro_xanh_mobile/features/admin/admin_screens.dart';
import 'package:phong_tro_xanh_mobile/features/landlord/landlord_screens.dart';
import 'package:phong_tro_xanh_mobile/features/rentals/rental_screens.dart';
import 'package:phong_tro_xanh_mobile/features/auth/auth_screens.dart';
import 'package:phong_tro_xanh_mobile/core/reference_photo.dart';

AppState demo([UserRole role = UserRole.tenant]) => AppState(
  role: role,
  transport: DemoTransport(delay: Duration.zero),
);
final denied = throwsA(isA<RepositoryFailure>());

void main() {
  test(
    'Paid swipes stay unlimited without undo inflation, then expire',
    () async {
      final s = demo();
      addTearDown(s.dispose);
      final order = await s.workflows.checkout(
        ServicePlan.catalog.first,
        false,
        'MoMo',
      );
      await s.workflows.paymentResult(order.id, 'Thành công');
      s.roomQuota = 0;
      s.roommateQuota = 0;
      expect(s.unlimitedSwipes, isTrue);
      expect(s.swipe(person: false, like: true), isTrue);
      expect(s.swipe(person: true, like: true), isTrue);
      s.undo(false);
      s.undo(true);
      expect(s.roomQuota, 0);
      expect(s.roommateQuota, 0);
      s.store.profiles[s.userId]!.packageExpiry = DateTime.now().subtract(
        const Duration(seconds: 1),
      );
      expect(s.unlimitedSwipes, isFalse);
      expect(s.swipe(person: false, like: true), isFalse);
      expect(s.swipe(person: true, like: true), isFalse);
    },
  );
  test('Gold grants bonuses once and enables incoming like-back; Super Match targets a profile', () async {
    final s = demo();
    addTearDown(s.dispose);
    await expectLater(s.workflows.confirmMatch('p1', likeBack: true), denied);
    final order = await s.workflows.checkout(
      ServicePlan.catalog.firstWhere((p) => p.id == 'gold'),
      false,
      'MoMo',
    );
    await s.workflows.paymentResult(order.id, 'Thành công');
    await s.workflows.paymentResult(order.id, 'Thành công');
    final p = s.store.profiles[s.userId]!;
    expect(p.boosts, 1);
    expect(p.superMatches, 5);
    await s.workflows.confirmMatch('p1', likeBack: true);
    expect(s.store.matches[s.userId], contains('p1'));
    await expectLater(s.workflows.consume('SUPER', null), denied);
    await s.workflows.consume('SUPER', 'p2');
    expect(p.superMatches, 4);
    expect(p.priorityPeople, contains('p2'));
    expect(s.liked, contains('p2'));
    expect(s.store.matches[s.userId], isNot(contains('p2')));
    await expectLater(s.workflows.consume('SUPER', 'p2'), denied);
    expect(p.superMatches, 4);
    await s.workflows.consume('BOOST', null);
    expect(p.boostedAt, isNotNull);
    await expectLater(s.workflows.confirmMatch('p2', likeBack: true), denied);
  });
  test(
    'A store blocked before opening a session can later be unblocked',
    () async {
      final admin = demo(UserRole.admin);
      addTearDown(admin.dispose);
      await admin.workflows.userStatus('owner-b', true, 'Kiểm tra');
      final another = AppState(
        store: admin.store,
        transport: DemoTransport(delay: Duration.zero),
      );
      addTearDown(another.dispose);
      expect(
        await another.authenticate('landlord2@demo.vn', 'demo123'),
        isFalse,
      );
      await admin.workflows.userStatus('owner-b', false, 'Đã xử lý');
      expect(
        await another.authenticate('landlord2@demo.vn', 'demo123'),
        isTrue,
      );
    },
  );
  test('Revoked account cannot commit an already pending mutation', () async {
    final s = demo();
    addTearDown(s.dispose);
    s.transport.delay = const Duration(milliseconds: 20);
    final pending = s.workflows.submitKyc('012345678901', 'front', 'back');
    s.store.blocked.add('tenant-a');
    await expectLater(pending, denied);
    expect(s.store.kyc, isEmpty);
  });
  testWidgets(
    'Welcome carousel has three actual pages and working indicators',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PT.theme,
          home: WelcomeScreen(onExplore: () {}, onLogin: () {}),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(PageView));
      await tester.pumpAndSettle();
      expect(find.text('1/3'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);
      await tester.tap(find.byTooltip('Giới thiệu 3'));
      await tester.pumpAndSettle();
      expect(find.text('3/3'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'Room editor preserves floor, images, fees and location when draft reopens',
    (tester) async {
      final s = demo();
      addTearDown(s.dispose);
      await tester.runAsync(
        () => s.authenticate('landlord2@demo.vn', 'demo123'),
      );
      final room = s.roomById('r4')!;
      await tester.pumpWidget(
        MaterialApp(
          theme: PT.theme,
          home: PostRoomScreen(state: s, existing: room),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, '4'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Tiêu đề bản nháp',
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      expect(s.roomById('r4')!.title, room.title);
      await tester.pumpWidget(
        MaterialApp(
          theme: PT.theme,
          home: PostRoomScreen(state: s, existing: room),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tiêu đề bản nháp'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '4'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, room.electricity), findsOneWidget);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.byType(ReferencePhoto), findsOneWidget);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text(room.address), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('Check-in selects rental B and leaves rental A unchecked', (
    tester,
  ) async {
    final s = demo();
    addTearDown(s.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: PT.theme,
        home: Scaffold(body: CheckInScreen(state: s)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('lease-a2 • ${s.roomById('r3')!.title}').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhập mã'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'PTX-2027');
    await tester.scrollUntilVisible(
      find.text('Xác nhận nhận phòng'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận nhận phòng'));
    await tester.pumpAndSettle();
    expect(s.rentalById('lease-a2')!.checkedIn, isTrue);
    expect(s.rentalById('lease-a1')!.checkedIn, isFalse);
    expect(find.text('Nhận phòng thành công!'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'KYC documents and admin decision fit large text on a narrow phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final s = demo();
      addTearDown(s.dispose);
      final kyc = await tester.runAsync(
        () => s.workflows.submitKyc('012345678901', 'front', 'back'),
      );
      s.session.startDemo(UserRole.admin);
      await tester.pumpWidget(
        MaterialApp(
          theme: PT.theme,
          home: AdminDecisionScreen(state: s, kind: 'kyc', id: kyc!.id),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Từ chối hồ sơ'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          theme: PT.theme,
          home: PostRoomScreen(state: s, existing: s.roomById('r4')),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  test(
    'KYC reject/resubmit/approve updates exact account and retains history',
    () async {
      final s = demo();
      addTearDown(s.dispose);
      final first = await s.workflows.submitKyc(
        '012345678901',
        'front',
        'back',
      );
      await expectLater(
        s.workflows.submitKyc('012345678901', 'front', 'back'),
        denied,
      );
      s.session.startDemo(UserRole.admin);
      await expectLater(s.workflows.decideKyc(first.id, false, ''), denied);
      await s.workflows.decideKyc(first.id, false, 'Ảnh chưa rõ');
      s.session.startDemo(UserRole.tenant);
      expect(s.verification, 'Đã từ chối');
      final second = await s.workflows.submitKyc(
        '012345678901',
        'demo-front',
        'demo-back',
      );
      expect(second.id, isNot(first.id));
      s.session.startDemo(UserRole.admin);
      await s.workflows.decideKyc(second.id, true, 'Đủ hai mặt');
      s.session.startDemo(UserRole.tenant);
      expect(s.verification, 'Đã xác minh');
      expect(s.store.kyc.first.note, 'Ảnh chưa rõ');
      expect(
        s.notifications.where((n) => n.id.startsWith('decision-')).length,
        2,
      );
      await s.authenticate('tenant2@demo.vn', 'demo123');
      expect(s.verification, 'Chưa xác minh');
    },
  );
  test('Offline KYC preserves form inputs and creates no record', () async {
    final s = demo();
    addTearDown(s.dispose);
    s.transport.fault = DemoFault.offline;
    await expectLater(
      s.workflows.submitKyc('012345678901', 'front', 'back'),
      denied,
    );
    expect(s.store.kyc, isEmpty);
    expect(s.verification, 'Chưa xác minh');
    s.transport.fault = DemoFault.none;
    await s.workflows.submitKyc('012345678901', 'front', 'back');
    expect(s.store.kyc.length, 1);
  });
  test(
    'Tenant report is processed by admin and survives account switch',
    () async {
      final s = demo();
      addTearDown(s.dispose);
      final r = await s.workflows.report(
        'ROOM',
        'r4',
        'Sai thông tin',
        'Giá không khớp',
      );
      await expectLater(
        s.workflows.resolveReport(r.id, 'resolve', 'Đã kiểm tra'),
        denied,
      );
      s.session.startDemo(UserRole.admin);
      s.transport.fault = DemoFault.server;
      await expectLater(
        s.workflows.resolveReport(r.id, 'remove_content', 'Ẩn tin'),
        denied,
      );
      expect(s.roomById('r4')!.status, RoomStatus.available);
      expect(r.history, isEmpty);
      s.transport.fault = DemoFault.none;
      await s.workflows.resolveReport(
        r.id,
        'remove_content',
        'Đã kiểm tra và ẩn tin',
      );
      expect(s.roomById('r4')!.status, RoomStatus.hidden);
      expect(r.status, 'Đã xử lý');
      await expectLater(
        s.workflows.resolveReport(r.id, 'ban', 'Thử lại'),
        denied,
      );
      expect(r.history.length, 1);
    },
  );
  test(
    'Admin blocks correct account; login rejects it until unblock',
    () async {
      final s = demo(UserRole.admin);
      addTearDown(s.dispose);
      await expectLater(
        s.workflows.userStatus('admin-a', true, 'Tự khóa'),
        denied,
      );
      await s.workflows.userStatus('owner-b', true, 'Vi phạm');
      s.logout();
      expect(await s.authenticate('landlord2@demo.vn', 'demo123'), isFalse);
      expect(await s.authenticate('landlord@demo.vn', 'demo123'), isTrue);
      s.session.startDemo(UserRole.admin);
      await s.workflows.userStatus('owner-b', false, 'Đã giải quyết');
      expect(await s.authenticate('landlord2@demo.vn', 'demo123'), isTrue);
    },
  );
  test(
    'Review targets room for tenant and tenant for owner, never duplicates',
    () async {
      final s = demo();
      addTearDown(s.dispose);
      await expectLater(s.workflows.review('lease-a2', 5, 'Tốt', []), denied);
      expect(s.checkIn('PTX-2027', rentalId: 'lease-a2'), isNull);
      final tenant = await s.workflows.review('lease-a2', 4, 'Phòng sạch', [
        'Sạch sẽ',
      ]);
      expect(tenant.targetId, 'r3');
      expect(tenant.targetType, 'ROOM');
      await expectLater(
        s.workflows.review('lease-a2', 5, 'Gửi lại', []),
        denied,
      );
      s.session.startDemo(UserRole.landlord);
      expect(s.roomRating('r3'), '4.0');
      final owner = await s.workflows.review('lease-a2', 5, 'Gọn gàng', [
        'Đúng hẹn',
      ]);
      expect(owner.targetId, 'tenant-a');
      expect(owner.targetType, 'USER');
      await s.authenticate('landlord2@demo.vn', 'demo123');
      await expectLater(
        s.workflows.review('lease-a2', 5, 'Không phải khách của tôi', []),
        denied,
      );
      expect(s.store.reviewRecords.length, 2);
    },
  );
  test(
    'Swap has correct fields, owner approval, proposal and accepted status',
    () async {
      final s = demo();
      addTearDown(s.dispose);
      s.checkIn('PTX-2027');
      final listing = await s.workflows.createSwap(
        SwapRequest(
          roomId: 'r3',
          reason: 'Gần chỗ làm',
          leaseholder: true,
          targetDistrict: 'Thủ Đức',
          targetType: 'Căn hộ mini',
          budgetMax: 5000000,
          movingDate: '2026-11-01',
          habits: ['Yên tĩnh'],
        ),
      );
      expect(listing.status, 'Chờ duyệt');
      expect(listing.roomId, 'r3');
      expect(listing.targetDistrict, 'Thủ Đức');
      expect(listing.budgetMax, 5000000);
      expect(listing.habits, ['Yên tĩnh']);
      await s.authenticate('landlord2@demo.vn', 'demo123');
      await expectLater(s.workflows.decideSwap(listing.id, true, ''), denied);
      s.session.startDemo(UserRole.landlord);
      await s.workflows.decideSwap(listing.id, true, 'Đồng ý');
      expect(listing.status, 'Đã duyệt');
      await s.authenticate('tenant2@demo.vn', 'demo123');
      s.checkIn('PTX-4026');
      s.transport.fault = DemoFault.offline;
      await expectLater(
        s.workflows.propose(listing.id, 'lease-b1', 'Đổi với tôi'),
        denied,
      );
      expect(s.store.proposals, isEmpty);
      s.transport.fault = DemoFault.none;
      final p = await s.workflows.propose(
        listing.id,
        'lease-b1',
        'Đổi với tôi',
      );
      await expectLater(
        s.workflows.propose(listing.id, 'lease-b1', 'Lặp'),
        denied,
      );
      await expectLater(s.workflows.respondProposal(p.id, true), denied);
      s.session.startDemo(UserRole.tenant);
      await s.workflows.respondProposal(p.id, true);
      expect(p.status, 'Đã chấp nhận');
      expect(listing.status, 'Đã ghép • chờ hợp đồng mới');
      expect(s.rentalById('lease-a2')!.room.id, 'r3');
      await expectLater(s.workflows.respondProposal(p.id, true), denied);
    },
  );
  test(
    'Non-leaseholder listing opens directly; cancel invalidates proposals',
    () async {
      final s = demo();
      addTearDown(s.dispose);
      s.checkIn('PTX-2026');
      final listing = await s.workflows.createSwap(
        SwapRequest(roomId: 'r1', reason: 'Đổi khu vực', leaseholder: false),
      );
      expect(listing.status, 'Đang tìm phòng phù hợp');
      await expectLater(
        s.workflows.createSwap(
          SwapRequest(roomId: 'r1', reason: 'Trùng', leaseholder: false),
        ),
        denied,
      );
      await s.authenticate('tenant2@demo.vn', 'demo123');
      s.checkIn('PTX-4026');
      final p = await s.workflows.propose(listing.id, 'lease-b1', 'Đề nghị');
      s.session.startDemo(UserRole.tenant);
      await s.workflows.cancelSwap(listing.id);
      expect(listing.status, 'Đã hủy');
      expect(p.status, 'Đã từ chối');
    },
  );
  test(
    'Only mutual likes become matches; unmatch removes incoming and sent like',
    () async {
      final s = demo();
      addTearDown(s.dispose);
      s.liked.addAll(['p1', 'p2']);
      await expectLater(s.workflows.confirmMatch('p2'), denied);
      expect(s.store.matches[s.userId], isNull);
      await s.workflows.confirmMatch('p1');
      final chat = s.contactPerson(s.personById('p1')!);
      expect(chat.participantId, 'p1');
      expect(s.contactPerson(s.personById('p1')!), same(chat));
      await s.workflows.unmatch('p1');
      expect(s.store.matches[s.userId], isEmpty);
      expect(s.liked, ['p2']);
      expect(s.conversations, contains(chat));
    },
  );
  test('Payment failure/cancel/pending do not grant, success is idempotent and isolated', () async {
    final s = demo();
    addTearDown(s.dispose);
    final plan = ServicePlan.catalog.firstWhere((p) => p.id == 'swipes');
    final canceled = await s.workflows.checkout(plan, false, 'MoMo');
    await s.workflows.paymentResult(canceled.id, 'Đã hủy');
    final failed = await s.workflows.checkout(plan, false, 'Thẻ');
    await s.workflows.paymentResult(failed.id, 'Thất bại');
    expect(s.roomQuota, 7);
    final order = await s.workflows.checkout(plan, false, 'Ngân hàng');
    expect(s.roomQuota, 7);
    await s.workflows.paymentResult(order.id, 'Thành công');
    await s.workflows.paymentResult(order.id, 'Thành công');
    expect(s.roomQuota, 157);
    expect(s.store.workspace(s.session.user!).roomAllowance, 165);
    await s.authenticate('tenant2@demo.vn', 'demo123');
    await expectLater(
      s.workflows.paymentResult(order.id, 'Thành công'),
      denied,
    );
    expect(s.roomQuota, 7);
    await expectLater(
      s.workflows.checkout(ServicePlan.catalog.last, false, 'MoMo'),
      denied,
    );
  });
  test(
    'Owner yearly package amount and consumable decrement are validated',
    () async {
      final s = demo(UserRole.landlord);
      addTearDown(s.dispose);
      final order = await s.workflows.checkout(
        ServicePlan.catalog.firstWhere((p) => p.id == 'owner-pro'),
        true,
        'Thẻ',
      );
      expect(order.amount, 1908000);
      await s.workflows.paymentResult(order.id, 'Thành công');
      expect(s.store.profiles[s.userId]!.package, 'Chủ trọ Pro');
      s.session.startDemo(UserRole.tenant);
      final boost = await s.workflows.checkout(
        ServicePlan.catalog.firstWhere((p) => p.id == 'boost'),
        false,
        'MoMo',
      );
      await s.workflows.paymentResult(boost.id, 'Thành công');
      await s.workflows.consume('BOOST', null);
      await expectLater(s.workflows.consume('BOOST', null), denied);
      expect(s.store.profiles[s.userId]!.boosts, 0);
    },
  );
  test(
    'Refreshed rental B code invalidates old code and works only for tenant B',
    () async {
      final s = demo(UserRole.landlord);
      addTearDown(s.dispose);
      await s.workflows.refreshCode('lease-a2');
      final code = s.rentalById('lease-a2')!.code;
      expect(code, isNot('PTX-2027'));
      await expectLater(s.workflows.refreshCode('lease-b1'), denied);
      s.session.startDemo(UserRole.tenant);
      expect(s.checkIn('PTX-2027'), isNotNull);
      expect(s.checkIn(code, rentalId: 'lease-a1'), isNotNull);
      expect(s.checkIn(code, rentalId: 'lease-a2'), isNull);
      expect(s.checkIn(code, rentalId: 'lease-a2'), isNotNull);
      s.session.startDemo(UserRole.landlord);
      await expectLater(s.workflows.refreshCode('lease-a2'), denied);
    },
  );
  test('Admin approves a pending room; wrong role cannot publish it', () async {
    final s = demo(UserRole.landlord);
    addTearDown(s.dispose);
    await expectLater(s.workflows.moderateRoom('r2', true), denied);
    s.session.startDemo(UserRole.admin);
    await s.workflows.moderateRoom('r2', true);
    expect(s.roomById('r2')!.status, RoomStatus.available);
    await expectLater(s.workflows.moderateRoom('r2', true), denied);
  });
  test('Logout and dispose invalidate pending domain mutations', () async {
    final s = demo();
    addTearDown(s.dispose);
    s.transport.delay = const Duration(milliseconds: 20);
    final pending = s.workflows.submitKyc('012345678901', 'front', 'back');
    s.logout();
    await expectLater(pending, denied);
    expect(s.store.kyc, isEmpty);
    final other = demo();
    other.transport.delay = const Duration(milliseconds: 20);
    final request = other.workflows.report(
      'ROOM',
      'r1',
      'Sai',
      'Thông tin sai',
    );
    other.dispose();
    await expectLater(request, denied);
    expect(other.store.reports, isEmpty);
  });
  test(
    'Account delete rejects password/error, then login remains unavailable',
    () async {
      final s = demo();
      addTearDown(s.dispose);
      await expectLater(s.workflows.deleteAccount('wrong'), denied);
      expect(s.store.deleted, isEmpty);
      s.transport.fault = DemoFault.offline;
      await expectLater(s.workflows.deleteAccount('demo123'), denied);
      expect(s.authenticated, isTrue);
      s.transport.fault = DemoFault.none;
      await s.workflows.deleteAccount('demo123');
      s.logout();
      expect(await s.authenticate('tenant@demo.vn', 'demo123'), isFalse);
      expect(await s.authenticate('tenant2@demo.vn', 'demo123'), isTrue);
    },
  );
  test(
    'New administrative and landlord screens use release-safe type guards',
    () {
      final s = demo();
      addTearDown(s.dispose);
      for (final page in [
        AdminRoomsScreen(state: s),
        AdminDecisionScreen(state: s, kind: 'user', id: 'tenant-a'),
        LandlordTenantsScreen(state: s),
      ]) {
        expect(RoutePolicy.forPage(page).evaluate(s), AccessResult.denied);
      }
    },
  );

  for (final name in [
    'profile',
    'onboarding',
    'kyc',
    'matches',
    'review',
    'swap',
    'tenants',
    'owner-reviews',
    'qr',
    'admin',
    'kyc-queue',
    'admin-users',
    'admin-reports',
    'admin-rooms',
    'packages',
    'checkout',
    'support',
    'delete',
  ]) {
    testWidgets('$name fits 320px, text scale 1.6 and keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final originalError = FlutterError.onError;
      FlutterError.onError = (details) {
        debugPrint(details.toString());
        originalError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalError);
      final owner = ['tenants', 'owner-reviews', 'qr'].contains(name);
      final admin = name.startsWith('admin') || name == 'kyc-queue';
      final s = demo(
        admin
            ? UserRole.admin
            : owner
            ? UserRole.landlord
            : UserRole.tenant,
      );
      s.store.rentals.first.checkedIn = name != 'qr';
      s.liked.add('p1');
      Widget page = switch (name) {
        'profile' => EditProfileScreen(state: s),
        'onboarding' => ProfileSetupScreen(state: s, onComplete: () {}),
        'kyc' => VerificationScreen(state: s),
        'matches' => MatchesScreen(state: s),
        'review' => ReviewScreen(state: s, rentalId: 'lease-a1'),
        'swap' => SwapScreen(state: s),
        'tenants' => LandlordTenantsScreen(state: s),
        'owner-reviews' => LandlordReviewsScreen(state: s),
        'qr' => LandlordQRScreen(state: s),
        'admin' => AdminScreen(state: s),
        'kyc-queue' => AdminQueueScreen(state: s),
        'admin-users' => AdminUsersScreen(state: s),
        'admin-reports' => AdminReportsScreen(state: s),
        'admin-rooms' => AdminRoomsScreen(state: s),
        'packages' => PackagesScreen(state: s),
        'checkout' => CheckoutScreen(state: s, plan: ServicePlan.catalog.first),
        'support' => SupportScreen(state: s),
        _ => DeleteAccountScreen(state: s),
      };
      await tester.pumpWidget(MaterialApp(theme: PT.theme, home: page));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (name == 'swap') {
        await tester.tap(find.text('Tạo yêu cầu').first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      s.dispose();
    });
  }
  testWidgets(
    'Profile draft survives back; canceled draft does not change public values',
    (tester) async {
      final s = demo();
      addTearDown(s.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: PT.theme,
          home: EditProfileScreen(state: s),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Tên bản nháp');
      await tester.pumpWidget(const SizedBox.shrink());
      expect(s.fullName, 'Nguyễn Hoài An');
      await tester.pumpWidget(
        MaterialApp(
          theme: PT.theme,
          home: EditProfileScreen(state: s),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tên bản nháp'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'KYC picker can remove media and retry failed submission without loss',
    (tester) async {
      final s = demo();
      addTearDown(s.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: PT.theme,
          home: VerificationScreen(state: s),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '012345678901');
      await tester.tap(find.text('Chọn ảnh mẫu Mặt trước'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa ảnh Mặt trước'));
      await tester.pumpAndSettle();
      expect(find.byType(DemoDocumentPreview), findsNothing);
      await tester.tap(find.text('Chọn ảnh mẫu Mặt trước'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Chọn ảnh mẫu Mặt sau'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn ảnh mẫu Mặt sau'));
      await tester.pumpAndSettle();
      s.transport.fault = DemoFault.offline;
      await tester.scrollUntilVisible(
        find.text('Gửi xác minh'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi xác minh'));
      await tester.pumpAndSettle();
      expect(s.store.kyc, isEmpty);
      expect(find.byType(DemoDocumentPreview), findsNWidgets(2));
      s.transport.fault = DemoFault.none;
      await tester.scrollUntilVisible(
        find.text('Gửi xác minh'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi xác minh'));
      await tester.pumpAndSettle();
      expect(s.store.kyc.single.number, '012345678901');
      expect(find.text('Chờ duyệt'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
