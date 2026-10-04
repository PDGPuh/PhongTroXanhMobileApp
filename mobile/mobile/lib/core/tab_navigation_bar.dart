import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'theme.dart';

class TabNavigationBar extends StatelessWidget {
  final int index, labelLines;
  final List<String> labels;
  final List<IconData> icons;
  final int? unreadIndex;
  final ValueChanged<int> onSelected;
  const TabNavigationBar({
    super.key,
    required this.index,
    required this.labels,
    required this.icons,
    required this.labelLines,
    required this.onSelected,
    this.unreadIndex,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: PT.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 7),
          child: Stack(
            children: [
              Row(
                children: List.generate(
                  labels.length,
                  (i) => Expanded(
                    child: Semantics(
                      button: true,
                      selected: index == i,
                      label:
                          '${labels[i]}${unreadIndex == i ? ', có tin nhắn chưa đọc' : ''}',
                      excludeSemantics: true,
                      onTap: () => onSelected(i),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: const Size(48, 48),
                        pressedOpacity: .65,
                        onPressed: () => onSelected(i),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: index == i ? 1 : 0,
                            end: index == i ? 1 : 0,
                          ),
                          duration: reduced
                              ? Duration.zero
                              : PT.navFeedbackDuration,
                          curve: PT.tabMotionCurve,
                          builder: (context, value, _) {
                            final color = Color.lerp(
                              PT.muted,
                              PT.green,
                              value,
                            )!;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Transform.scale(
                                      scale: reduced ? 1 : 1 + .06 * value,
                                      child: Icon(
                                        icons[i],
                                        color: color,
                                        size: 24,
                                      ),
                                    ),
                                    if (unreadIndex == i)
                                      Positioned(
                                        right: -3,
                                        top: -2,
                                        child: Container(
                                          width: 7,
                                          height: 7,
                                          decoration: const BoxDecoration(
                                            color: PT.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height:
                                      MediaQuery.textScalerOf(context)
                                          .scale(12) *
                                      1.4 *
                                      labelLines,
                                  child: Text(
                                    labels[i],
                                    style: PT
                                        .caption(color)
                                        .copyWith(fontWeight: FontWeight.w500),
                                    maxLines: labelLines,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 7.5),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 4,
                height: 2.5,
                child: IgnorePointer(
                  child: AnimatedAlign(
                    key: const ValueKey('tab-selection-indicator'),
                    duration: reduced ? Duration.zero : PT.tabMotionDuration,
                    curve: PT.tabMotionCurve,
                    alignment: Alignment(
                      -1 + 2 * index / (labels.length - 1),
                      0,
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 1 / labels.length,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: PT.green,
                            borderRadius: BorderRadius.circular(2),
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
    );
  }
}
