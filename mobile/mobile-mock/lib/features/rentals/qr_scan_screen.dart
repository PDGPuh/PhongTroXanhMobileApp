import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});
  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen>
    with WidgetsBindingObserver {
  MobileScannerController? controller;
  String? error;
  bool returned = false, starting = false;
  bool get supported =>
      kIsWeb ||
      [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      ].contains(defaultTargetPlatform);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (supported) {
      controller = MobileScannerController(
        autoStart: false,
        formats: [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => start());
    }
  }

  Future<void> start() async {
    if (!mounted ||
        starting ||
        returned ||
        controller == null ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }
    setState(() {
      starting = true;
      error = null;
    });
    try {
      await controller!.start();
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Chưa mở được camera. Hãy cấp quyền camera hoặc quay lại nhập mã.',
        );
      }
    } finally {
      if (mounted) setState(() => starting = false);
    }
  }

  Future<void> stop() async {
    try {
      await controller?.stop();
    } catch (_) {
      /* Camera may already be released. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!(controller?.value.hasCameraPermission ?? false)) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(start());
    } else {
      unawaited(stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(controller?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  Future<void> detected(BarcodeCapture capture) async {
    if (returned || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    final code = capture.barcodes
        .map((b) => b.rawValue?.trim())
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .firstOrNull;
    if (code == null) return;
    returned = true;
    await stop();
    if (mounted) Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) => BasicPage(
    title: 'Quét QR nhận phòng',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Hướng camera vào QR của hợp đồng nhận phòng. Quét mã chưa xác nhận nhận phòng cho đến khi kiểm tra mã thành công.',
        ),
        const SizedBox(height: 20),
        if (supported)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 300,
              child: MobileScanner(
                controller: controller,
                onDetect: detected,
                errorBuilder: (context, failure) => Container(
                  color: PT.mint,
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      failure.errorCode ==
                              MobileScannerErrorCode.permissionDenied
                          ? 'Quyền camera bị từ chối. Bạn có thể cấp quyền trong cài đặt hoặc nhập mã thủ công.'
                          : 'Camera chưa sẵn sàng. Hãy thử lại hoặc nhập mã thủ công.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          const EmptyState(
            'Thiết bị chưa hỗ trợ quét QR',
            'Hãy nhập mã nhận phòng hoặc sử dụng điện thoại.',
            icon: LucideIcons.scanLine,
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(error!, style: PT.body(14, PT.error)),
          ),
        const SizedBox(height: 20),
        if (supported)
          PrimaryButton(
            'Thử lại camera',
            outline: true,
            busy: starting,
            onTap: starting ? null : start,
          ),
        const SizedBox(height: 12),
        PrimaryButton('Quay lại nhập mã', onTap: () => Navigator.pop(context)),
      ],
    ),
  );
}
