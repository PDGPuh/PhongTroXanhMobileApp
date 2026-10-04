import 'dart:convert';

export '../rentals/rental_workflows.dart'
    show LandlordSwapsScreen, LandlordReviewsScreen, LandlordTenantsScreen;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../core/theme.dart';
import '../../core/device_media.dart';
import '../../core/widgets.dart';
import '../../core/reference_photo.dart';
import '../../demo/models.dart';
import '../rooms/room_screens.dart';
import '../rooms/room_gallery.dart';
import '../account/account_screens.dart';
import '../rentals/rental_screens.dart';

class LandlordScreen extends StatelessWidget {
  final AppState state;
  const LandlordScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    children: [
      Header(
        unreadNotifications: state.unreadNotifications,
        owner: true,
        onProfile: () => openPage(
          context,
          ProfileScreen(
            state: state,
            onLogout: () => AppScope.maybeOf(context)?.logout(),
          ),
        ),
        onMap: () => openPage(context, MapScreen(state: state)),
        onNotifications: () =>
            openPage(context, NotificationsScreen(state: state)),
      ),
      const PageHeading(
        'Chủ trọ 👋',
        'Quản lý phòng trọ hiệu quả, dễ dàng hơn mỗi ngày',
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 680 ? 4 : 2;
          final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
          final stats = <Widget>[
            _SmallStat(
              LucideIcons.house,
              '${state.myRooms.where((r) => r.status == RoomStatus.available).length}',
              'Phòng đang hiển thị',
              'Đang hoạt động',
              PT.green,
              PT.mint,
            ),
            _SmallStat(
              LucideIcons.clock,
              '${state.myRooms.where((r) => r.status == RoomStatus.pending).length}',
              'Phòng chờ duyệt',
              'Đang xử lý',
              PT.amber,
              const Color(0xFFFFF8ED),
            ),
            _SmallStat(
              LucideIcons.users,
              '${state.rentals.map((r) => r.tenantId).toSet().length}',
              'Người thuê',
              'Theo hợp đồng',
              const Color(0xFF0799DE),
              const Color(0xFFEEF8FF),
            ),
            _SmallStat(
              LucideIcons.star,
              '${state.store.reviewRecords.where((r) => state.myRooms.any((room) => room.id == r.targetId)).length}',
              'Đánh giá nhận được',
              'Từ người thuê',
              PT.green,
              PT.mint,
            ),
          ];
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final stat in stats) SizedBox(width: width, child: stat),
            ],
          );
        },
      ),
      const SizedBox(height: 8),
      Text('Số liệu minh họa trong bản demo', style: PT.caption()),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(child: Text('Hoạt động gần đây', style: PT.title(23))),
          TextButton(
            onPressed: () =>
                openPage(context, LandlordRoomsScreen(state: state)),
            child: const Text('Xem tất cả'),
          ),
        ],
      ),
      ...state.myRooms
          .take(3)
          .map((r) => _ManageRoomTile(state: state, room: r)),
      const SizedBox(height: 16),
      MenuRow(
        spacious: true,
        framed: false,
        icon: LucideIcons.users,
        title: 'Người thuê',
        subtitle: 'Hợp đồng, nhận phòng và đánh giá',
        onTap: () => openPage(context, LandlordTenantsScreen(state: state)),
      ),
      MenuRow(
        spacious: true,
        framed: false,
        icon: LucideIcons.arrowLeftRight,
        title: 'Yêu cầu đổi phòng',
        subtitle: 'Duyệt yêu cầu thuộc phòng của bạn',
        onTap: () => openPage(context, LandlordSwapsScreen(state: state)),
      ),
      PrimaryButton(
        'Đăng phòng mới',
        icon: LucideIcons.plus,
        onTap: () => openPage(context, PostRoomScreen(state: state)),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: PT.card(color: PT.mint),
        child: Row(
          children: [
            const Icon(LucideIcons.lightbulb, size: 32, color: PT.green),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mẹo cho chủ trọ', style: PT.title(17)),
                  const SizedBox(height: 5),
                  Text(
                    'Thêm hình ảnh đẹp và mô tả chi tiết sẽ giúp thu hút nhiều người quan tâm hơn!',
                    style: PT.body(14, PT.muted),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 18),
          ],
        ),
      ),
      const SizedBox(height: 20),
      MenuRow(
        spacious: true,
        framed: false,
        icon: LucideIcons.qrCode,
        title: 'Mã QR nhận phòng',
        subtitle: 'Tạo mã và chia sẻ cho người thuê',
        onTap: () => openPage(context, LandlordQRScreen(state: state)),
      ),
      MenuRow(
        spacious: true,
        framed: false,
        icon: LucideIcons.arrowLeftRight,
        title: 'Duyệt hoán đổi',
        subtitle: 'Kiểm tra các yêu cầu chuyển người ở',
        onTap: () => openPage(context, LandlordSwapsScreen(state: state)),
      ),
    ],
  );
}

class _SmallStat extends StatelessWidget {
  final IconData icon;
  final String value, label, badge;
  final Color color, bg;
  const _SmallStat(
    this.icon,
    this.value,
    this.label,
    this.badge,
    this.color,
    this.bg,
  );
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(value, style: PT.title(28))),
            ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: .09),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.textScalerOf(context).scale(14) * 1.5 * 2,
          ),
          child: Text(label, style: PT.body(13, PT.muted)),
        ),
        const SizedBox(height: 12),
        Text(
          badge,
          style: PT.body(12, PT.deep).copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}

class _ManageRoomTile extends StatelessWidget {
  final AppState state;
  final Room room;
  const _ManageRoomTile({required this.state, required this.room});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: PT.card(radius: 16),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            openPage(context, ManageRoomScreen(state: state, room: room)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 104,
                height: 96,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Positioned.fill(child: RoomPhoto(room: room)),
                      Positioned(
                        left: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: PT.mint,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            state.roomStatus[room.id] ?? 'Chờ duyệt',
                            style: PT.body(8, PT.green),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.title, style: PT.title(16)),
                    const SizedBox(height: 6),
                    Text(
                      '${room.district}, TP.HCM',
                      style: PT.body(12, PT.muted),
                    ),
                    const SizedBox(height: 6),
                    Text(room.priceLabel, style: PT.price(17)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.eye,
                              size: 12,
                              color: PT.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${state.roomViews(room.id)} lượt xem',
                              style: PT.body(11, PT.muted),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.heart,
                              size: 12,
                              color: PT.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${state.roomSaves(room.id)} lượt lưu',
                              style: PT.body(11, PT.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 17),
            ],
          ),
        ),
      ),
    ),
  );
}

class LandlordRoomsScreen extends StatelessWidget {
  final AppState state;
  final bool standalone;
  const LandlordRoomsScreen({
    super.key,
    required this.state,
    this.standalone = true,
  });
  @override
  Widget build(BuildContext context) {
    final content = ListenableBuilder(
      listenable: state,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!standalone)
            const PageHeading(
              'Quản lý phòng',
              'Thông tin phòng và trạng thái tin đăng',
            ),
          PrimaryButton(
            'Đăng phòng mới',
            icon: LucideIcons.plus,
            onTap: () => openPage(context, PostRoomScreen(state: state)),
          ),
          const SizedBox(height: 20),
          ...state.myRooms.map((r) => _ManageRoomTile(state: state, room: r)),
        ],
      ),
    );
    return standalone
        ? BasicPage(title: 'Quản lý phòng', child: content)
        : content;
  }
}

class ManageRoomScreen extends StatelessWidget implements ResourceScreen {
  @override
  ResourceRef get resource => ResourceRef(ResourceKind.room, room.id);
  final AppState state;
  final Room room;
  const ManageRoomScreen({super.key, required this.state, required this.room});
  @override
  Widget build(BuildContext context) => BasicPage(
    title: 'Quản lý tin phòng',
    child: ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final room = state.roomById(this.room.id) ?? this.room;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            RoomCard(
              room: room,
              saved: state.isSaved(room.id),
              onSave: () => state.toggleSave(room.id),
              onInfo: () =>
                  openPage(context, RoomDetailScreen(state: state, room: room)),
            ),
            const SizedBox(height: 18),
            MenuRow(
              icon: LucideIcons.pencil,
              title: 'Sửa thông tin',
              onTap: () => openPage(
                context,
                PostRoomScreen(state: state, existing: room),
              ),
            ),
            MenuRow(
              icon: LucideIcons.eyeOff,
              title: state.roomStatus[room.id] == 'Đã ẩn'
                  ? 'Hiển thị tin'
                  : 'Ẩn tin',
              onTap: state.roomById(room.id)?.status == RoomStatus.pending
                  ? null
                  : () => state.setRoomStatus(
                      room,
                      state.roomStatus[room.id] == 'Đã ẩn'
                          ? 'Đang hiển thị'
                          : 'Đã ẩn',
                    ),
            ),
            MenuRow(
              icon: LucideIcons.circleCheck,
              title: 'Đánh dấu đã cho thuê',
              onTap: state.roomById(room.id)?.status == RoomStatus.pending
                  ? null
                  : () => state.setRoomStatus(room, 'Đã cho thuê'),
            ),
            MenuRow(
              icon: LucideIcons.qrCode,
              title: 'Mã QR nhận phòng',
              onTap: () => openPage(context, LandlordQRScreen(state: state)),
            ),
            MenuRow(
              icon: LucideIcons.users,
              title: 'Người thuê',
              subtitle: 'Danh sách người đã nhận phòng',
              onTap: () => openPage(
                context,
                LandlordTenantsScreen(state: state, roomId: room.id),
              ),
            ),
            MenuRow(
              icon: LucideIcons.arrowLeftRight,
              title: 'Yêu cầu hoán đổi',
              onTap: () => openPage(context, LandlordSwapsScreen(state: state)),
            ),
            MenuRow(
              icon: LucideIcons.zap,
              title: 'Đẩy tin nổi bật',
              onTap: () => openPage(context, PackagesScreen()),
            ),
          ],
        );
      },
    ),
  );
}

class PostRoomScreen extends StatefulWidget {
  final AppState state;
  final Room? existing;
  const PostRoomScreen({super.key, required this.state, this.existing});
  @override
  State<PostRoomScreen> createState() => _PostRoomScreenState();
}

class _PostRoomScreenState extends State<PostRoomScreen> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.existing?.title ?? ''),
      price = TextEditingController(
        text: widget.existing?.price.toString() ?? '',
      ),
      area = TextEditingController(
        text: widget.existing?.area.toString() ?? '',
      ),
      address = TextEditingController(text: widget.existing?.address ?? ''),
      description = TextEditingController(
        text: widget.existing?.description ?? '',
      ),
      electricity = TextEditingController(
        text: widget.existing?.electricity ?? '3.500đ/kWh',
      ),
      water = TextEditingController(
        text: widget.existing?.water ?? '100.000đ/người',
      ),
      fees = TextEditingController(text: widget.existing?.otherFees ?? '');
  int step = 0;
  bool photo = false, submitting = false;
  bool pickingPhotos = false;
  List<LocalPhoto> localPhotos = [];
  String? submitError;
  late final newId = 'room-${DateTime.now().microsecondsSinceEpoch}';
  late final floor = TextEditingController(
    text: '${widget.existing?.floor ?? 3}',
  );
  late final latitude = TextEditingController(
    text: widget.existing?.latitude?.toString() ?? '',
  );
  late final longitude = TextEditingController(
    text: widget.existing?.longitude?.toString() ?? '',
  );
  String get draftKey => 'post-room-${widget.existing?.id ?? 'new'}';
  void saveDraft() {
    widget.state.drafts[draftKey] = jsonEncode({
      'title': title.text,
      'price': price.text,
      'area': area.text,
      'floor': floor.text,
      'latitude': latitude.text,
      'longitude': longitude.text,
      'address': address.text,
      'description': description.text,
      'electricity': electricity.text,
      'water': water.text,
      'fees': fees.text,
      'step': step,
      'photo': photo,
      'localPhotos': localPhotos.map((p) => p.id).toList(),
      'district': district,
      'type': type,
      'amenities': amenities.toList(),
    });
  }

  String district = 'Quận 10', type = 'Studio';
  final amenities = {'Có nội thất', 'Wifi riêng', 'Máy lạnh'};
  @override
  void initState() {
    super.initState();
    district = widget.existing?.district ?? district;
    type = widget.existing?.type ?? type;
    photo = widget.existing != null;
    localPhotos = [...?widget.existing?.localPhotos];
    photo = widget.existing?.images.isNotEmpty ?? false;
    Map<String, dynamic> restored = {};
    try {
      restored = jsonDecode(
        widget.state.drafts[draftKey] ?? '{}',
      ) as Map<String, dynamic>;
    } catch (_) {
      /* Obsolete draft. */
    }
    final controllers = {
      'title': title,
      'price': price,
      'area': area,
      'floor': floor,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'description': description,
      'electricity': electricity,
      'water': water,
      'fees': fees,
    };
    for (final e in controllers.entries) {
      if (restored[e.key] != null) {
        e.value.text = restored[e.key];
      }
      e.value.addListener(saveDraft);
    }
    step = (restored['step'] as int? ?? 0).clamp(0, 4);
    photo = restored['photo'] ?? photo;
    if (restored['localPhotos'] is List) {
      localPhotos = (restored['localPhotos'] as List)
          .cast<String>()
          .map(
            (id) =>
                widget.state.ownPhoto(id) ??
                widget.existing?.localPhotos
                    .where((p) => p.id == id)
                    .firstOrNull,
          )
          .whereType<LocalPhoto>()
          .toList();
    }
    district = restored['district'] ?? district;
    type = restored['type'] ?? type;
    if (widget.existing != null) {
      amenities
        ..clear()
        ..addAll(widget.existing!.amenities);
    }
    if (restored['amenities'] != null) {
      amenities
        ..clear()
        ..addAll((restored['amenities'] as List).cast<String>());
    }
    saveDraft();
  }

  @override
  void dispose() {
    for (final c in [
      floor,
      latitude,
      longitude,
      title,
      price,
      area,
      address,
      description,
      electricity,
      water,
      fees,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Room get draft => Room(
    id: widget.existing?.id ?? newId,
    title: title.text.trim(),
    floor: int.tryParse(floor.text) ?? 3,
    images: photo
        ? (widget.existing?.images.isNotEmpty ?? false)
              ? widget.existing!.images
              : const [PhotoKind.room]
        : const [],
    localPhotos: [...localPhotos],
    latitude: double.tryParse(latitude.text.trim()),
    longitude: double.tryParse(longitude.text.trim()),
    district: district,
    price: int.tryParse(price.text) ?? 0,
    area: int.tryParse(area.text) ?? 20,
    type: type,
    amenities: amenities.toList(),
    address: address.text.trim(),
    description: description.text.trim(),
    electricity: electricity.text.trim(),
    water: water.text.trim(),
    otherFees: fees.text.trim(),
  );
  @override
  Widget build(BuildContext context) => BasicPage(
    title: widget.existing == null ? 'Đăng phòng mới' : 'Sửa phòng',
    bottom: Row(
      children: [
        if (step > 0) ...[
          Expanded(
            child: PrimaryButton(
              'Quay lại',
              outline: true,
              onTap: submitting || pickingPhotos
                  ? null
                  : () {
                      setState(() => step--);
                      saveDraft();
                    },
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: PrimaryButton(
            step == 4 ? 'Gửi tin chờ duyệt' : 'Tiếp tục',
            busy: submitting,
            onTap: submitting || pickingPhotos
                ? null
                : () async {
                    if (step == 0 || step == 1 || step == 3) {
                      if (!form.currentState!.validate()) {
                        return;
                      }
                    }
                    if ((step == 2 || step == 4) &&
                        !photo &&
                        localPhotos.isEmpty) {
                      message(context, 'Hãy thêm ít nhất một ảnh phòng.');
                      return;
                    }
                    if (step < 4) {
                      setState(() => step++);
                      saveDraft();
                      return;
                    }
                    final room = draft;
                    setState(() {
                      submitting = true;
                      submitError = null;
                    });
                    try {
                      await widget.state.workflows.run('post-${room.id}', () {
                        if (widget.existing == null) {
                          widget.state.addRoom(room);
                        } else {
                          widget.state.replaceRoom(room);
                        }
                        widget.state.drafts.remove(draftKey);
                      }, role: UserRole.landlord);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() => submitError = e.toString());
                      }
                    } finally {
                      if (mounted) {
                        setState(() => submitting = false);
                      }
                    }
                  },
          ),
        ),
      ],
    ),
    child: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (submitError != null)
            Text(submitError!, style: PT.body(14, PT.error)),
          Text(
            'Bước ${step + 1}/5 • ${['Thông tin', 'Giá & phí', 'Hình ảnh', 'Vị trí', 'Xem trước'][step]}',
            style: PT.body(13, PT.green),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (step + 1) / 5,
            color: PT.green,
            backgroundColor: PT.mint,
          ),
          const SizedBox(height: 25),
          if (step == 0) ...[
            TextFormField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Tiêu đề phòng'),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Nhập tiêu đề phòng' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: floor,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tầng'),
              validator: (v) =>
                  (int.tryParse(v ?? '') ?? -1) < 0 ? 'Nhập tầng hợp lệ' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: area,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Diện tích (m²)'),
              validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                  ? 'Nhập diện tích hợp lệ'
                  : null,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Loại phòng'),
              items: [
                'Studio',
                'Phòng trọ',
                'Căn hộ mini',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (s) {
                type = s!;
                saveDraft();
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),
            const SizedBox(height: 20),
            Text('Tiện nghi', style: PT.title(21)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 8,
              children: ['Có nội thất', 'Wifi riêng', 'Máy lạnh', 'Bếp riêng']
                  .map(
                    (a) => FilterChip(
                      label: Text(a),
                      selected: amenities.contains(a),
                      onSelected: (v) => setState(() {
                        if (v) {
                          amenities.add(a);
                        } else {
                          amenities.remove(a);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (step == 1) ...[
            TextFormField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tiền thuê (đ/tháng)',
              ),
              validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                  ? 'Nhập giá thuê hợp lệ'
                  : null,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: electricity,
              decoration: const InputDecoration(
                labelText: 'Điện (đ/kWh)',
                hintText: '3.500',
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: water,
              decoration: const InputDecoration(
                labelText: 'Nước (đ/người)',
                hintText: '100.000',
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: fees,
              decoration: const InputDecoration(
                labelText: 'Phí khác',
                hintText: 'Wifi, gửi xe, đặt cọc...',
              ),
            ),
          ],
          if (step == 2) ...[
            Text('Thêm hình ảnh phòng', style: PT.title(25)),
            const SizedBox(height: 14),
            if (localPhotos.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final picture in localPhotos)
                    SizedBox(
                      width: 110,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LocalPhotoView(photo: picture, height: 90),
                          ),
                          IconButton(
                            tooltip: 'Xóa ảnh ${picture.name}',
                            icon: const Icon(LucideIcons.trash2),
                            onPressed: submitting
                                ? null
                                : () {
                                    setState(() => localPhotos.remove(picture));
                                    saveDraft();
                                  },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            PrimaryButton(
              'Chọn ảnh phòng từ thiết bị',
              outline: true,
              busy: pickingPhotos,
              onTap: pickingPhotos || submitting
                  ? null
                  : () async {
                      final camera = await choosePhotoSource(context);
                      if (camera == null || !mounted) return;
                      setState(() {
                        pickingPhotos = true;
                        submitError = null;
                      });
                      try {
                        final photos = await widget.state.pickMedia(
                          multiple: !camera,
                          camera: camera,
                        );
                        if (!mounted) return;
                        if (localPhotos.length + photos.length > 8) {
                          throw const MediaFailure(
                            'Một tin phòng có tối đa 8 ảnh từ thiết bị.',
                          );
                        }
                        setState(() => localPhotos.addAll(photos));
                        saveDraft();
                      } on MediaFailure catch (e) {
                        if (mounted) setState(() => submitError = e.message);
                      } finally {
                        if (mounted) setState(() => pickingPhotos = false);
                      }
                    },
            ),
            const SizedBox(height: 12),
            if (photo)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: const ReferencePhoto(height: 220),
              ),
            const SizedBox(height: 18),
            PrimaryButton(
              photo ? 'Thay ảnh mẫu' : 'Chọn ảnh mẫu',
              outline: true,
              icon: LucideIcons.imagePlus,
              onTap: () {
                setState(() => photo = true);
                saveDraft();
              },
            ),
            if (photo)
              TextButton(
                onPressed: () {
                  setState(() => photo = false);
                  saveDraft();
                },
                child: const Text('Xóa ảnh phòng'),
              ),
            const SizedBox(height: 15),
            Text(
              'Ảnh từ thiết bị được giữ trong lần chạy này, chưa tải lên máy chủ. Có thể chọn ảnh mẫu để thử nhanh.',
              style: PT.body(13, PT.muted),
            ),
          ],
          if (step == 3) ...[
            TextFormField(
              controller: address,
              decoration: const InputDecoration(labelText: 'Địa chỉ'),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Nhập địa chỉ' : null,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: district,
              decoration: const InputDecoration(labelText: 'Khu vực'),
              items: [
                'Quận 10',
                'Quận 3',
                'Thủ Đức',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (s) {
                district = s!;
                saveDraft();
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: latitude,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Vĩ độ (không bắt buộc)',
              ),
              validator: (value) {
                final raw = value?.trim() ?? '';
                if (raw.isEmpty) {
                  return longitude.text.trim().isEmpty
                      ? null
                      : 'Nhập đủ cả vĩ độ và kinh độ.';
                }
                final lat = double.tryParse(raw);
                return lat == null || !lat.isFinite || lat.abs() > 90
                    ? 'Vĩ độ phải từ -90 đến 90.'
                    : null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: longitude,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Kinh độ (không bắt buộc)',
              ),
              validator: (value) {
                final raw = value?.trim() ?? '';
                if (raw.isEmpty) {
                  return latitude.text.trim().isEmpty
                      ? null
                      : 'Nhập đủ cả vĩ độ và kinh độ.';
                }
                final lng = double.tryParse(raw);
                return lng == null || !lng.isFinite || lng.abs() > 180
                    ? 'Kinh độ phải từ -180 đến 180.'
                    : null;
              },
            ),
            const SizedBox(height: 15),
            const Text(
              'Điền tọa độ chính xác để mở chỉ đường; để trống nếu chưa có vị trí. Bản đồ dưới đây là minh họa.',
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: const CustomPaint(
                  painter: StreetPainter(),
                  child: Center(
                    child: Icon(LucideIcons.mapPin, size: 40, color: PT.green),
                  ),
                ),
              ),
            ),
          ],
          if (step == 4)
            RoomCard(room: draft, saved: false, onSave: () {}, onInfo: () {}),
        ],
      ),
    ),
  );
}

class LandlordQRScreen extends StatefulWidget {
  final AppState state;
  const LandlordQRScreen({super.key, required this.state});
  @override
  State<LandlordQRScreen> createState() => _LandlordQRScreenState();
}

class _LandlordQRScreenState extends State<LandlordQRScreen> {
  String? selectedId;
  bool busy = false;
  String? error;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, _) {
      final rentals = widget.state.rentals;
      final selected =
          rentals.where((r) => r.id == selectedId).firstOrNull ??
          rentals.firstOrNull;
      if (selected == null) {
        return const BasicPage(
          title: 'Mã nhận phòng',
          child: EmptyState(
            'Chưa có hợp đồng',
            'Mã nhận phòng được cấp cho từng hợp đồng của bạn.',
          ),
        );
      }
      return BasicPage(
        title: 'Mã nhận phòng',
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<String>(
              initialValue: selected.id,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Hợp đồng / phòng'),
              items: rentals
                  .map(
                    (r) => DropdownMenuItem(
                      value: r.id,
                      child: Text(
                        r.room.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (id) => setState(() => selectedId = id),
            ),
            const SizedBox(height: 20),
            Text(selected.room.title, style: PT.title(25)),
            const SizedBox(height: 18),
            Pill(
              selected.checkedIn ? 'Đã nhận phòng' : 'Chờ nhận phòng',
              color: PT.green,
            ),
            const SizedBox(height: 20),
            if (!selected.checkedIn) ...[
              Container(
                height: 230,
                decoration: PT.card(color: PT.mint),
                alignment: Alignment.center,
                child: selected.codeExpiresAt?.isBefore(DateTime.now()) ?? false
                    ? const Text('Mã đã hết hạn. Hãy tạo mã mới.')
                    : QrImageView(
                        data: selected.code,
                        size: 210,
                        backgroundColor: Colors.white,
                        semanticsLabel: 'QR nhận phòng hợp đồng ${selected.id}',
                      ),
              ),
              const SizedBox(height: 18),
              Text(
                selected.code,
                style: PT.title(22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (selected.codeExpiresAt != null)
                Text(
                  '${selected.codeExpiresAt!.isBefore(DateTime.now()) ? 'Mã đã hết hạn' : 'Hạn sử dụng'}: ${selected.codeExpiresAt!.toString().substring(0, 16)}',
                  style: PT.body(
                    14,
                    selected.codeExpiresAt!.isBefore(DateTime.now())
                        ? PT.error
                        : PT.muted,
                  ),
                ),
              if (error != null) Text(error!, style: PT.body(14, PT.error)),
              PrimaryButton(
                'Sao chép mã',
                outline: true,
                onTap: busy
                    ? null
                    : () async {
                        try {
                          await Clipboard.setData(
                            ClipboardData(text: selected.code),
                          );
                          if (context.mounted) {
                            message(context, 'Đã sao chép mã nhận phòng.');
                          }
                        } catch (_) {
                          if (mounted) {
                            setState(
                              () => error = 'Chưa sao chép được. Hãy chọn và sao chép mã thủ công.',
                            );
                          }
                        }
                      },
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                'Tạo mã mới (24 giờ)',
                busy: busy,
                onTap: busy
                    ? null
                    : () async {
                        setState(() {
                          busy = true;
                          error = null;
                        });
                        try {
                          await widget.state.workflows.refreshCode(selected.id);
                        } catch (e) {
                          if (mounted) {
                            setState(() => error = e.toString());
                          }
                        } finally {
                          if (mounted) {
                            setState(() => busy = false);
                          }
                        }
                      },
              ),
              const SizedBox(height: 12),
              Text(
                'QR chứa mã của hợp đồng ${selected.id}; có thể quét bằng camera. Xác nhận nhận phòng vẫn được kiểm tra trong kho demo.',
                style: PT.body(14, PT.muted),
              ),
            ] else
              Text(
                'Mã đã sử dụng và không thể nhận phòng lần nữa.',
                style: PT.body(14, PT.muted),
              ),
          ],
        ),
      );
    },
  );
}
