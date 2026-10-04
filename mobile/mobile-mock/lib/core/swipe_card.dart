import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';
import 'tab_transition.dart';

/// Gesture presentation only. The caller commits the action after [swipe]
/// completes, and owns authentication, quotas and the current card identity.
class SwipeCard extends StatefulWidget {
  final Object identity;
  final Widget child;
  final Widget? next;
  final String positiveLabel;
  final ValueChanged<bool> onSwipeRequested;

  const SwipeCard({
    super.key,
    required this.identity,
    required this.child,
    required this.onSwipeRequested,
    this.next,
    this.positiveLabel = 'LƯU',
  });

  @override
  State<SwipeCard> createState() => SwipeCardState();
}

class SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  late final AnimationController _motion =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 260),
      )..addListener(() {
        setState(() {
          _dx =
              _from +
              (_to - _from) * Curves.easeOutCubic.transform(_motion.value);
        });
      });
  late final AnimationController _arrival = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  late final Animation<double> _arrivalOpacity = _arrival.drive(
    Tween<double>(begin: .65, end: 1),
  );
  late final Animation<double> _arrivalScale = _arrival
      .drive(CurveTween(curve: Curves.easeOutCubic))
      .drive(Tween<double>(begin: .97, end: 1));
  double _dx = 0, _from = 0, _to = 0, _width = 320;
  bool _exiting = false;
  bool _pointerCancelled = false;

  bool get _reducedMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void didUpdateWidget(SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.identity != widget.identity) {
      _motion.stop();
      _dx = 0;
      _exiting = false;
      if (_reducedMotion) {
        _arrival.value = 1;
      } else {
        _arrival.forward(from: 0);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TabActivity.isActiveOf(context)) {
      _motion.stop(canceled: true);
      _dx = 0;
      _exiting = false;
      _arrival.value = 1;
    }
    if (_reducedMotion) _arrival.value = 1;
  }

  @override
  void dispose() {
    _motion.dispose();
    _arrival.dispose();
    super.dispose();
  }

  /// Returns false if the card changed or was disposed during the animation.
  Future<bool> swipe(bool positive) async {
    if (_exiting) return false;
    final identity = widget.identity;
    _exiting = true;
    if (_reducedMotion) {
      setState(() => _dx = 0);
      return true;
    }
    _motion.stop();
    _from = _dx;
    _to = (positive ? 1 : -1) * (_width * 1.5 + 100);
    _motion.duration = const Duration(milliseconds: 260);
    try {
      await _motion.forward(from: 0).orCancel;
      return mounted && widget.identity == identity;
    } on TickerCanceled {
      return false;
    }
  }

  void reset() {
    if (!mounted) return;
    _exiting = false;
    _settle();
  }

  void _settle() {
    _motion.stop();
    if (_reducedMotion || !TabActivity.isActiveOf(context)) {
      setState(() => _dx = 0);
      return;
    }
    _from = _dx;
    _to = 0;
    _motion.duration = const Duration(milliseconds: 200);
    _motion.forward(from: 0);
  }

  void _release(DragEndDetails details) {
    // Flutter can deliver DragEndDetails for a cancelled pointer after the
    // recognizer has won the arena. That must never become a saved card.
    if (_pointerCancelled) {
      _settle();
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    final enoughDistance = _dx.abs() >= (_width * .28).clamp(80, 140);
    final flick =
        velocity.abs() >= 700 && _dx.abs() >= 24 && velocity.sign == _dx.sign;
    if (enoughDistance || flick) widget.onSwipeRequested(_dx > 0);
    // A guest's login prompt must not leave a dragged card stuck off centre.
    if (!_exiting) _settle();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _width = constraints.maxWidth;
      final progress = (_dx.abs() / (_width * .4)).clamp(0.0, 1.0);
      final positive = _dx >= 0;
      final color = positive ? PT.green : PT.red;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          if (widget.next != null)
            Positioned.fill(
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: Transform.scale(
                    scale: _reducedMotion ? 1 : .96 + progress * .04,
                    child: Opacity(
                      opacity: .6 + progress * .4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          minHeight: 0,
                          maxHeight: double.infinity,
                          child: widget.next,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Listener(
            onPointerDown: (_) => _pointerCancelled = false,
            onPointerCancel: (_) => _pointerCancelled = true,
            child: GestureDetector(
              onHorizontalDragStart: _exiting
                  ? null
                  : (_) {
                      _motion.stop();
                      _arrival.value = 1;
                    },
              onHorizontalDragUpdate: _exiting
                  ? null
                  : (details) {
                      setState(() => _dx += details.delta.dx);
                    },
              onHorizontalDragEnd: _exiting ? null : _release,
              onHorizontalDragCancel: _exiting ? null : _settle,
              child: Transform.translate(
                key: const ValueKey('swipe-card-transform'),
                offset: _reducedMotion ? Offset.zero : Offset(_dx, 0),
                child: Transform.rotate(
                  angle: _reducedMotion
                      ? 0
                      : (_dx / _width * .16).clamp(-.22, .22),
                  child: FadeTransition(
                    opacity: _arrivalOpacity,
                    child: ScaleTransition(
                      scale: _arrivalScale,
                      child: AbsorbPointer(
                        absorbing: _exiting,
                        child: Stack(
                          children: [
                            // Keep InkWell highlights in the moving card's
                            // coordinate space instead of the page Material.
                            Material(
                              type: MaterialType.transparency,
                              child: widget.child,
                            ),
                            if (progress > 0)
                              Positioned(
                                top: 60,
                                left: positive ? 18 : null,
                                right: positive ? null : 18,
                                child: IgnorePointer(
                                  child: ExcludeSemantics(
                                    child: Opacity(
                                      opacity: progress,
                                      child: Transform.rotate(
                                        angle:
                                            (positive ? -1 : 1) * math.pi / 24,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: .96,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: color,
                                              width: 2,
                                            ),
                                          ),
                                          child: Text(
                                            positive
                                                ? widget.positiveLabel
                                                : 'BỎ QUA',
                                            style: PT
                                                .body(20, color)
                                                .copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
