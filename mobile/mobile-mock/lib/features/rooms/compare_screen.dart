import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_state.dart';
import '../../core/async_resource.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../demo/models.dart';
import 'room_controller.dart';
import 'room_screens.dart';

class RoomComparisonController {
  final RoomRepository repository;
  final result = AsyncResource<List<Room>>();
  RoomComparisonController(this.repository);
  Future<void> compare(Iterable<String> ids) {
    final selected = ids.toSet().toList();
    return result.load(() async {
      if (selected.length < 2) {
        throw const RepositoryFailure(
          DemoFault.denied,
          'Chọn ít nhất 2 phòng để so sánh.',
        );
      }
      final rooms = await Future.wait(selected.map(repository.find));
      if (rooms.any((r) => r == null)) {
        throw const RepositoryFailure(
          DemoFault.missing,
          'Một phòng không còn tồn tại. Chọn lại phòng.',
        );
      }
      if (rooms.any(
        (r) => r!.status == RoomStatus.hidden || r.status == RoomStatus.pending,
      )) {
        throw const RepositoryFailure(
          DemoFault.denied,
          'Một phòng không còn công khai. Chọn lại phòng.',
        );
      }
      return rooms.cast<Room>();
    });
  }

  void dispose() => result.dispose();
}

class CompareRoomsScreen extends StatefulWidget {
  final AppState state;
  final String? initialRoomId;
  const CompareRoomsScreen({
    super.key,
    required this.state,
    this.initialRoomId,
  });
  @override
  State<CompareRoomsScreen> createState() => _CompareRoomsScreenState();
}

class _CompareRoomsScreenState extends State<CompareRoomsScreen> {
  late final controller = RoomComparisonController(
    widget.state.roomController.repository,
  );
  late final selected = <String>{
    if (widget.initialRoomId != null) widget.initialRoomId!,
  };
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller.result,
    builder: (context, _) {
      final result = controller.result;
      final busy = result.phase == ResourcePhase.loading;
      final rooms = widget.state.rooms
          .where(
            (r) =>
                r.status == RoomStatus.available ||
                r.status == RoomStatus.rented,
          )
          .toList();
      return BasicPage(
        title: 'So sánh phòng',
        bottom: PrimaryButton(
          busy ? 'Đang tải so sánh…' : 'So sánh ${selected.length} phòng',
          busy: busy,
          onTap: selected.length < 2 || busy
              ? null
              : () => controller.compare(selected),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Đặt cạnh nhau để chọn nơi ở phù hợp', style: PT.title(25)),
            const SizedBox(height: 8),
            Text(
              'Chọn ít nhất 2 phòng. Phòng đã thuê được ghi rõ để bạn cân nhắc.',
              style: PT.body(14, PT.muted),
            ),
            const SizedBox(height: 12),
            for (final room in rooms)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(room.title, style: PT.body(15)),
                subtitle: Text('${room.priceLabel} • ${room.status.label}'),
                value: selected.contains(room.id),
                onChanged: busy
                    ? null
                    : (v) => setState(() {
                        v! ? selected.add(room.id) : selected.remove(room.id);
                        result.clear();
                      }),
              ),
            if (result.phase == ResourcePhase.error) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  result.error!.message,
                  style: PT.body(14, PT.error),
                ),
              ),
              TextButton(
                onPressed: () => controller.compare(selected),
                child: const Text('Thử lại'),
              ),
            ],
            if (result.phase == ResourcePhase.ready) ...[
              const SizedBox(height: 20),
              Text('Kết quả so sánh', style: PT.title(23)),
              const SizedBox(height: 8),
              Text(
                'Cuộn ngang để xem từng phòng',
                style: PT.body(13, PT.muted),
              ),
              const SizedBox(height: 12),
              _ComparisonTable(rooms: result.data!, state: widget.state),
            ],
          ],
        ),
      );
    },
  );
}

class _ComparisonTable extends StatelessWidget {
  final List<Room> rooms;
  final AppState state;
  const _ComparisonTable({required this.rooms, required this.state});
  @override
  Widget build(BuildContext context) {
    final width = ((MediaQuery.sizeOf(context).width - 32) / 2).clamp(
      175.0,
      230.0,
    );
    final specs = <(String, String Function(Room))>[
      ('Giá thuê', (r) => r.priceLabel),
      ('Khu vực', (r) => r.district),
      ('Diện tích', (r) => '${r.area} m²'),
      ('Tầng', (r) => '${r.floor}'),
      ('Loại phòng', (r) => r.type),
      ('Trạng thái', (r) => r.status.label),
      ('Độ phù hợp', (r) => '${r.match}%'),
      ('Chủ trọ', (r) => r.landlordName),
      ('Điện', (r) => r.electricity),
      ('Nước', (r) => r.water),
      ('Phí khác', (r) => r.otherFees),
    ];
    Widget cell(Widget child) =>
        Padding(padding: const EdgeInsets.all(12), child: child);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: width * rooms.length,
        child: Container(
          decoration: PT.card(),
          child: Table(
            defaultColumnWidth: FixedColumnWidth(width),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: const TableBorder(
              horizontalInside: BorderSide(color: PT.line),
              verticalInside: BorderSide(color: PT.line),
            ),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: PT.mint),
                children: [
                  for (final room in rooms)
                    cell(Text(room.title, style: PT.title(17))),
                ],
              ),
              for (final spec in specs)
                TableRow(
                  children: [
                    for (final room in rooms)
                      cell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(spec.$1, style: PT.body(12, PT.muted)),
                            const SizedBox(height: 4),
                            Text(
                              spec.$2(room),
                              style: PT.body(
                                15,
                                spec.$1 == 'Giá thuê' ? PT.green : PT.deep,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              for (final amenity in {...rooms.expand((r) => r.amenities)})
                TableRow(
                  children: [
                    for (final room in rooms)
                      cell(
                        Row(
                          children: [
                            Icon(
                              room.amenities.contains(amenity)
                                  ? LucideIcons.check
                                  : LucideIcons.x,
                              size: 18,
                              color: room.amenities.contains(amenity)
                                  ? PT.green
                                  : PT.muted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: Text(amenity, style: PT.body(14))),
                          ],
                        ),
                      ),
                  ],
                ),
              TableRow(
                children: [
                  for (final room in rooms)
                    cell(
                      PrimaryButton(
                        'Xem phòng',
                        outline: true,
                        onTap: () => openPage(
                          context,
                          RoomDetailScreen(state: state, room: room),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
