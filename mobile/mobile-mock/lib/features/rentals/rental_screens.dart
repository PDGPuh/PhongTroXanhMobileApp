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
import '../../demo/models.dart';
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
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    children: [
      Header(
        unreadNotifications: widget.state.unreadNotifications,
        onMap: () => openPage(context, MapScreen(state: widget.state)),
        onNotifications: () =>
            message(context, 'Mã nhận phòng do chủ trọ cung cấp'),
      ),
      PageHeading(
        success ? 'Nhận phòng thành công!' : 'Nhận phòng',
        success
            ? 'Chào mừng bạn đến không gian sống mới'
            : 'Quét QR hoặc nhập mã từ chủ trọ để nhận phòng',
      ),
      if (success) ...[
        const Padding(
          padding: EdgeInsets.all(16),
          child: Icon(LucideIcons.circleCheck, size: 70, color: PT.green),
        ),
        RoomCard(
          room: received!.room,
          saved: widget.state.isSaved(received!.room.id),
          onSave: () => widget.state.toggleSave(received!.room.id),
          onInfo: () => openPage(
            context,
            RoomDetailScreen(state: widget.state, room: received!.room),
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          'Xem phòng đang thuê',
          onTap: () => openPage(context, RentalsScreen(state: widget.state)),
        ),
        const SizedBox(height: 10),
        PrimaryButton(
          'Viết đánh giá',
          outline: true,
          onTap: () => openPage(
            context,
            ReviewScreen(state: widget.state, rentalId: received!.id),
          ),
        ),
      ] else ...[
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
          const SizedBox(height: 16),
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
            const SizedBox(width: 10),
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
        const SizedBox(height: 22),
        if (camera) ...[
          Container(
            constraints: const BoxConstraints(minHeight: 270),
            padding: const EdgeInsets.all(16),
            decoration: PT.card(color: PT.mint),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.scanLine, size: 90, color: PT.green),
                const SizedBox(height: 20),
                Text(
                  'Hướng camera vào mã QR của chủ trọ',
                  style: PT.body(13, PT.muted),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final revision = widget.state.workflows.epoch;
                          final scanned = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QrScanScreen(),
                            ),
                          );
                          if (!mounted ||
                              revision != widget.state.workflows.epoch) {
                            return;
                          }
                          if (scanned == null) {
                            setState(() => camera = false);
                            return;
                          }
                          code.text = scanned;
                          await check(scanned);
                        },
                  child: const Text('Mở camera để quét QR'),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () {
                          final r = widget.state.rentals
                              .where((r) => r.id == selectedRentalId)
                              .firstOrNull;
                          if (r == null) {
                            setState(
                              () =>
                                  error = 'Chọn hợp đồng trước khi thử mã mẫu.',
                            );
                          } else {
                            check(r.code);
                          }
                        },
                  child: const Text('Thử quét mã mẫu'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Cho phép camera khi mở màn quét; nếu từ chối bạn vẫn có thể nhập mã.',
            style: PT.body(12, PT.muted),
          ),
        ] else ...[
          TextField(
            controller: code,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Mã nhận phòng',
              hintText: 'PTX-2026',
              errorText: error,
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            'Xác nhận nhận phòng',
            busy: busy,
            onTap: busy ? null : () => check(code.text),
          ),
        ],
        if (error != null && camera)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(error!, style: PT.body(13, PT.red)),
          ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: PT.card(color: PT.mint),
          child: Text(
            'Mã do chủ trọ cung cấp khi bạn đến nhận phòng. Mỗi mã chỉ sử dụng được một lần.',
            style: PT.body(14, PT.muted),
          ),
        ),
      ],
    ],
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
            padding: const EdgeInsets.all(16),
            children: state.rentals
                .where((r) => rentalId == null || r.id == rentalId)
                .map(
                  (r) => Container(
                    padding: const EdgeInsets.all(14),
                    decoration: PT.card(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: const ReferencePhoto(height: 160),
                        ),
                        const SizedBox(height: 14),
                        Text(r.room.title, style: PT.title(23)),
                        const SizedBox(height: 9),
                        Pill(
                          r.checkedIn ? 'Đã nhận phòng' : 'Chờ nhận phòng',
                          icon: LucideIcons.badgeCheck,
                          color: PT.green,
                        ),
                        const SizedBox(height: 14),
                        PrimaryButton(
                          'Viết đánh giá',
                          outline: true,
                          onTap: () => openPage(
                            context,
                            ReviewScreen(state: state, rentalId: r.id),
                          ),
                        ),
                        const SizedBox(height: 10),
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
