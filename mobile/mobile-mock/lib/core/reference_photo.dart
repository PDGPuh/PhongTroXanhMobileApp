import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Renders only the photographic portion of an unchanged reference asset.
/// All controls and text are native Flutter widgets, never screenshot overlays.
enum PhotoKind {
  room,
  woman,
  man,
  host,
  illustration,
  google,
  apple,
  facebook,
  logo,
}

class ReferencePhoto extends StatefulWidget {
  final PhotoKind kind;
  final double? height;
  final String? label;
  const ReferencePhoto({
    super.key,
    this.kind = PhotoKind.room,
    this.height,
    this.label,
  });
  @override
  State<ReferencePhoto> createState() => _ReferencePhotoState();
}

class _ReferencePhotoState extends State<ReferencePhoto> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _info;
  String get asset => switch (widget.kind) {
    PhotoKind.room || PhotoKind.logo => 'welcome',
    PhotoKind.woman => 'roommate',
    PhotoKind.man => 'messages',
    PhotoKind.host => 'messages',
    PhotoKind.illustration ||
    PhotoKind.google ||
    PhotoKind.apple ||
    PhotoKind.facebook => 'login',
  };
  Rect get region => switch (widget.kind) {
    PhotoKind.room => const Rect.fromLTWH(147, 775, 649, 315),
    PhotoKind.logo => const Rect.fromLTWH(148, 168, 83, 79),
    PhotoKind.woman => const Rect.fromLTWH(147, 646, 551, 244),
    PhotoKind.man => const Rect.fromLTWH(149, 785, 106, 106),
    PhotoKind.host => const Rect.fromLTWH(150, 332, 109, 106),
    PhotoKind.illustration => const Rect.fromLTWH(116, 1275, 709, 329),
    PhotoKind.google => const Rect.fromLTWH(184, 1107, 40, 42),
    PhotoKind.apple => const Rect.fromLTWH(412, 1105, 36, 44),
    PhotoKind.facebook => const Rect.fromLTWH(609, 1104, 49, 49),
  };
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(ReferencePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _info?.dispose();
      _info = null;
      _resolve();
    }
  }

  void _resolve() {
    _unsubscribe();
    _stream = AssetImage('assets/references/$asset.png')
        .resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener((info, _) {
      if (!mounted) {
        info.dispose();
        return;
      }
      setState(() {
        _info?.dispose();
        _info = info;
      });
    });
    _stream!.addListener(_listener!);
  }

  void _unsubscribe() {
    if (_listener != null) {
      _stream?.removeListener(_listener!);
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        widget.label ??
        switch (widget.kind) {
          PhotoKind.room => 'Studio sáng thoáng với cây xanh và ban công',
          PhotoKind.woman => 'Ảnh đại diện bạn ở ghép',
          PhotoKind.man => 'Ảnh đại diện cá nhân',
          PhotoKind.host => 'Ảnh đại diện chủ trọ',
          PhotoKind.illustration => 'Minh họa ngôi nhà và cây xanh',
          PhotoKind.logo => 'Logo Phòng Trọ Xanh',
          PhotoKind.google => 'Google',
          PhotoKind.apple => 'Apple',
          PhotoKind.facebook => 'Facebook',
        },
    image: true,
    child: SizedBox(
      height: widget.height,
      child: _info == null
          ? const ColoredBox(color: Color(0xFFEAF9F4))
          : CustomPaint(
              painter: _PhotoPainter(_info!.image, region),
              child: const SizedBox.expand(),
            ),
    ),
  );
}

class _PhotoPainter extends CustomPainter {
  final ui.Image image;
  final Rect source;
  _PhotoPainter(this.image, this.source);
  @override
  void paint(Canvas canvas, Size size) {
    final fit = applyBoxFit(BoxFit.cover, source.size, size);
    final crop = Alignment.center.inscribe(fit.source, source);
    canvas.drawImageRect(
      image,
      crop,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(_PhotoPainter old) =>
      old.image != image || old.source != source;
}
