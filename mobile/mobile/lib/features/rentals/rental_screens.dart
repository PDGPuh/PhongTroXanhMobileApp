import 'dart:math' as math;

import 'rental_workflows.dart';
import 'qr_scan_screen.dart';
import '../../core/async_resource.dart';
export 'rental_workflows.dart';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../core/reference_photo.dart';
import '../../domain/models.dart';
import '../rooms/room_screens.dart';

class CheckInScreen extends StatefulWidget {
  final AppState state;
  const CheckInScreen({super.key, required this.state});
  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool camera = true, success = false;
  Rental? received;
  String? error;
  String? selectedRentalId;
  bool busy = false;
  final code = TextEditingController();
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> check(String value) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.state.workflows.run(
        'check-in',
        () => widget.state.checkIn(value, rentalId: selectedRentalId),
      );
      if (!mounted) return;
      setState(() {
        error = result;
        success = result == null;
        if (success) {
          received = widget.state.rentals
              .where((r) => r.code.toUpperCase() == value.trim().toUpperCase())
              .firstOrNull;
        }
      });
    } on RepositoryFailure catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final lockViewport =
          constraints.maxHeight >= 520 &&
          textScale <= 1.25 &&
          MediaQuery.viewInsetsOf(context).bottom == 0;
      final minContentHeight = lockViewport
          ? math.max(0.0, constraints.maxHeight - 10)
          : 0.0;
      final scannerHeight = (constraints.maxHeight - 340).clamp(135.0, 390.0);
      final successPhotoHeight = (constraints.maxHeight - 430).clamp(
        130.0,
        360.0,
      );
      return ListView(
        physics: lockViewport
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: minContentHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Header(
                      unreadNotifications: widget.state.unreadNotifications,
                      onMap: () =>
                          openPage(context, MapScreen(state: widget.state)),
                      onNotifications: () => message(
                        context,
                        'Mã nhận phòng do chủ trọ cung cấp',
                      ),
                    ),
                    PageHeading(
                      success ? 'Nhận phòng thành công!' : 'Nhận phòng',
                      success
                          ? 'Chào mừng bạn đến không gian sống mới'
                          : 'Quét QR hoặc nhập mã từ chủ trọ để nhận phòng',
                    ),
                    if (!success) ...[
                      if (widget.state.rentals.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          initialValue: selectedRentalId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Chọn hợp đồng nhận phòng',
                          ),
                          items: widget.state.rentals
                              .where((r) => r.status == RentalStatus.active)
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r.id,
                                  child: Text(
                                    '${r.id} • ${r.room.title}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: busy
                              ? null
                              : (id) => setState(() {
                                  selectedRentalId = id;
                                  error = null;
                                }),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              'Quét QR',
                              icon: LucideIcons.scanLine,
                              outline: !camera,
                              onTap: () => setState(() => camera = true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: PrimaryButton(
                              'Nhập mã',
                              icon: LucideIcons.keyboard,
                              outline: camera,
                              onTap: () => setState(() => camera = false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                if (success) ...[
                  const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      LucideIcons.circleCheck,
                      size: 42,
                      color: PT.green,
                    ),
                  ),
                  RoomCard(
                    room: received!.room,
                    photoHeight: successPhotoHeight,
                    saved: widget.state.isSaved(received!.room.id),
                    onSave: () => widget.state.toggleSave(received!.room.id),
                    onInfo: () => openPage(
                      context,
                      RoomDetailScreen(
                        state: widget.state,
                        room: received!.room,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          'Xem phòng đang thuê',
                          onTap: () => openPage(
                            context,
                            RentalsScreen(state: widget.state),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PrimaryButton(
                          'Viết đánh giá',
                          outline: true,
                          onTap: () => openPage(
                            context,
                            ReviewScreen(
                              state: widget.state,
                              rentalId: received!.id,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: camera
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                  minHeight: scannerHeight,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: PT.card(color: PT.mint),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      LucideIcons.scanLine,
                                      size: 46,
                                      color: PT.green,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Hướng camera vào mã QR của chủ trọ',
                                      style: PT.body(12, PT.muted),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          onPressed: busy
                                              ? null
                                              : () async {
                                                  final revision = widget
                                                      .state
                                                      .workflows
                                                      .epoch;
                                                  final scanned =
                                                      await Navigator.push<
                                                        String
                                                      >(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              const QrScanScreen(),
                                                        ),
                                                      );
                                                  if (!mounted ||
                                                      revision !=
                                                          widget
                                                              .state
                                                              .workflows
                                                              .epoch) {
                                                    return;
                                                  }
                                                  if (scanned == null) {
                                                    setState(
                                                      () => camera = false,
                                                    );
                                                    return;
                                                  }
                                                  code.text = scanned;
                                                  await check(scanned);
                                                },
                                          child: const Text(
                                            'Mở camera để quét QR',
                                          ),
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          onPressed: busy
                                              ? null
                                              : () {
                                                  final r = widget.state.rentals
                                                      .where(
                                                        (r) =>
                                                            r.id ==
                                                            selectedRentalId,
                                                      )
                                                      .firstOrNull;
                                                  if (r == null) {
                                                    setState(
                                                      () => error =
                                                          'Chọn hợp đồng trước khi thử mã mẫu.',
                                                    );
                                                  } else {
                                                    check(r.code);
                                                  }
                                                },
                                          child: const Text('Thử quét mã mẫu'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Cho phép camera khi mở màn quét; nếu từ chối bạn vẫn có thể nhập mã.',
                                style: PT.body(11, PT.muted),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: code,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: InputDecoration(
                                  labelText: 'Mã nhận phòng',
                                  hintText: 'PTX-2026',
                                  errorText: error,
                                ),
                              ),
                              const SizedBox(height: 10),
                              PrimaryButton(
                                'Xác nhận nhận phòng',
                                busy: busy,
                                onTap: busy ? null : () => check(code.text),
                              ),
                            ],
                          ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (error != null && camera)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(error!, style: PT.body(12, PT.red)),
                        ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: PT.card(color: PT.mint, radius: 11),
                        child: Text(
                          'Mã do chủ trọ cung cấp khi bạn đến nhận phòng. Mỗi mã chỉ sử dụng được một lần.',
                          style: PT.body(11, PT.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}

class RentalsScreen extends StatelessWidget {
  final AppState state;
  final String? rentalId;
  const RentalsScreen({super.key, required this.state, this.rentalId});
  @override
  Widget build(BuildContext context) => BasicPage(
    title: 'Lịch sử nhận phòng',
    child: state.rentals.isEmpty
        ? const EmptyState(
            'Chưa có phòng đang thuê',
            'Nhận phòng bằng QR hoặc mã do chủ trọ cung cấp.',
            icon: LucideIcons.house,
          )
        : ListView(
            padding: const EdgeInsets.all(14),
            children: state.rentals
                .where((r) => rentalId == null || r.id == rentalId)
                .map(
                  (r) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: PT.card(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: const ReferencePhoto(height: 120),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(r.room.title, style: PT.title(18)),
                            ),
                            const SizedBox(width: 8),
                            Pill(
                              r.checkedIn ? 'Đã nhận phòng' : 'Chờ nhận phòng',
                              icon: LucideIcons.badgeCheck,
                              color: PT.green,
                              dense: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        PrimaryButton(
                          'Viết đánh giá',
                          outline: true,
                          onTap: () => openPage(
                            context,
                            ReviewScreen(state: state, rentalId: r.id),
                          ),
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          'Yêu cầu hoán đổi',
                          icon: LucideIcons.arrowLeftRight,
                          onTap: () => openPage(
                            context,
                            SwapScreen(state: state, rentalId: r.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
  );
}
