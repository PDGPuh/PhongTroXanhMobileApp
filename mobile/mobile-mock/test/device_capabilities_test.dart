import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:phong_tro_xanh_mobile/app/app_state.dart';
import 'package:phong_tro_xanh_mobile/core/async_resource.dart';
import 'package:phong_tro_xanh_mobile/core/device_media.dart';
import 'package:phong_tro_xanh_mobile/core/theme.dart';
import 'package:phong_tro_xanh_mobile/demo/models.dart';
import 'package:phong_tro_xanh_mobile/features/account/account_screens.dart';
import 'package:phong_tro_xanh_mobile/features/landlord/landlord_screens.dart';
import 'package:phong_tro_xanh_mobile/features/rentals/qr_scan_screen.dart';
import 'package:phong_tro_xanh_mobile/features/rooms/directions_button.dart';
import 'package:phong_tro_xanh_mobile/features/rooms/room_gallery.dart';

final Uint8List png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
LocalPhoto picture(String id) =>
    LocalPhoto(id: id, name: '$id.png', bytes: png);

class FakePicker implements MediaPicker {
  List<LocalPhoto> value = [];
  MediaFailure? error;
  Completer<List<LocalPhoto>>? pending;
  @override
  Future<List<LocalPhoto>> pick({
    bool multiple = false,
    bool camera = false,
  }) async {
    if (error != null) throw error!;
    return pending?.future ?? value;
  }
}

AppState demo(FakePicker picker, [UserRole role = UserRole.tenant]) => AppState(
  role: role,
  mediaPicker: picker,
  transport: DemoTransport(delay: Duration.zero),
);
Future<void> mount(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(MaterialApp(theme: PT.theme, home: page));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, String text) async {
  if (find.text(text).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(text),
      250,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
  }
  await tester.ensureVisible(find.text(text).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> expectQrData(WidgetTester tester, String data) async {
  final qrFinder = find.byType(QrImageView);
  final view = tester.widget<QrImageView>(qrFinder);
  final paintFinder = find.descendant(
    of: qrFinder,
    matching: find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is QrPainter,
    ),
  );
  final actual = tester.widget<CustomPaint>(paintFinder).painter! as QrPainter;
  final expected = QrPainter(
    data: data,
    version: view.version,
    errorCorrectionLevel: view.errorCorrectionLevel,
    gapless: view.gapless,
    eyeStyle: view.eyeStyle,
    dataModuleStyle: view.dataModuleStyle,
  );
  // Compare the rendered QR pattern, rather than the visible text beside it.
  await tester.runAsync(() async {
    final actualImage = await actual.toImageData(256);
    final expectedImage = await expected.toImageData(256);
    expect(actualImage, isNotNull);
    expect(expectedImage, isNotNull);
    expect(
      actualImage!.buffer.asUint8List(),
      expectedImage!.buffer.asUint8List(),
      reason: 'The displayed QR must encode the selected contract code.',
    );
  });
}

void main() {
  test('Cancel and permission failure leave media unchanged', () async {
    final picker = FakePicker();
    final s = demo(picker);
    addTearDown(s.dispose);
    expect(await s.pickMedia(), isEmpty);
    expect(s.store.workspace(s.session.user!).media, isEmpty);
    picker.error = const MediaFailure('Quyền bị từ chối');
    await expectLater(s.pickMedia(), throwsA(isA<MediaFailure>()));
    expect(s.store.workspace(s.session.user!).media, isEmpty);
  });
  test(
    'Late photo result after logout is not assigned to a different account',
    () async {
      final picker = FakePicker()..pending = Completer<List<LocalPhoto>>();
      final s = demo(picker);
      addTearDown(s.dispose);
      final tenant = s.session.user!;
      final pending = s.pickMedia();
      s.logout();
      await s.authenticate('tenant2@demo.vn', 'demo123');
      picker.pending!.complete([picture('photo-late')]);
      await expectLater(pending, throwsA(isA<MediaFailure>()));
      expect(s.store.workspace(tenant).media, isEmpty);
      expect(s.store.workspace(s.session.user!).media, isEmpty);
    },
  );
  test(
    'CCCD references must be owned; admin sees exact submitted images',
    () async {
      final picker = FakePicker()
        ..value = [picture('photo-a'), picture('photo-b')];
      final s = demo(picker);
      addTearDown(s.dispose);
      await s.pickMedia(multiple: true);
      await s.authenticate('tenant2@demo.vn', 'demo123');
      expect(s.ownPhoto('photo-a'), isNull);
      await expectLater(
        s.workflows.submitKyc('012345678901', 'photo-a', 'photo-b'),
        throwsA(isA<RepositoryFailure>()),
      );
      expect(s.store.kyc, isEmpty);
      await s.authenticate('tenant@demo.vn', 'demo123');
      final k = await s.workflows.submitKyc(
        '012345678901',
        'photo-a',
        'photo-b',
      );
      await s.authenticate('admin@demo.vn', 'demo123');
      expect(s.store.workspaceById(k.userId).media[k.front]!.bytes, png);
      expect(s.store.workspaceById(k.userId).media[k.back]!.id, 'photo-b');
    },
  );
  test('Corrupt and oversize images are rejected before storage', () async {
    await expectLater(
      DeviceMediaPicker.validate(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<MediaFailure>()),
    );
    await expectLater(
      DeviceMediaPicker.validate(Uint8List(DeviceMediaPicker.maxBytes + 1)),
      throwsA(isA<MediaFailure>()),
    );
  });
  testWidgets('Decoder accepts a valid PNG', (tester) async {
    await tester.runAsync(() => DeviceMediaPicker.validate(png));
  });
  testWidgets(
    'Native profile photo remains draft until saved and canceled picker retains it',
    (tester) async {
      final picker = FakePicker()..value = [picture('photo-avatar')];
      final s = demo(picker);
      addTearDown(s.dispose);
      await mount(tester, EditProfileScreen(state: s));
      await tapVisible(tester, 'Chọn ảnh đại diện từ thiết bị');
      await tapVisible(tester, 'Chọn từ thư viện');
      expect(s.store.profiles[s.userId]!.avatarPhoto, isNull);
      expect(find.byType(LocalPhotoView), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await mount(tester, EditProfileScreen(state: s));
      expect(find.byType(LocalPhotoView), findsOneWidget);
      picker.value = [];
      await tapVisible(tester, 'Chọn ảnh đại diện từ thiết bị');
      await tapVisible(tester, 'Chọn từ thư viện');
      expect(find.byType(LocalPhotoView), findsOneWidget);
      await tapVisible(tester, 'Lưu thay đổi');
      expect(s.store.profiles[s.userId]!.avatarPhoto!.id, 'photo-avatar');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'CCCD device picker can remove a photo and submit both actual refs',
    (tester) async {
      final picker = FakePicker()..value = [picture('photo-front')];
      final s = demo(picker);
      addTearDown(s.dispose);
      await mount(tester, VerificationScreen(state: s));
      await tester.enterText(find.byType(TextField), '012345678901');
      await tapVisible(tester, 'Chọn ảnh Mặt trước từ thiết bị');
      await tapVisible(tester, 'Chọn từ thư viện');
      await tapVisible(tester, 'Xóa ảnh Mặt trước');
      expect(find.byType(LocalPhotoView), findsNothing);
      await tapVisible(tester, 'Chọn ảnh Mặt trước từ thiết bị');
      await tapVisible(tester, 'Chọn từ thư viện');
      picker.value = [picture('photo-back')];
      await tapVisible(tester, 'Chọn ảnh Mặt sau từ thiết bị');
      await tapVisible(tester, 'Chọn từ thư viện');
      await tapVisible(tester, 'Gửi xác minh');
      expect(s.store.kyc.single.front, 'photo-front');
      expect(s.store.kyc.single.back, 'photo-back');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('Submitted document preview is denied to another tenant', (
    tester,
  ) async {
    final picker = FakePicker()..value = [picture('photo-identity')];
    final s = demo(picker);
    addTearDown(s.dispose);
    await tester.runAsync(() => s.pickMedia());
    await tester.runAsync(() => s.authenticate('tenant2@demo.vn', 'demo123'));
    await mount(
      tester,
      VerificationDocument(
        state: s,
        userId: 'tenant-a',
        reference: 'photo-identity',
        side: 'Mặt trước',
      ),
    );
    expect(find.byType(LocalPhotoView), findsNothing);
    expect(find.text('Bạn không có quyền xem giấy tờ này.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'Room gallery uses device photos in actual count, pager and fullscreen',
    (tester) async {
      final room = Room(
        id: 'actual',
        title: 'Ảnh thật',
        district: 'Quận 3',
        price: 1000000,
        images: const [],
        localPhotos: [picture('one'), picture('two')],
      );
      await mount(tester, Scaffold(body: RoomGallery(room: room)));
      expect(find.text('1/2'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-700, 0));
      await tester.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);
      await tester.tap(find.byType(LocalPhotoView).last);
      await tester.pumpAndSettle();
      expect(find.text('Ảnh 2/2'), findsOneWidget);
      expect(room.copyWith(status: RoomStatus.pending).localPhotos.length, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'Room editor keeps selected photos in draft without changing published record',
    (tester) async {
      final picker = FakePicker()..value = [picture('photo-room')];
      final s = demo(picker, UserRole.landlord);
      addTearDown(s.dispose);
      final room = s.myRooms.first;
      await mount(tester, PostRoomScreen(state: s, existing: room));
      await tapVisible(tester, 'Tiếp tục');
      await tapVisible(tester, 'Tiếp tục');
      await tapVisible(tester, 'Chọn ảnh phòng từ thiết bị');
      await tapVisible(tester, 'Chọn từ thư viện');
      expect(s.roomById(room.id)!.localPhotos, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await mount(tester, PostRoomScreen(state: s, existing: room));
      expect(find.byType(LocalPhotoView), findsOneWidget);
      await tester.tap(find.byTooltip('Xóa ảnh photo-room.png'));
      await tester.pumpAndSettle();
      expect(find.byType(LocalPhotoView), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('QR encodes selected contract B and updates after refresh', (
    tester,
  ) async {
    final s = demo(FakePicker(), UserRole.landlord);
    addTearDown(s.dispose);
    await mount(tester, LandlordQRScreen(state: s));
    await expectQrData(tester, 'PTX-2026');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.rentalById('lease-a2')!.room.title).last);
    await tester.pumpAndSettle();
    await expectQrData(tester, 'PTX-2027');
    await tapVisible(tester, 'Tạo mã mới (24 giờ)');
    final code = s.rentalById('lease-a2')!.code;
    expect(code, isNot('PTX-2027'));
    await expectQrData(tester, code);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Expired contract QR is not offered for scanning', (
    tester,
  ) async {
    final s = demo(FakePicker(), UserRole.landlord);
    addTearDown(s.dispose);
    s.rentalById('lease-a1')!.codeExpiresAt = DateTime.now().subtract(
      const Duration(seconds: 1),
    );
    await mount(tester, LandlordQRScreen(state: s));
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('Mã đã hết hạn. Hãy tạo mã mới.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'Unsupported scanner platform offers manual entry without camera initialization',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await mount(tester, const QrScanScreen());
        expect(find.text('Thiết bị chưa hỗ trợ quét QR'), findsOneWidget);
        expect(find.text('Quay lại nhập mã'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
  test(
    'Directions use exact coordinates and reject missing/invalid values',
    () {
      const room = Room(
        id: 'map',
        title: 'Map B',
        district: 'Thủ Đức',
        price: 1,
        latitude: 10.802,
        longitude: 106.73,
      );
      expect(
        directionsUri(room)!.queryParameters['destination'],
        '10.802,106.73',
      );
      expect(
        directionsUri(
          const Room(
            id: 'x',
            title: 'x',
            district: 'x',
            price: 1,
            latitude: null,
            longitude: null,
          ),
        ),
        isNull,
      );
      expect(
        directionsUri(
          const Room(
            id: 'x',
            title: 'x',
            district: 'x',
            price: 1,
            latitude: 300,
          ),
        ),
        isNull,
      );
    },
  );
  testWidgets(
    'Map launch failure stays visible and can be retried without switching room',
    (tester) async {
      var calls = 0;
      Uri? target;
      const room = Room(
        id: 'map-b',
        title: 'B',
        district: 'Thủ Đức',
        price: 1,
        latitude: 10.81,
        longitude: 106.73,
      );
      await mount(
        tester,
        Scaffold(
          body: DirectionsButton(
            room: room,
            launcher: (uri) async {
              target = uri;
              calls++;
              return false;
            },
          ),
        ),
      );
      await tapVisible(tester, 'Chỉ đường đến phòng');
      expect(target!.queryParameters['destination'], '10.81,106.73');
      expect(
        find.text(
          'Chưa mở được ứng dụng bản đồ. Hãy thử lại hoặc liên hệ chủ trọ.',
        ),
        findsOneWidget,
      );
      await tapVisible(tester, 'Chỉ đường đến phòng');
      expect(calls, 2);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
