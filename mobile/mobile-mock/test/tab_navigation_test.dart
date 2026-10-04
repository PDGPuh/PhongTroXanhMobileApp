import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phong_tro_xanh_mobile/app/app.dart';
import 'package:phong_tro_xanh_mobile/app/app_state.dart';
import 'package:phong_tro_xanh_mobile/core/tab_navigation_bar.dart';
import 'package:phong_tro_xanh_mobile/core/tab_transition.dart';
import 'package:phong_tro_xanh_mobile/core/theme.dart';
import 'package:phong_tro_xanh_mobile/demo/models.dart';

class CounterPage extends StatefulWidget {
  final int id;
  const CounterPage(this.id, {super.key});
  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int count = 0;
  final draft = TextEditingController();
  @override
  void dispose() {
    draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      TextField(key: ValueKey('field-${widget.id}'), controller: draft),
      TextButton(
        onPressed: () => setState(() => count++),
        child: Text('Page ${widget.id}: $count'),
      ),
      for (var i = 0; i < 30; i++) SizedBox(height: 60, child: Text('Row $i')),
    ],
  );
}

Widget host(int index, {bool reduced = false}) => MaterialApp(
  theme: PT.theme,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(
      body: TabTransitionStack(
        index: index,
        children: List.generate(
          5,
          (i) => CounterPage(i, key: ValueKey('page-$i')),
        ),
      ),
    ),
  ),
);

double opacity(WidgetTester tester, int i) => tester
    .widget<Opacity>(
      find.byKey(ValueKey('tab-opacity-$i'), skipOffstage: false),
    )
    .opacity;

void main() {
  testWidgets('Switching tabs preserves edits, local state and scroll offset', (
    tester,
  ) async {
    await tester.pumpWidget(host(0));
    await tester.enterText(
      find.byKey(const ValueKey('field-0')),
      'Giữ bản nháp',
    );
    await tester.tap(find.text('Page 0: 0'));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final scroll = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey('page-0')),
            matching: find.byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            ),
          )
          .first,
    );
    scroll.position.jumpTo(360);
    await tester.pumpAndSettle();
    final offset = scroll.position.pixels;
    expect(offset, greaterThan(0));
    await tester.pumpWidget(host(3));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(0));
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, closeTo(offset, .01));
    final retained = tester.state<_CounterPageState>(
      find.byKey(const ValueKey('page-0')),
    );
    expect(retained.draft.text, 'Giữ bản nháp');
    expect(retained.count, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'An interrupted switch continues from the current painted frame',
    (tester) async {
      await tester.pumpWidget(host(0));
      await tester.pumpWidget(host(4));
      await tester.pump(const Duration(milliseconds: 80));
      final first = opacity(tester, 0), last = opacity(tester, 4);
      expect(first, inExclusiveRange(0, 1));
      expect(last, inExclusiveRange(0, 1));
      await tester.pumpWidget(host(2));
      expect(opacity(tester, 0), closeTo(first, .0001));
      expect(opacity(tester, 4), closeTo(last, .0001));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pumpWidget(host(1));
      await tester.pumpAndSettle();
      expect(opacity(tester, 1), 1);
      for (final i in [0, 2, 3, 4]) {
        expect(opacity(tester, i), 0);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Outgoing tabs cannot receive taps, focus or screen reader actions',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(4));
        await tester.tap(find.text('Page 4: 0'));
        await tester.pumpWidget(host(0));
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.semantics.byLabel('Page 4: 1'), findsNothing);
        await tester.tap(find.text('Page 0: 0'));
        await tester.pumpAndSettle();
        expect(find.text('Page 0: 1'), findsOneWidget);
        await tester.pumpWidget(host(4));
        await tester.pumpAndSettle();
        expect(find.text('Page 4: 1'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'Reduce Motion snaps an in-flight transition and later switches',
    (tester) async {
      await tester.pumpWidget(host(0));
      await tester.pumpWidget(host(4));
      await tester.pump(const Duration(milliseconds: 70));
      await tester.pumpWidget(host(4, reduced: true));
      expect(opacity(tester, 4), 1);
      expect(opacity(tester, 0), 0);
      await tester.pumpWidget(host(1, reduced: true));
      expect(opacity(tester, 1), 1);
      expect(opacity(tester, 4), 0);
      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  testWidgets('All five real tabs respond to rapid taps; the last tap wins', (
    tester,
  ) async {
    final state = AppState(role: UserRole.tenant);
    addTearDown(state.dispose);
    await tester.pumpWidget(
      PhongTroXanhApp(state: state, initialScreen: 'discover'),
    );
    await tester.pumpAndSettle();
    for (final i in [1, 2, 3, 4, 0, 4]) {
      final buttons = find.descendant(
        of: find.byType(TabNavigationBar),
        matching: find.byType(CupertinoButton),
      );
      await tester.tap(buttons.at(i));
      await tester.pump(const Duration(milliseconds: 45));
    }
    await tester.pumpAndSettle();
    expect(
      tester.widget<TabNavigationBar>(find.byType(TabNavigationBar)).index,
      4,
    );
    expect(
      find.text('Quản lý thông tin và hành trình của bạn'),
      findsOneWidget,
    );
    expect(opacity(tester, 4), 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Leaving a tab during a swipe cancels its quota and saved-room commit',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState(role: UserRole.tenant);
      addTearDown(state.dispose);
      await tester.pumpWidget(
        PhongTroXanhApp(state: state, initialScreen: 'discover'),
      );
      await tester.pumpAndSettle();
      final quota = state.roomQuota;
      await tester.tap(find.byTooltip('Lưu phòng').first);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(
        find
            .descendant(
              of: find.byType(TabNavigationBar),
              matching: find.byType(CupertinoButton),
            )
            .at(4),
      );
      await tester.pumpAndSettle();
      expect(state.roomQuota, quota);
      expect(state.saved, isEmpty);
      await tester.tap(
        find
            .descendant(
              of: find.byType(TabNavigationBar),
              matching: find.byType(CupertinoButton),
            )
            .at(0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Lưu phòng').first);
      await tester.pumpAndSettle();
      expect(state.roomQuota, quota - 1);
      expect(state.saved, contains('r1'));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
