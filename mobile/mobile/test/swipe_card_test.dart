import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phong_tro_xanh_mobile/app/app_state.dart';
import 'package:phong_tro_xanh_mobile/app/navigation.dart';
import 'package:phong_tro_xanh_mobile/core/swipe_card.dart';
import 'package:phong_tro_xanh_mobile/core/theme.dart';
import 'package:phong_tro_xanh_mobile/core/widgets.dart';
import 'package:phong_tro_xanh_mobile/domain/models.dart';
import 'package:phong_tro_xanh_mobile/features/rooms/room_screens.dart';

Widget deck({
  required GlobalKey<SwipeCardState> key,
  required ValueChanged<bool> onSwipe,
  Object identity = 'first',
  bool reducedMotion = false,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reducedMotion),
    child: Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: SwipeCard(
            key: key,
            identity: identity,
            onSwipeRequested: onSwipe,
            next: const SizedBox(height: 260, child: Text('Next card')),
            child: Container(
              height: 220,
              color: Colors.white,
              child: const Center(child: Text('Current card')),
            ),
          ),
        ),
      ),
    ),
  ),
);

double translation(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(const ValueKey('swipe-card-transform')))
    .transform
    .storage[12];

Future<TestGesture> pull(WidgetTester tester, double distance) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byType(SwipeCard)),
  );
  await gesture.moveBy(Offset(distance.sign * 20, 0));
  await tester.pump();
  await gesture.moveBy(Offset(distance / 2, 0));
  await tester.pump(const Duration(milliseconds: 100));
  await gesture.moveBy(Offset(distance / 2, 0));
  await tester.pump(const Duration(milliseconds: 500));
  return gesture;
}

Widget discover(AppState state, {bool person = false, VoidCallback? login}) =>
    MaterialApp(
      theme: PT.theme,
      home: Scaffold(
        body: AppScope(
          state: state,
          requestLogin: (_, _) => login?.call(),
          logout: () {},
          child: ListenableBuilder(
            listenable: state,
            builder: (_, _) => DiscoverScreen(state: state, person: person),
          ),
        ),
      ),
    );

Future<void> phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'Card follows the drag, shows intent and returns on a short drag',
    (tester) async {
      final key = GlobalKey<SwipeCardState>();
      final actions = <bool>[];
      await tester.pumpWidget(deck(key: key, onSwipe: actions.add));
      final gesture = await pull(tester, 60);
      expect(translation(tester), greaterThan(0));
      expect(find.text('LƯU'), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(translation(tester), closeTo(0, .01));
      expect(actions, isEmpty);
      expect(find.text('LƯU'), findsNothing);
    },
  );

  for (final direction in [1, -1]) {
    testWidgets(
      'Slow distance swipe $direction commits once after the flight',
      (tester) async {
        final key = GlobalKey<SwipeCardState>();
        final actions = <bool>[];
        await tester.pumpWidget(
          deck(
            key: key,
            onSwipe: (like) async {
              if (await key.currentState!.swipe(like)) actions.add(like);
            },
          ),
        );
        final gesture = await pull(tester, 180.0 * direction);
        await gesture.up();
        expect(actions, isEmpty);
        await tester.pumpAndSettle();
        expect(actions, [direction > 0]);
      },
    );
  }

  testWidgets('Cancelled drag restores the card without an action', (
    tester,
  ) async {
    final key = GlobalKey<SwipeCardState>();
    final actions = <bool>[];
    await tester.pumpWidget(deck(key: key, onSwipe: actions.add));
    final gesture = await pull(tester, -120);
    expect(find.text('BỎ QUA'), findsOneWidget);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(translation(tester), closeTo(0, .01));
    expect(actions, isEmpty);
  });

  testWidgets(
    'Replacing a card cancels its pending flight and excludes the next card semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final key = GlobalKey<SwipeCardState>();
      await tester.pumpWidget(deck(key: key, onSwipe: (_) {}));
      expect(find.bySemanticsLabel('Next card'), findsNothing);
      final flight = key.currentState!.swipe(true);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpWidget(
        deck(key: key, identity: 'replacement', onSwipe: (_) {}),
      );
      expect(await flight, isFalse);
      await tester.pumpAndSettle();
      expect(translation(tester), closeTo(0, .01));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'Reduced motion preserves the swipe action without moving the card',
    (tester) async {
      final key = GlobalKey<SwipeCardState>();
      final actions = <bool>[];
      await tester.pumpWidget(
        deck(
          key: key,
          reducedMotion: true,
          onSwipe: (like) async {
            if (await key.currentState!.swipe(like)) actions.add(like);
          },
        ),
      );
      final gesture = await pull(tester, 180);
      expect(translation(tester), 0);
      await gesture.up();
      await tester.pump();
      expect(actions, [true]);
      expect(translation(tester), 0);
    },
  );

  testWidgets(
    'Save button blocks duplicate taps, advances one room and undo restores its quota',
    (tester) async {
      await phone(tester);
      final state = AppState(role: UserRole.tenant);
      addTearDown(state.dispose);
      state.filters('Tất cả', 'Tất cả', 10000000);
      final id = state.filteredRooms.first.id;
      final quota = state.roomQuota;
      await tester.pumpWidget(discover(state));
      await tester.pumpAndSettle();
      final save = find.byWidgetPredicate(
        (w) => w is RoundButton && w.label == 'Lưu phòng',
      );
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.tap(save);
      expect(state.roomIndex, 0);
      await tester.pumpAndSettle();
      expect(state.roomIndex, 1);
      expect(state.saved, contains(id));
      expect(state.roomQuota, quota - 1);
      final undo = find.byWidgetPredicate(
        (w) => w is RoundButton && w.label == 'Hoàn tác',
      );
      await tester.ensureVisible(undo);
      await tester.tap(undo);
      await tester.pumpAndSettle();
      expect(state.roomIndex, 0);
      expect(state.roomQuota, quota);
      expect(state.saved, isNot(contains(id)));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Roommate swipe likes the displayed person and shows its confirmation',
    (tester) async {
      await phone(tester);
      final state = AppState(role: UserRole.tenant);
      addTearDown(state.dispose);
      final candidate = state.filteredPeople.first;
      final quota = state.roommateQuota;
      await tester.pumpWidget(discover(state, person: true));
      await tester.pumpAndSettle();
      final gesture = await pull(tester, 180);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(state.liked, contains(candidate.id));
      expect(state.personIndex, 1);
      expect(state.roommateQuota, quota - 1);
      expect(find.text('Đã gửi lời thích!'), findsOneWidget);
      expect(find.textContaining(candidate.name).last, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Guest swipe asks for login and snaps back without consuming quota',
    (tester) async {
      await phone(tester);
      final state = AppState();
      addTearDown(state.dispose);
      var loginRequests = 0;
      await tester.pumpWidget(discover(state, login: () => loginRequests++));
      await tester.pumpAndSettle();
      final quota = state.roomQuota;
      final gesture = await pull(tester, 180);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(loginRequests, 1);
      expect(state.roomIndex, 0);
      expect(state.roomQuota, quota);
      expect(state.saved, isEmpty);
      expect(translation(tester), closeTo(0, .01));
    },
  );

  testWidgets(
    'Filter or account changes during a flight cannot apply a stale swipe',
    (tester) async {
      await phone(tester);
      final state = AppState(role: UserRole.tenant);
      addTearDown(state.dispose);
      await tester.pumpWidget(discover(state));
      await tester.pumpAndSettle();
      final quota = state.roomQuota;
      final gesture = await pull(tester, 180);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 80));
      state.filters('Tất cả', 'Tất cả', 10000000);
      await tester.pumpAndSettle();
      expect(state.roomIndex, 0);
      expect(state.roomQuota, quota);
      expect(state.saved, isEmpty);
      final secondGesture = await pull(tester, 180);
      await secondGesture.up();
      await tester.pump(const Duration(milliseconds: 80));
      state.logout();
      await tester.pumpAndSettle();
      expect(state.roomIndex, 0);
      expect(state.saved, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Vertical scrolling on a card does not consume a swipe', (
    tester,
  ) async {
    await phone(tester);
    tester.view.physicalSize = const Size(390, 812);
    final state = AppState(role: UserRole.tenant);
    addTearDown(state.dispose);
    await tester.pumpWidget(discover(state));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(SwipeCard), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(state.roomIndex, 0);
    expect(state.saved, isEmpty);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      greaterThan(0),
    );
  });
}
