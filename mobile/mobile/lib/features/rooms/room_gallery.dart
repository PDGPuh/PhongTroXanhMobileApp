import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/reference_photo.dart';
import '../../core/device_media.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';

/// Uses the room's actual image list. A single fixture image counts as 1/1.
class RoomGallery extends StatefulWidget {
  final Room room;
  final double height;
  final bool allowSwipe;
  const RoomGallery({
    super.key,
    required this.room,
    this.height = 270,
    this.allowSwipe = true,
  });
  @override
  State<RoomGallery> createState() => _RoomGalleryState();
}

class _RoomGalleryState extends State<RoomGallery> {
  int index = 0;
  final pager = PageController();
  @override
  void dispose() {
    pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.room.imageCount;
    if (count == 0) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: Text('Chưa có ảnh phòng')),
      );
    }
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: pager,
            physics: widget.allowSwipe
                ? null
                : const NeverScrollableScrollPhysics(),
            itemCount: count,
            onPageChanged: (i) => setState(() => index = i),
            itemBuilder: (_, i) => InkWell(
              onTap: widget.allowSwipe
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            _GalleryViewer(room: widget.room, initial: i),
                      ),
                    )
                  : null,
              child: RoomPhoto(room: widget.room, index: i),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${index + 1}/$count',
                style: PT.body(13, Colors.white),
              ),
            ),
          ),
          if (count > 1)
            Positioned(
              bottom: 12,
              left: 12,
              child: RoundButton(
                icon: LucideIcons.chevronRight,
                label: 'Ảnh phòng tiếp theo',
                background: Colors.white,
                onTap: () => pager.animateToPage(
                  (index + 1) % count,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GalleryViewer extends StatefulWidget {
  final Room room;
  final int initial;
  const _GalleryViewer({required this.room, required this.initial});
  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final pager = PageController(initialPage: widget.initial);
  late int index = widget.initial;
  @override
  void dispose() {
    pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: PT.deep,
    appBar: AppBar(
      title: Text('Ảnh ${index + 1}/${widget.room.imageCount}'),
      leading: IconButton(
        tooltip: 'Đóng ảnh',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(LucideIcons.x),
      ),
    ),
    body: SafeArea(
      child: PageView.builder(
        controller: pager,
        itemCount: widget.room.imageCount,
        onPageChanged: (i) => setState(() => index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: AspectRatio(
              aspectRatio: 1.4,
              child: RoomPhoto(room: widget.room, index: i),
            ),
          ),
        ),
      ),
    ),
  );
}

class RoomPhoto extends StatelessWidget {
  final Room room;
  final int index;
  const RoomPhoto({super.key, required this.room, this.index = 0});
  @override
  Widget build(BuildContext context) {
    final label = '${room.title}, ảnh ${index + 1}/${room.imageCount}';
    if (index < room.images.length) {
      return ReferencePhoto(kind: room.images[index], label: label);
    }
    final offset = index - room.images.length;
    if (offset < 0 || offset >= room.localPhotos.length) {
      return const Center(child: Text('Chưa có ảnh phòng'));
    }
    return LocalPhotoView(photo: room.localPhotos[offset], label: label);
  }
}
