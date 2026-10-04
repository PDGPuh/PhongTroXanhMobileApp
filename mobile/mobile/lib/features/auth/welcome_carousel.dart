import 'package:flutter/material.dart';

import '../../core/reference_photo.dart';
import '../../core/theme.dart';

class WelcomeCarousel extends StatefulWidget {
  const WelcomeCarousel({super.key});
  @override
  State<WelcomeCarousel> createState() => _WelcomeCarouselState();
}

class _WelcomeCarouselState extends State<WelcomeCarousel> {
  final controller = PageController();
  int index = 0;
  static const slides = [
    (PhotoKind.room, 'Không gian sống tốt hơn\nbắt đầu từ đây'),
    (PhotoKind.woman, 'Kết nối người bạn ở\ncùng lối sống'),
    (PhotoKind.illustration, 'Hoàn thiện hồ sơ\nđể xây dựng sự tin cậy'),
  ];
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 230,
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
                        Positioned(
                          left: 10,
                          bottom: 10,
                          right: 80,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .94),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(slide.$2, style: PT.body(12)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Positioned(
                right: 9,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${index + 1}/${slides.length}',
                    style: PT.body(12, Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 6),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < slides.length; i++)
            IconButton(
              tooltip: 'Giới thiệu ${i + 1}',
              onPressed: () => controller.animateToPage(
                i,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              ),
              icon: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == index ? PT.green : PT.line,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    ],
  );
}
