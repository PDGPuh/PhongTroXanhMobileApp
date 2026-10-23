import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/reference_photo.dart';
import '../../core/theme.dart';

class WelcomeCarousel extends StatefulWidget {
  final double? height;
  const WelcomeCarousel({super.key, this.height});
  @override
  State<WelcomeCarousel> createState() => _WelcomeCarouselState();
}

class _WelcomeCarouselState extends State<WelcomeCarousel> {
  final controller = PageController();
  int index = 0;
  static const slides = [
    (
      PhotoKind.room,
      'Studio ban công xanh • Quận 10',
      'Match 96% • 3,5tr/tháng',
      'Chủ trọ xác thực',
    ),
    (
      PhotoKind.woman,
      'Minh Anh, 21 • ĐH Bách Khoa',
      'Match 94% • Hợp lối sống',
      'Đã xác thực CCCD',
    ),
    (
      PhotoKind.illustration,
      'Đặt lịch & Ký hợp đồng số',
      '100% Minh bạch chi phí',
      'Bảo vệ tiền cọc',
    ),
  ];
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h =
        widget.height ??
        (MediaQuery.sizeOf(context).height * 0.36).clamp(180.0, 360.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: PT.deep.withValues(alpha: .08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: h,
            child: Stack(
              children: [
                PageView(
                  controller: controller,
                  onPageChanged: (i) => setState(() => index = i),
                  children: [
                    for (final slide in slides)
                      Stack(
                        fit: StackFit.expand,
                        children: [
                          ReferencePhoto(kind: slide.$1),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0.0, 0.45, 1.0],
                                colors: [
                                  Color(0x1F000000),
                                  Color(0x00000000),
                                  Color(0xCC0D261E),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .92),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.favorite_rounded,
                                    size: 13,
                                    color: PT.green,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    slide.$3,
                                    style: PT
                                        .body(11.5, PT.deep)
                                        .copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 68,
                            bottom: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.shieldCheck,
                                      size: 13.5,
                                      color: Color(0xFF6EE7B7),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        slide.$4,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: PT
                                            .body(12, const Color(0xFFA7F3D0))
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  slide.$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PT
                                      .title(18)
                                      .copyWith(
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  right: 14,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .28),
                      ),
                    ),
                    child: Text(
                      '${index + 1}/${slides.length}',
                      style: PT
                          .body(11.5, Colors.white)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < slides.length; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => controller.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == index ? 24 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == index
                          ? PT.green
                          : PT.green.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
