import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phong_tro_xanh_mobile/app/app.dart';
import 'package:phong_tro_xanh_mobile/app/app_state.dart';
import 'package:phong_tro_xanh_mobile/core/tab_navigation_bar.dart';
import 'package:phong_tro_xanh_mobile/demo/models.dart';
import 'package:phong_tro_xanh_mobile/features/rooms/room_screens.dart';
import 'package:phong_tro_xanh_mobile/features/chat/chat_screens.dart';
import 'package:phong_tro_xanh_mobile/features/rentals/rental_screens.dart';

void main() {
  for (final screen in ['discover', 'roommate']) {
    testWidgets('$screen keeps swipe actions visible while content scrolls', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState(role: UserRole.tenant);
      addTearDown(state.dispose);
      await tester.pumpWidget(
        PhongTroXanhApp(state: state, initialScreen: screen),
      );
      await tester.pumpAndSettle();
      final action = find.byTooltip(
        screen == 'discover' ? 'Lưu phòng' : 'Thích bạn ở',
      );
      final before = tester.getRect(action);
      expect(
        before.bottom,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(TabNavigationBar)).dy),
      );
      final scroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(DiscoverScreen),
              matching: find.byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              ),
            )
            .first,
      );
      scroll.position.jumpTo(160);
      await tester.pumpAndSettle();
      expect(tester.getRect(action), before);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'Welcome action enters the app and login changes the active role',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState(role: UserRole.tenant);
      await tester.pumpWidget(
        PhongTroXanhApp(state: state, initialScreen: 'welcome'),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Bắt đầu tìm phòng'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bắt đầu tìm phòng'));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        PhongTroXanhApp(state: state, initialScreen: 'login'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'landlord@demo.vn',
      );
      await tester.enterText(find.byType(TextFormField).last, 'demo123');
      await tester.tap(find.text('Đăng nhập').last);
      await tester.pumpAndSettle();
      expect(state.role, UserRole.landlord);
      expect(find.byType(AppShell), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    },
  );

  test('People filters apply and undo preserves an earlier like', () {
    final state = AppState(role: UserRole.tenant);
    expect(state.filteredPeople.every((p) => p.gender == 'Nữ'), isTrue);
    state.personFilters('Tất cả', 'Nam', 'Gọn gàng', 3000000);
    expect(state.filteredPeople.map((p) => p.id), ['p2']);
    state.liked.add('p2');
    expect(state.swipe(person: true, like: true), isTrue);
    state.undo(true);
    expect(state.liked, contains('p2'));
    state.dispose();
  });
  test(
    'Room drafts retain fee data and check-in reviews survive screen changes',
    () {
      final state = AppState(role: UserRole.landlord);
      const room = Room(
        id: 'new',
        title: 'Phòng thử',
        district: 'Quận 3',
        price: 3000000,
        address: '456 đường mới',
        description: 'Mô tả đã nhập',
        electricity: '4.000đ/kWh',
        water: '80.000đ/người',
        otherFees: 'Wifi 50.000đ',
      );
      state.addRoom(room);
      expect(state.rooms.last.otherFees, 'Wifi 50.000đ');
      state.session.startDemo(UserRole.tenant);
      state.checkIn('PTX-2026');
      state.review('r1', 4, '  Phòng thoáng  ');
      expect(state.reviews['lease-a1']!.comment, 'Phòng thoáng');
      final request = SwapRequest(
        roomId: 'r1',
        reason: 'Người ở ghép chuyển đi',
        leaseholder: false,
      );
      state.addSwap(request);
      expect(request.status, 'Đang tìm phòng phù hợp');
      state.dispose();
    },
  );

  test('Saving, swiping and undo share one source of truth', () {
    final state = AppState(role: UserRole.tenant);
    state.toggleSave('r1');
    expect(state.saved, contains('r1'));
    expect(state.swipe(person: false, like: true), isTrue);
    expect(state.roomQuota, 6);
    state.undo(false);
    expect(state.roomQuota, 7);
    expect(
      state.saved,
      contains('r1'),
      reason: 'Undo must preserve a room saved before swiping.',
    );
    state.toggleSave('r1');
    expect(state.saved, isEmpty);
    state.swipe(person: false, like: true);
    expect(state.saved, contains('r1'));
    state.undo(false);
    expect(state.saved, isEmpty);
    state.dispose();
  });
  test('Room filters apply both type, area and price', () {
    final state = AppState(role: UserRole.tenant);
    state.filters('Quận 10', 'Tất cả', 2600000);
    expect(state.filteredRooms, isEmpty);
    state.filters('Tất cả', 'Studio', 3500000);
    expect(state.filteredRooms.map((r) => r.id), ['r1']);
    state.dispose();
  });
  test('Check-in rejects bad/reused codes; swap approval changes status', () {
    final state = AppState(role: UserRole.tenant);
    expect(state.checkIn('bad'), isNotNull);
    expect(state.reviewableRentals, isEmpty);
    expect(state.checkIn('ptx-2026'), isNull);
    expect(state.reviewableRentals.length, 1);
    expect(state.checkIn('PTX-2026'), isNotNull);
    final request = SwapRequest(
      roomId: 'r1',
      reason: 'Thay đổi nơi làm việc',
      leaseholder: true,
    );
    state.addSwap(request);
    state.session.startDemo(UserRole.landlord);
    state.resolveSwap(state.swaps.single, true);
    expect(state.swaps.single.status, 'Đã duyệt');
    state.dispose();
  });
  test('Contact actions select stable conversations and trim messages', () {
    final state = AppState(role: UserRole.tenant);
    final first = state.contactRoom(state.rooms.first);
    expect(state.contactRoom(state.rooms.first), same(first));
    final length = first.messages.length;
    state.send(first, '   ');
    expect(first.messages.length, length);
    state.send(first, '  Chào cô!  ');
    expect(first.messages.last.text, 'Chào cô!');
    state.dispose();
  });
  testWidgets(
    'Save in details updates saved collection and contact opens chat',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState(role: UserRole.tenant);
      await tester.pumpWidget(
        PhongTroXanhApp(state: state, initialScreen: 'detail'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RoomDetailScreen), findsOneWidget);
      await tester.tap(find.text('Lưu').last);
      await tester.pumpAndSettle();
      expect(state.saved, contains('r1'));
      await tester.tap(find.text('Liên hệ').last);
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
      final field = find.byType(TextField).last;
      await tester.enterText(field, 'Cho mình hỏi phòng còn trống không?');
      await tester.pump();
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(
        state.conversations.first.messages.last.text,
        'Cho mình hỏi phòng còn trống không?',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    },
  );
  testWidgets('Reviews are unavailable before confirmed check-in', (
    tester,
  ) async {
    final state = AppState(role: UserRole.tenant);
    await tester.pumpWidget(MaterialApp(home: ReviewScreen(state: state)));
    await tester.pumpAndSettle();
    expect(find.text('Cần xác nhận thuê trước'), findsOneWidget);
    expect(find.text('Gửi đánh giá'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });
  for (final screen in [
    'welcome',
    'login',
    'discover',
    'detail',
    'roommate',
    'messages',
    'chat',
    'profile',
    'landlord',
    'admin',
  ]) {
    testWidgets('$screen fits small phone and scaled text', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final originalError = FlutterError.onError;
      FlutterError.onError = (details) {
        debugPrint(details.toString());
        originalError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalError);
      final state = AppState(role: UserRole.tenant);
      await tester.pumpWidget(
        PhongTroXanhApp(state: state, initialScreen: screen, demoPreview: true),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$screen initial layout');
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$screen with large text');
      tester.view.physicalSize = const Size(812, 375);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '$screen landscape with large text',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    });
  }
}
