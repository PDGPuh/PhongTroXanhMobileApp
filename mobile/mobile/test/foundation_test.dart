import 'package:phong_tro_xanh_mobile/mock/transport.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phong_tro_xanh_mobile/app/app.dart';
import 'package:phong_tro_xanh_mobile/app/app_state.dart';
import 'package:phong_tro_xanh_mobile/app/navigation.dart';
import 'package:phong_tro_xanh_mobile/core/async_resource.dart';
import 'package:phong_tro_xanh_mobile/domain/models.dart';
import 'package:phong_tro_xanh_mobile/features/admin/admin_screens.dart';
import 'package:phong_tro_xanh_mobile/features/auth/auth_screens.dart';
import 'package:phong_tro_xanh_mobile/features/account/account_screens.dart';
import 'package:phong_tro_xanh_mobile/features/rooms/room_screens.dart';
import 'package:phong_tro_xanh_mobile/features/landlord/landlord_screens.dart';
import 'package:phong_tro_xanh_mobile/features/rentals/rental_screens.dart';

AppState fixture() => AppState(transport: DemoTransport(delay: Duration.zero));

void main() {
  testWidgets(
    'Admin can log out from the overview without retaining private routes',
    (tester) async {
      final state = AppState(
        role: UserRole.admin,
        transport: DemoTransport(delay: Duration.zero),
      );
      addTearDown(state.dispose);
      await tester.pumpWidget(
        PhongTroXanhApp(state: state, initialScreen: 'admin'),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Đăng xuất'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(state.authenticated, isFalse);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(AdminScreen), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('QR screen only exposes rentals of the signed-in landlord', (
    tester,
  ) async {
    final state = fixture();
    addTearDown(state.dispose);
    await tester.runAsync(
      () => state.authenticate('landlord2@demo.vn', 'demo123'),
    );
    await tester.pumpWidget(MaterialApp(home: LandlordQRScreen(state: state)));
    await tester.pumpAndSettle();
    expect(find.text('PTX-4026'), findsOneWidget);
    expect(find.text('PTX-2026'), findsNothing);
    expect(find.text('Studio xanh gần Bách Khoa'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'Review uses the selected rental and refuses duplicate submission',
    (tester) async {
      final state = AppState(role: UserRole.tenant);
      addTearDown(state.dispose);
      state.checkIn('PTX-2026');
      state.checkIn('PTX-2027');
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewScreen(state: state, rentalId: 'lease-a2'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Đánh giá phòng thứ hai');
      await tester.ensureVisible(find.text('Gửi đánh giá'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi đánh giá'));
      await tester.pumpAndSettle();
      expect(state.reviews['lease-a2']!.comment, 'Đánh giá phòng thứ hai');
      expect(state.reviews.containsKey('lease-a1'), isFalse);
      expect(
        () => state.review('lease-a2', 4, 'duplicate'),
        throwsA(isA<RepositoryFailure>()),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  test(
    'Unknown email prefix cannot create an admin or bypass credentials',
    () async {
      final state = fixture();
      addTearDown(state.dispose);
      expect(
        await state.authenticate('admin-impostor@demo.vn', 'demo123'),
        isFalse,
      );
      expect(state.authenticated, isFalse);
      expect(await state.authenticate('admin@demo.vn', 'wrongpass'), isFalse);
      expect(await state.authenticate('admin@demo.vn', 'demo123'), isTrue);
      expect(state.userId, 'admin-a');
      expect(state.role, UserRole.admin);
    },
  );
  test(
    'Registration uses server identity and always starts as tenant',
    () async {
      final state = fixture();
      addTearDown(state.dispose);
      expect(
        await state.session.register(
          email: 'admin-new@example.vn',
          password: 'secret123',
          name: 'User',
          phone: '0909999000',
        ),
        isTrue,
      );
      expect(state.role, UserRole.tenant);
      final id = state.userId;
      state.logout();
      expect(await state.authenticate('0909999000', 'secret123'), isTrue);
      expect(state.userId, id);
    },
  );
  test(
    'Account data, settings and drafts are isolated across logout',
    () async {
      final state = fixture();
      addTearDown(state.dispose);
      await state.authenticate('tenant@demo.vn', 'demo123');
      state.toggleSave('r1');
      state.setSetting('messages', false);
      state.updateProfile('Tên A', 'changed@example.vn', 'Bio A');
      state.drafts['chat-c1'] = 'sensitive';
      state.logout();
      expect(state.saved, isEmpty);
      expect(state.conversations, isEmpty);
      expect(state.fullName, 'Khách');
      expect(state.rentals, isEmpty);
      await state.authenticate('tenant2@demo.vn', 'demo123');
      expect(state.saved, isEmpty);
      expect(state.conversations, isEmpty);
      expect(state.fullName, 'Lê Thu Hà');
      expect(state.settings['messages'], isNot(false));
      await state.authenticate('tenant@demo.vn', 'demo123');
      expect(state.saved, {'r1'});
      expect(state.fullName, 'Tên A');
      expect(state.settings['messages'], isFalse);
      expect(state.drafts, isEmpty);
    },
  );
  test(
    'Room conversation and shared cards retain selected participant and room',
    () async {
      final state = fixture();
      addTearDown(state.dispose);
      await state.authenticate('tenant@demo.vn', 'demo123');
      final room = state.roomById('r4')!;
      final c = state.contactRoom(room);
      expect(c.participantId, 'owner-b');
      expect(c.roomId, 'r4');
      expect(c.participantName, 'Nguyễn Văn Hùng');
      expect(state.contactRoom(room), same(c));
      state.shareRoom(c, state.roomById('r1')!);
      expect(c.roomId, 'r4');
      expect(c.messages.last.roomId, 'r1');
      state.logout();
      await state.authenticate('tenant2@demo.vn', 'demo123');
      expect(
        () => state.send(c, 'cross-account'),
        throwsA(isA<RepositoryFailure>()),
      );
    },
  );
  test(
    'Ownership and pending approval cannot be bypassed by mutations',
    () async {
      final state = fixture();
      addTearDown(state.dispose);
      await state.authenticate('landlord2@demo.vn', 'demo123');
      expect(state.myRooms.map((r) => r.id), ['r4']);
      expect(
        () => state.setRoomStatus(state.roomById('r1')!, 'Đã ẩn'),
        throwsA(isA<RepositoryFailure>()),
      );
      expect(
        () => state.replaceRoom(state.roomById('r1')!),
        throwsA(isA<RepositoryFailure>()),
      );
      await state.authenticate('landlord@demo.vn', 'demo123');
      expect(
        () => state.setRoomStatus(state.roomById('r2')!, 'Đang hiển thị'),
        throwsA(isA<RepositoryFailure>()),
      );
      state.addRoom(
        const Room(
          id: 'new-owner',
          title: 'Test',
          district: 'Quận 10',
          price: 2000000,
        ),
      );
      expect(state.roomById('new-owner')!.landlordId, 'owner-a');
      expect(state.roomById('new-owner')!.status, RoomStatus.pending);
    },
  );
  test(
    'Access policies enforce auth, roles, ownership and typed resource IDs',
    () async {
      final state = fixture();
      addTearDown(state.dispose);
      final admin = RoutePolicy.forPage(AdminQueueScreen(state: state));
      expect(admin.evaluate(state), AccessResult.loginRequired);
      await state.authenticate('tenant@demo.vn', 'demo123');
      expect(admin.evaluate(state), AccessResult.denied);
      expect(
        const RoutePolicy(
          public: true,
        ).evaluate(state, target: const ResourceRef(ResourceKind.room, 'r2')),
        AccessResult.denied,
      );
      expect(
        const RoutePolicy(
          public: true,
        ).evaluate(state, target: const ResourceRef(ResourceKind.room, 'gone')),
        AccessResult.missing,
      );
      expect(AppDestination.parse('/rooms/r4')!.target!.id, 'r4');
      expect(
        AppDestination.parse('/chat/c7')!.target!.kind,
        ResourceKind.conversation,
      );
      expect(AppDestination.parse('/unknown'), isNull);
    },
  );
  test(
    'Discover exposes available rooms only, including after filter change',
    () async {
      final state = fixture();
      addTearDown(state.dispose);
      state.filters('Tất cả', 'Tất cả', 6000000);
      await state.loadRooms();
      expect(state.filteredRooms.map((r) => r.id), ['r1', 'r4']);
      state.roomController.query = 'Thảo Điền';
      expect(state.filteredRooms.map((r) => r.id), ['r4']);
      state.roomController.minPrice = 5000000;
      expect(state.filteredRooms, isEmpty);
    },
  );
  test(
    'Repository error hides fixtures and retry restores fetched content',
    () async {
      final state = fixture();
      addTearDown(state.dispose);
      await state.loadRooms();
      state.transport.fault = RepositoryFault.offline;
      await state.loadRooms();
      expect(state.roomController.feed.phase, ResourcePhase.error);
      expect(state.roomController.feed.data, isNull);
      expect(state.filteredRooms, isEmpty);
      state.transport.fault = RepositoryFault.none;
      await state.loadRooms();
      expect(state.roomController.feed.phase, ResourcePhase.ready);
      expect(state.filteredRooms.single.id, 'r1');
    },
  );
  test('Late auth response cannot resurrect a logged-out session', () async {
    final state = AppState(
      transport: DemoTransport(delay: const Duration(milliseconds: 20)),
    );
    addTearDown(state.dispose);
    final pending = state.authenticate('admin@demo.vn', 'demo123');
    state.logout();
    expect(await pending, isFalse);
    expect(state.authenticated, isFalse);
    expect(state.session.busy, isFalse);
  });
  test(
    'Async resource discards outdated results and can dispose during a fetch',
    () async {
      final feed = AsyncResource<List<int>>();
      final pending = Completer<List<int>>();
      final first = feed.load(() => pending.future);
      await feed.load(() async => [2]);
      pending.complete([1]);
      await first;
      expect(feed.data, [2]);
      final next = Completer<List<int>>();
      final fetch = feed.load(() => next.future);
      feed.dispose();
      next.complete([3]);
      await fetch;
    },
  );
  test('Undo works separately after interleaved room and roommate swipes', () {
    final state = AppState(role: UserRole.tenant);
    addTearDown(state.dispose);
    state.swipe(person: false, like: true);
    state.swipe(person: true, like: true);
    state.undo(false);
    expect(state.roomIndex, 0);
    expect(state.roomQuota, 7);
    expect(state.personIndex, 1);
    expect(state.roommateQuota, 5);
    state.undo(true);
    expect(state.personIndex, 0);
    expect(state.roommateQuota, 6);
  });
  test('Check-in validates selected rental and authenticated tenant', () async {
    final state = fixture();
    addTearDown(state.dispose);
    await state.authenticate('tenant@demo.vn', 'demo123');
    expect(state.checkIn('PTX-2027', rentalId: 'lease-a1'), isNotNull);
    expect(state.checkIn('PTX-2027', rentalId: 'lease-a2'), isNull);
    expect(state.rentalById('lease-a1')!.checkedIn, isFalse);
    expect(state.rentalById('lease-a2')!.checkedIn, isTrue);
    await state.authenticate('tenant2@demo.vn', 'demo123');
    expect(state.checkIn('PTX-2026'), isNotNull);
    expect(state.rentals.single.id, 'lease-b1');
  });
  for (final path in ['/rooms/r4', '/rooms/missing', '/admin']) {
    testWidgets('Native initial route $path retains ID and access policy', (
      tester,
    ) async {
      tester.platformDispatcher.defaultRouteNameTestValue = path;
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      final state = fixture();
      addTearDown(state.dispose);
      if (path == '/admin') {
        state.session.startDemo(UserRole.tenant);
      }
      await tester.pumpWidget(PhongTroXanhApp(state: state));
      await tester.pumpAndSettle();
      if (path == '/rooms/r4') {
        expect(
          tester
              .widget<RoomDetailScreen>(find.byType(RoomDetailScreen))
              .room
              .id,
          'r4',
        );
        expect(state.authenticated, isFalse);
      } else if (path == '/admin') {
        expect(find.text('Bạn không có quyền truy cập'), findsOneWidget);
        expect(find.byType(AdminScreen), findsNothing);
      } else {
        expect(find.text('Nội dung không còn tồn tại'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'URL preview does not grant admin without explicit preview mode',
    (tester) async {
      final state = fixture();
      addTearDown(state.dispose);
      await tester.pumpWidget(
        PhongTroXanhApp(state: state, initialScreen: 'admin'),
      );
      await tester.pumpAndSettle();
      expect(state.authenticated, isFalse);
      expect(find.byType(AdminScreen), findsNothing);
      expect(find.text('Đăng nhập để tiếp tục'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('Guest saves room after login and returns to the same detail', (
    tester,
  ) async {
    final state = fixture();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      PhongTroXanhApp(state: state, initialScreen: 'detail'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu').last);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(state.saved, isEmpty);
    await tester.enterText(find.byType(TextFormField).first, 'tenant@demo.vn');
    await tester.enterText(find.byType(TextFormField).last, 'demo123');
    await tester.tap(find.text('Đăng nhập').last);
    await tester.pumpAndSettle();
    expect(find.byType(RoomDetailScreen), findsOneWidget);
    expect(state.saved, {'r1'});
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Logout removes a protected page and all private UI', (
    tester,
  ) async {
    final state = fixture();
    addTearDown(state.dispose);
    state.session.startDemo(UserRole.tenant);
    state.toggleSave('r1');
    await tester.pumpWidget(
      PhongTroXanhApp(state: state, initialScreen: 'profile'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Chỉnh sửa hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
    state.logout();
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(state.saved, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Room list offers retry after offline, without demo fallback', (
    tester,
  ) async {
    final state = fixture();
    addTearDown(state.dispose);
    state.transport.fault = RepositoryFault.offline;
    await tester.pumpWidget(
      PhongTroXanhApp(state: state, initialScreen: 'discover'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.byType(RoomCard), findsNothing);
    state.transport.fault = RepositoryFault.none;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(RoomCard), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
