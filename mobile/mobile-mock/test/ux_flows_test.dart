import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phong_tro_xanh_mobile/app/app_state.dart';
import 'package:phong_tro_xanh_mobile/app/session.dart';
import 'package:phong_tro_xanh_mobile/core/async_resource.dart';
import 'package:phong_tro_xanh_mobile/core/theme.dart';
import 'package:phong_tro_xanh_mobile/core/reference_photo.dart';
import 'package:phong_tro_xanh_mobile/demo/models.dart';
import 'package:phong_tro_xanh_mobile/features/auth/password_recovery.dart';
import 'package:phong_tro_xanh_mobile/features/auth/recovery_screen.dart';
import 'package:phong_tro_xanh_mobile/features/rooms/room_filters.dart';
import 'package:phong_tro_xanh_mobile/features/rooms/compare_screen.dart';
import 'package:phong_tro_xanh_mobile/features/rooms/room_gallery.dart';
import 'package:phong_tro_xanh_mobile/features/rooms/room_screens.dart';
import 'package:phong_tro_xanh_mobile/features/chat/chat_screens.dart';
import 'package:phong_tro_xanh_mobile/features/account/account_screens.dart';

AppState fixture([UserRole? role]) => AppState(
  role: role,
  transport: DemoTransport(delay: Duration.zero),
);
Widget app(Widget page) => MaterialApp(theme: PT.theme, home: page);

void main() {
  test('Disposing the app while sending finishes without notifying a closed controller', () async {
    final state = AppState(
      role: UserRole.tenant,
      transport: DemoTransport(delay: const Duration(milliseconds: 10)),
    );
    final c = state.contactRoom(state.roomById('r4')!);
    final pending = state.sendAsync(c, 'Đang gửi');
    state.dispose();
    await pending;
    expect(c.messages.last.delivery, MessageDelivery.failed);
  });
  testWidgets(
    'Comparison results keep two room columns aligned at large text size',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = fixture();
      addTearDown(state.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: PT.theme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 740),
              textScaler: TextScaler.linear(1.6),
            ),
            child: CompareRoomsScreen(state: state, initialRoomId: 'r4'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Studio xanh gần Bách Khoa'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      await tester.tap(find.text('So sánh 2 phòng'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(Table),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(Table), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  test(
    'OTP rejects wrong/expired/reused tokens and changes real demo credentials',
    () async {
      var now = DateTime(2026, 10, 2);
      final repo = DemoAuthRepository(
        transport: DemoTransport(delay: Duration.zero),
        now: () => now,
      );
      await repo.sendOtp('tenant@demo.vn');
      final first = repo.demoOtp('tenant@demo.vn')!;
      await expectLater(
        repo.verifyOtp('tenant@demo.vn', '000000'),
        throwsA(isA<RepositoryFailure>()),
      );
      await expectLater(
        repo.sendOtp('tenant@demo.vn'),
        throwsA(isA<RepositoryFailure>()),
      );
      now = now.add(const Duration(minutes: 6));
      await expectLater(
        repo.verifyOtp('tenant@demo.vn', first),
        throwsA(isA<RepositoryFailure>()),
      );
      await repo.sendOtp('tenant@demo.vn');
      expect(repo.demoOtp('tenant@demo.vn'), isNot(first));
      final token = await repo.verifyOtp(
        'tenant@demo.vn',
        repo.demoOtp('tenant@demo.vn')!,
      );
      await repo.resetPassword(token, 'newpass456');
      await expectLater(
        repo.resetPassword(token, 'other456'),
        throwsA(isA<RepositoryFailure>()),
      );
      await expectLater(
        repo.signIn('tenant@demo.vn', 'demo123'),
        throwsA(isA<RepositoryFailure>()),
      );
      expect(
        (await repo.signIn('tenant@demo.vn', 'newpass456')).id,
        'tenant-a',
      );
    },
  );
  test(
    'Recovery retains email, handles cooldown and offline without advancing',
    () async {
      var now = DateTime(2026, 10, 2);
      final transport = DemoTransport(delay: Duration.zero);
      final repo = DemoAuthRepository(transport: transport, now: () => now);
      final c = PasswordRecoveryController(repo, now: () => now);
      addTearDown(c.dispose);
      transport.fault = DemoFault.offline;
      expect(await c.send('tenant@demo.vn'), isFalse);
      expect(c.step, 0);
      transport.fault = DemoFault.none;
      expect(await c.send(' TENANT@demo.vn '), isTrue);
      expect(c.resendSeconds, 60);
      expect(await c.send(c.email), isFalse);
      expect(await c.verify('000000'), isFalse);
      expect(c.step, 1);
      expect(await c.verify(repo.demoOtp(c.email)!), isTrue);
      c.back();
      expect(c.email, 'tenant@demo.vn');
      c.changeEmail();
      expect(c.step, 0);
      expect(await c.reset('newpass456', 'newpass456'), isFalse);
      now = now.add(const Duration(seconds: 61));
      expect(await c.send('tenant@demo.vn'), isTrue);
    },
  );
  test(
    'Room comparison refuses missing/private IDs and retries after offline',
    () async {
      final state = fixture();
      addTearDown(state.dispose);
      final c = RoomComparisonController(state.roomController.repository);
      addTearDown(c.dispose);
      await c.compare(['r1', 'r1']);
      expect(c.result.phase, ResourcePhase.error);
      await c.compare(['r1', 'missing']);
      expect(c.result.error!.kind, DemoFault.missing);
      await c.compare(['r1', 'r2']);
      expect(c.result.error!.kind, DemoFault.denied);
      state.transport.fault = DemoFault.offline;
      await c.compare(['r1', 'r4']);
      expect(c.result.data, isNull);
      state.transport.fault = DemoFault.none;
      await c.compare(['r4', 'r1']);
      expect(c.result.data!.map((r) => r.id), ['r4', 'r1']);
      expect(c.result.data!.first.price, 4500000);
    },
  );
  test(
    'Failed message stays in conversation; repeated retry has one stable ID',
    () async {
      final state = fixture(UserRole.tenant);
      addTearDown(state.dispose);
      final c = state.contactRoom(state.roomById('r4')!);
      state.transport.fault = DemoFault.offline;
      await state.sendAsync(c, '  Xin chào  ');
      final failed = c.messages.last;
      expect(failed.text, 'Xin chào');
      expect(failed.delivery, MessageDelivery.failed);
      state.transport.fault = DemoFault.none;
      await Future.wait([
        state.sendAsync(c, '', retryId: failed.id),
        state.sendAsync(c, '', retryId: failed.id),
      ]);
      expect(c.messages.where((m) => m.id == failed.id).length, 1);
      expect(c.messages.last.delivery, MessageDelivery.sent);
      expect(state.conversations.first, same(c));
      state.toggleConversationMute(c.id);
      expect(state.conversationMuted(c.id), isTrue);
    },
  );
  test(
    'Sending after logout cannot reach another account or become sent',
    () async {
      final state = AppState(
        role: UserRole.tenant,
        transport: DemoTransport(delay: const Duration(milliseconds: 10)),
      );
      addTearDown(state.dispose);
      final c = state.contactRoom(state.roomById('r4')!);
      final send = state.sendAsync(c, 'Chỉ tài khoản A');
      state.logout();
      await send;
      expect(c.messages.last.delivery, MessageDelivery.failed);
      await state.authenticate('tenant2@demo.vn', 'demo123');
      expect(state.conversations, isEmpty);
    },
  );
  test(
    'Notifications preserve target IDs and read status per account',
    () async {
      final state = fixture(UserRole.tenant);
      addTearDown(state.dispose);
      expect(state.unreadNotifications, 3);
      final notification = state.notifications.first;
      expect(notification.target!.id, 'c1');
      state.readNotification(notification.id);
      expect(state.unreadNotifications, 2);
      state.logout();
      await state.authenticate('landlord2@demo.vn', 'demo123');
      expect(state.conversations, isEmpty);
      expect(state.notifications.length, 1);
      expect(state.notifications.single.verification, isTrue);
      state.logout();
      await state.authenticate('tenant@demo.vn', 'demo123');
      expect(state.notifications.first.read, isTrue);
    },
  );
  testWidgets('Recovery finishes all four steps and new password signs in', (
    tester,
  ) async {
    final state = fixture();
    addTearDown(state.dispose);
    await tester.pumpWidget(app(ForgotPasswordScreen(state: state)));
    await tester.enterText(find.byType(TextFormField), 'tenant@demo.vn');
    await tester.tap(find.text('Gửi mã OTP'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập mã OTP'), findsOneWidget);
    final code = (state.session.repository as DemoAuthRepository).demoOtp(
      'tenant@demo.vn',
    )!;
    await tester.enterText(find.byType(TextFormField), code);
    await tester.tap(find.text('Xác minh OTP'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'password789');
    await tester.enterText(find.byType(TextFormField).last, 'wrongpassword');
    await tester.tap(find.text('Cập nhật mật khẩu'));
    await tester.pumpAndSettle();
    expect(find.text('Mật khẩu xác nhận chưa khớp'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, 'password789');
    await tester.tap(find.text('Cập nhật mật khẩu'));
    await tester.pumpAndSettle();
    expect(find.text('Đã đổi mật khẩu'), findsOneWidget);
    expect(
      await tester.runAsync(
        () => state.authenticate('tenant@demo.vn', 'password789'),
      ),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Filter drafts never mutate results until valid apply', (
    tester,
  ) async {
    final state = fixture();
    addTearDown(state.dispose);
    await tester.pumpWidget(app(const Scaffold(body: SizedBox())));
    final context = tester.element(find.byType(Scaffold));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RoomFilterSheet(state: state),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Thảo Điền');
    expect(state.roomController.query, isEmpty);
    await tester.enterText(find.byType(TextFormField).at(1), '6000000');
    await tester.enterText(find.byType(TextFormField).at(2), '3000000');
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();
    expect(
      find.text('Giá tối đa phải từ giá tối thiểu trở lên'),
      findsOneWidget,
    );
    expect(state.roomController.query, isEmpty);
    await tester.tap(find.byTooltip('Đóng bộ lọc'));
    await tester.pumpAndSettle();
    expect(state.filteredRooms.single.id, 'r1');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RoomFilterSheet(state: state),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa bộ lọc'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Thảo Điền');
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();
    expect(state.filteredRooms.single.id, 'r4');
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Gallery counter uses real list and changes with page', (
    tester,
  ) async {
    const room = Room(
      id: 'gallery',
      title: 'Bộ ảnh',
      district: 'Quận 10',
      price: 1,
      images: [PhotoKind.room, PhotoKind.room],
    );
    await tester.pumpWidget(app(const Scaffold(body: RoomGallery(room: room))));
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-650, 0));
    await tester.pumpAndSettle();
    expect(find.text('2/2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'Chat draft restores and failed message can retry without duplication',
    (tester) async {
      final state = fixture(UserRole.tenant);
      addTearDown(state.dispose);
      final c = state.contactRoom(state.roomById('r4')!);
      state.drafts['chat-${c.id}'] = 'Nội dung nháp';
      await tester.pumpWidget(app(ChatScreen(state: state, conversation: c)));
      await tester.pumpAndSettle();
      expect(find.text('Nội dung nháp'), findsOneWidget);
      state.transport.fault = DemoFault.offline;
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa gửi • Thử lại'), findsOneWidget);
      state.transport.fault = DemoFault.none;
      await tester.tap(find.text('Chưa gửi • Thử lại'));
      await tester.pumpAndSettle();
      expect(c.messages.where((m) => m.text == 'Nội dung nháp').length, 1);
      expect(c.messages.last.delivery, MessageDelivery.sent);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('Target map preserves r4 even outside discovery price filters', (
    tester,
  ) async {
    final state = fixture();
    addTearDown(state.dispose);
    await tester.pumpWidget(app(MapScreen(state: state, roomId: 'r4')));
    await tester.pumpAndSettle();
    expect(find.text(state.roomById('r4')!.title), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final screen in ['recovery', 'filter', 'compare', 'notifications']) {
    testWidgets('$screen supports 320px and large text with keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = fixture(UserRole.landlord);
      addTearDown(state.dispose);
      final page = switch (screen) {
        'recovery' => ForgotPasswordScreen(state: state),
        'filter' => Scaffold(body: RoomFilterSheet(state: state)),
        'compare' => CompareRoomsScreen(state: state),
        _ => NotificationsScreen(state: state),
      };
      await tester.pumpWidget(
        MaterialApp(
          theme: PT.theme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 740),
              textScaler: TextScaler.linear(1.6),
              viewInsets: EdgeInsets.only(bottom: 240),
            ),
            child: page,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
