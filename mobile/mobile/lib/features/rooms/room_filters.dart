import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class RoomFilterSheet extends StatefulWidget {
  final AppState state;
  const RoomFilterSheet({super.key, required this.state});
  @override
  State<RoomFilterSheet> createState() => _RoomFilterSheetState();
}

class _RoomFilterSheetState extends State<RoomFilterSheet> {
  final form = GlobalKey<FormState>();
  late final query = TextEditingController(
    text: widget.state.roomController.query,
  );
  late final minimum = TextEditingController(
    text: widget.state.roomController.minPrice.toInt().toString(),
  );
  late final maximum = TextEditingController(
    text: widget.state.maxPrice.toInt().toString(),
  );
  late String district = widget.state.district,
      type = widget.state.type,
      sort = widget.state.roomController.sort;
  late final amenities = {...widget.state.roomController.amenities};
  @override
  void dispose() {
    query.dispose();
    minimum.dispose();
    maximum.dispose();
    super.dispose();
  }

  void clear() => setState(() {
    district = type = 'Tất cả';
    sort = 'newest';
    amenities.clear();
    form.currentState?.reset();
    query.clear();
    minimum.text = '0';
    maximum.text = '8000000';
  });
  @override
  Widget build(BuildContext context) {
    final districts = {'Tất cả', ...widget.state.rooms.map((r) => r.district)};
    final types = {'Tất cả', ...widget.state.rooms.map((r) => r.type)};
    final options = {...widget.state.rooms.expand((r) => r.amenities)};
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: math.max(
          220,
          MediaQuery.sizeOf(context).height * .82 -
              MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 4),
              child: Row(
                children: [
                  Expanded(child: Text('Bộ lọc phòng', style: PT.title(20))),
                  IconButton(
                    tooltip: 'Đóng bộ lọc',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: form,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  children: [
                    TextFormField(
                      controller: query,
                      decoration: const InputDecoration(
                        labelText: 'Tên phòng hoặc địa chỉ',
                        prefixIcon: Icon(LucideIcons.search),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Ngân sách mỗi tháng (đ)', style: PT.body(13)),
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final minField = TextFormField(
                          controller: minimum,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Giá tối thiểu',
                          ),
                          validator: (v) => (int.tryParse(v ?? '') ?? -1) >= 0
                              ? null
                              : 'Nhập số tiền từ 0 trở lên',
                        );
                        final maxField = TextFormField(
                          controller: maximum,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Giá tối đa',
                          ),
                          validator: (v) {
                            final max = int.tryParse(v ?? '');
                            final min = int.tryParse(minimum.text);
                            return max == null || max < 0
                                ? 'Nhập số tiền hợp lệ'
                                : min != null && max < min
                                ? 'Giá tối đa phải từ giá tối thiểu trở lên'
                                : null;
                          },
                        );
                        final sideBySide =
                            constraints.maxWidth >= 320 &&
                            MediaQuery.textScalerOf(context).scale(12) <= 15;
                        if (sideBySide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: minField),
                              const SizedBox(width: 10),
                              Expanded(child: maxField),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            minField,
                            const SizedBox(height: 8),
                            maxField,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text('Khu vực', style: PT.body(13)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: districts
                          .map(
                            (d) => ChoiceChip(
                              visualDensity: VisualDensity.compact,
                              label: Text(d),
                              selected: district == d,
                              onSelected: (_) => setState(() => district = d),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Text('Loại phòng', style: PT.body(13)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: types
                          .map(
                            (t) => ChoiceChip(
                              visualDensity: VisualDensity.compact,
                              label: Text(t),
                              selected: type == t,
                              onSelected: (_) => setState(() => type = t),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Text('Tiện ích cần có', style: PT.body(13)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: options
                          .map(
                            (a) => FilterChip(
                              visualDensity: VisualDensity.compact,
                              label: Text(a),
                              selected: amenities.contains(a),
                              onSelected: (v) => setState(() {
                                v ? amenities.add(a) : amenities.remove(a);
                              }),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: sort,
                      key: ValueKey(sort),
                      decoration: const InputDecoration(labelText: 'Sắp xếp'),
                      items: const [
                        DropdownMenuItem(
                          value: 'newest',
                          child: Text('Gợi ý mặc định'),
                        ),
                        DropdownMenuItem(
                          value: 'price_asc',
                          child: Text('Giá tăng dần'),
                        ),
                        DropdownMenuItem(
                          value: 'price_desc',
                          child: Text('Giá giảm dần'),
                        ),
                      ],
                      onChanged: (v) => setState(() => sort = v!),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: clear,
                      child: const Text('Xóa bộ lọc'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PrimaryButton(
                        'Áp dụng bộ lọc',
                        onTap: () {
                          if (!form.currentState!.validate()) return;
                          widget.state.applyRoomFilters(
                            district: district,
                            type: type,
                            minPrice: double.parse(minimum.text),
                            maxPrice: double.parse(maximum.text),
                            query: query.text.trim(),
                            amenities: amenities,
                            sort: sort,
                          );
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
