import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets.dart';
import '../../domain/models.dart';

Uri? directionsUri(Room room) {
  final lat = room.latitude, lng = room.longitude;
  if (lat == null ||
      lng == null ||
      !lat.isFinite ||
      !lng.isFinite ||
      lat.abs() > 90 ||
      lng.abs() > 180) {
    return null;
  }
  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '$lat,$lng',
  });
}

class DirectionsButton extends StatefulWidget {
  final Room room;
  final Future<bool> Function(Uri)? launcher;
  const DirectionsButton({super.key, required this.room, this.launcher});
  @override
  State<DirectionsButton> createState() => _DirectionsButtonState();
}

class _DirectionsButtonState extends State<DirectionsButton> {
  bool busy = false;
  String? error;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (error != null)
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(error!)),
      PrimaryButton(
        'Chỉ đường đến phòng',
        outline: true,
        busy: busy,
        onTap: busy
            ? null
            : () async {
                final uri = directionsUri(widget.room);
                if (uri == null) {
                  setState(
                    () => error = 'Phòng chưa có tọa độ hợp lệ. Hãy liên hệ chủ trọ để được hướng dẫn.',
                  );
                  return;
                }
                setState(() {
                  busy = true;
                  error = null;
                });
                try {
                  final opened =
                      await (widget.launcher?.call(uri) ??
                          launchUrl(uri, mode: LaunchMode.externalApplication));
                  if (!opened && mounted) {
                    setState(
                      () => error = 'Chưa mở được ứng dụng bản đồ. Hãy thử lại hoặc liên hệ chủ trọ.',
                    );
                  }
                } catch (_) {
                  if (mounted) {
                    setState(
                      () => error = 'Chưa mở được chỉ đường. Hãy thử lại.',
                    );
                  }
                } finally {
                  if (mounted) setState(() => busy = false);
                }
              },
      ),
    ],
  );
}
