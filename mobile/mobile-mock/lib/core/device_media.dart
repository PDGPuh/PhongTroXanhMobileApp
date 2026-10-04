import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'theme.dart';

/// Local preview data. Backend upload must return a server attachment ID later.
class LocalPhoto {
  final String id, name;
  final Uint8List bytes;
  const LocalPhoto({required this.id, required this.name, required this.bytes});
}

class MediaFailure implements Exception {
  final String message;
  const MediaFailure(this.message);
}

abstract class MediaPicker {
  Future<List<LocalPhoto>> pick({bool multiple = false, bool camera = false});
}

class DeviceMediaPicker implements MediaPicker {
  final ImagePicker picker;
  DeviceMediaPicker({ImagePicker? picker}) : picker = picker ?? ImagePicker();
  static const maxBytes = 10 * 1024 * 1024;
  static Future<void> validate(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw const MediaFailure('Ảnh phải nhỏ hơn 10 MB và không được rỗng.');
    }
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 128);
      final frame = await codec.getNextFrame();
      frame.image.dispose();
      codec.dispose();
    } catch (_) {
      throw const MediaFailure(
        'Không đọc được ảnh này. Hãy chọn ảnh JPG, PNG hoặc WebP.',
      );
    }
  }

  @override
  Future<List<LocalPhoto>> pick({
    bool multiple = false,
    bool camera = false,
  }) async {
    try {
      final List<XFile> files;
      if (multiple && !camera) {
        files = await picker.pickMultiImage(
          maxWidth: 2048,
          maxHeight: 2048,
          imageQuality: 85,
        );
      } else {
        final file = await picker.pickImage(
          source: camera ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 2048,
          maxHeight: 2048,
          imageQuality: 85,
          requestFullMetadata: false,
        );
        files = file == null ? [] : [file];
      }
      if (files.length > 8) {
        throw const MediaFailure('Chọn tối đa 8 ảnh mỗi lần.');
      }
      final result = <LocalPhoto>[];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        await validate(bytes);
        result.add(
          LocalPhoto(
            id: 'photo-${DateTime.now().microsecondsSinceEpoch}-${result.length}',
            name: file.name,
            bytes: bytes,
          ),
        );
      }
      return result;
    } on MediaFailure {
      rethrow;
    } on PlatformException catch (e) {
      throw MediaFailure(
        e.code.contains('denied') || e.code.contains('restricted')
            ? 'Chưa có quyền truy cập ảnh hoặc camera. Hãy cấp quyền trong cài đặt thiết bị và thử lại.'
            : 'Chưa mở được ảnh hoặc camera. Bạn có thể chọn ảnh từ thư viện và thử lại.',
      );
    } catch (_) {
      throw const MediaFailure(
        'Thiết bị chưa hỗ trợ thao tác này. Hãy chọn ảnh từ thư viện hoặc thử trên điện thoại.',
      );
    }
  }
}

/// Shows source choices without opening a camera until explicitly selected.
Future<bool?> choosePhotoSource(BuildContext context) =>
    showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, false),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh bằng camera'),
              onTap: () => Navigator.pop(ctx, true),
            ),
            ListTile(title: const Text('Hủy'), onTap: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );

class LocalPhotoView extends StatelessWidget {
  final LocalPhoto photo;
  final double? height;
  final BoxFit fit;
  final String? label;
  const LocalPhotoView({
    super.key,
    required this.photo,
    this.height,
    this.fit = BoxFit.cover,
    this.label,
  });
  @override
  Widget build(BuildContext context) => Image.memory(
    photo.bytes,
    height: height,
    width: double.infinity,
    fit: fit,
    semanticLabel: label ?? photo.name,
    errorBuilder: (_, _, _) => Container(
      height: height ?? 140,
      color: PT.mint,
      alignment: Alignment.center,
      child: const Text('Không đọc được ảnh. Hãy chọn lại.'),
    ),
  );
}
