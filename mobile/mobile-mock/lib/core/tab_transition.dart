import 'package:flutter/material.dart';

import 'theme.dart';

/// Inactive tabs retain their state but cannot receive input or commit gestures.
class TabActivity extends InheritedWidget {
  final bool active;
  const TabActivity({super.key, required this.active, required super.child});

  static bool isActiveOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabActivity>()?.active ?? true;

  @override
  bool updateShouldNotify(TabActivity oldWidget) => active != oldWidget.active;
}

class _TabFrame {
  final double opacity, dx;
  const _TabFrame(this.opacity, this.dx);
  static const hidden = _TabFrame(0, 0);
  static const selected = _TabFrame(1, 0);

  _TabFrame towards(_TabFrame other, double progress) => _TabFrame(
    opacity + (other.opacity - opacity) * progress,
    dx + (other.dx - dx) * progress,
  );
}

/// Keeps visited tabs mounted. Interrupted transitions resume from the painted
/// positions instead of queuing taps or flashing back to the previous screen.
class TabTransitionStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  const TabTransitionStack({
    super.key,
    required this.index,
    required this.children,
  }) : assert(index >= 0 && index < children.length);

  @override
  State<TabTransitionStack> createState() => _TabTransitionStackState();
}

class _TabTransitionStackState extends State<TabTransitionStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  late Map<int, _TabFrame> _from, _to;
  final Set<int> _visited = {};
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _visited.add(widget.index);
    _from = _to = {widget.index: _TabFrame.selected};
    _motion = AnimationController(
      vsync: this,
      duration: PT.tabMotionDuration,
      value: 1,
    );
  }

  void _snap() {
    _from = _to = {widget.index: _TabFrame.selected};
    _motion.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) _snap();
  }

  _TabFrame _frame(int i) => (_from[i] ?? _TabFrame.hidden).towards(
    _to[i] ?? _TabFrame.hidden,
    PT.tabMotionCurve.transform(_motion.value),
  );

  @override
  void didUpdateWidget(TabTransitionStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited.add(widget.index);
    if (widget.index == oldWidget.index &&
        widget.children.length == oldWidget.children.length) {
      return;
    }
    if (_reducedMotion || widget.children.length != oldWidget.children.length) {
      _snap();
      return;
    }
    final direction = widget.index > oldWidget.index ? 1.0 : -1.0;
    final painted = <int, _TabFrame>{
      for (var i = 0; i < widget.children.length; i++)
        if (_frame(i).opacity > 0) i: _frame(i),
    };
    painted.putIfAbsent(widget.index, () => _TabFrame(0, direction * 14));
    _motion.stop();
    _from = painted;
    _to = {
      for (final i in painted.keys)
        i: i == widget.index
            ? _TabFrame.selected
            : _TabFrame(0, -direction * 14),
    };
    _motion.forward(from: 0);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedBuilder(
      animation: _motion,
      builder: (context, _) => Stack(
        fit: StackFit.expand,
        children: List.generate(widget.children.length, (i) {
          final frame = _frame(i);
          final active = i == widget.index;
          return Offstage(
            key: ValueKey('tab-layer-$i'),
            offstage: !active && frame.opacity <= 0,
            child: IgnorePointer(
              ignoring: !active,
              child: ExcludeSemantics(
                excluding: !active,
                child: Focus(
                  canRequestFocus: false,
                  descendantsAreFocusable: active,
                  descendantsAreTraversable: active,
                  child: TickerMode(
                    enabled: active,
                    child: TabActivity(
                      active: active,
                      child: PrimaryScrollController.none(
                        child: Transform.translate(
                          key: ValueKey('tab-transform-$i'),
                          offset: Offset(frame.dx, 0),
                          child: Opacity(
                            key: ValueKey('tab-opacity-$i'),
                            opacity: frame.opacity.clamp(0, 1),
                            alwaysIncludeSemantics: active,
                            child: RepaintBoundary(
                              child: _visited.contains(i)
                                  ? widget.children[i]
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );
}
