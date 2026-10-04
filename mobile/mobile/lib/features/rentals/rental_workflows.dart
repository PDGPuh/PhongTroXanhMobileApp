import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_state.dart';
import '../../core/flow_page.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../account/account_workflows.dart';
import '../chat/chat_screens.dart';
import '../rooms/room_screens.dart';

class ReviewScreen extends StatefulWidget {
  final AppState state;
  final String? rentalId;
  const ReviewScreen({super.key, required this.state, this.rentalId});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final comment = TextEditingController();
  late String? id = widget.rentalId;
  int rating = 5;
  final tags = <String>{};
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FlowPage(
    state: widget.state,
    title: widget.state.role == UserRole.landlord
        ? 'Đánh giá người thuê'
        : 'Đánh giá phòng',
    content: (ctx, f) {
      final s = widget.state;
      final rental = s.reviewableRentals
          .where((r) => id == null || r.id == id)
          .firstOrNull;
      final previous = s.store.reviewRecords
          .where((r) => r.rentalId == rental?.id && r.authorId == s.userId)
          .firstOrNull;
      return [
        if (rental == null)
          const EmptyState(
            'Cần xác nhận thuê trước',
            'Chỉ hợp đồng đang hoạt động và đã nhận phòng mới được đánh giá.',
            icon: LucideIcons.shieldCheck,
          )
        else ...[
          DropdownButtonFormField<String>(
            initialValue: rental.id,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Hợp đồng cần đánh giá',
            ),
            items: s.reviewableRentals
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
            onChanged: f.busy
                ? null
                : (v) => setState(() {
                    id = v;
                    comment.clear();
                    rating = 5;
                    tags.clear();
                  }),
          ),
          const SizedBox(height: 16),
          Text(
            s.role == UserRole.landlord
                ? s.store.workspaceById(rental.tenantId).fullName
                : rental.room.title,
            style: PT.title(25),
          ),
          Text(
            'Đối tượng: ${s.role == UserRole.landlord ? rental.tenantId : rental.room.id} • ${rental.id}',
          ),
          const SizedBox(height: 16),
          if (previous != null)
            flowCard('Đánh giá đã gửi • ${previous.id}', [
              Text('${previous.rating}/5 sao'),
              Text(previous.comment),
              Text(previous.tags.join(' • ')),
            ])
          else ...[
            Wrap(
              alignment: WrapAlignment.center,
              children: List.generate(
                5,
                (i) => IconButton(
                  tooltip: '${i + 1} sao',
                  onPressed: f.busy
                      ? null
                      : () => setState(() => rating = i + 1),
                  icon: Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 36,
                    color: PT.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  (s.role == UserRole.landlord
                          ? [
                              'Đúng hẹn',
                              'Gọn gàng',
                              'Thân thiện',
                              'Trả tiền đúng hạn',
                              'Giữ gìn tài sản',
                              'Tôn trọng hàng xóm',
                            ]
                          : [
                              'Sạch sẽ',
                              'Đúng mô tả',
                              'Giá hợp lý',
                              'Chủ trọ thân thiện',
                            ])
                      .map(
                        (tag) => FilterChip(
                          label: Text(tag),
                          selected: tags.contains(tag),
                          onSelected: (v) => setState(() {
                            v ? tags.add(tag) : tags.remove(tag);
                          }),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: comment,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Chia sẻ trải nghiệm của bạn',
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              'Gửi đánh giá',
              busy: f.busy,
              onTap: f.busy
                  ? null
                  : () => f.perform(
                      () => s.workflows.review(
                        rental.id,
                        rating,
                        comment.text,
                        tags.toList(),
                      ),
                    ),
            ),
          ],
        ],
      ];
    },
  );
}

class ReviewHistoryScreen extends StatelessWidget {
  final AppState state;
  final String? roomId;
  const ReviewHistoryScreen({super.key, required this.state, this.roomId});
  @override
  Widget build(BuildContext context) => FlowPage(
    state: state,
    title: 'Lịch sử đánh giá',
    content: (ctx, f) {
      final records = state.store.reviewRecords
          .where(
            (r) => roomId != null
                ? r.targetType == 'ROOM' && r.targetId == roomId
                : r.authorId == state.userId ||
                      r.targetId == state.userId ||
                      state.myRooms.any((room) => room.id == r.targetId),
          )
          .toList();
      return [
        if (records.isEmpty)
          const EmptyState(
            'Chưa có đánh giá',
            'Đánh giá được liên kết với hợp đồng đã nhận phòng.',
          ),
        for (final r in records.reversed)
          flowCard('${r.authorName} • ${r.rating}/5', [
            Text(
              'Đối tượng: ${r.targetType} ${r.targetId} • ${r.rentalId}',
              style: PT.body(12, PT.muted),
            ),
            const SizedBox(height: 10),
            Text(r.comment, style: PT.body(15)),
            Text(r.tags.join(' • ')),
            if (r.authorId != state.userId)
              TextButton(
                onPressed: () => openPage(
                  ctx,
                  ReportScreen(
                    state: state,
                    targetType: 'REVIEW',
                    targetId: r.id,
                  ),
                ),
                child: const Text('Báo cáo đánh giá'),
              ),
          ]),
      ];
    },
  );
}

class LandlordTenantsScreen extends StatelessWidget {
  final AppState state;
  final String? roomId;
  const LandlordTenantsScreen({super.key, required this.state, this.roomId});
  List<Rental> get rentals => state.rentals
      .where((r) => roomId == null || r.room.id == roomId)
      .toList();
  @override
  Widget build(BuildContext context) => FlowPage(
    state: state,
    title: 'Người thuê',
    content: (ctx, f) => [
      if (rentals.isEmpty)
        const EmptyState(
          'Chưa có người thuê',
          'Hợp đồng thuộc phòng của bạn sẽ xuất hiện ở đây.',
        ),
      for (final r in rentals)
        flowCard(state.store.workspaceById(r.tenantId).fullName, [
          Text(r.room.title, style: PT.body(16)),
          Text('${r.id} • ${r.status.label}'),
          Text(
            r.checkedIn ? 'Đã nhận phòng' : 'Chờ nhận phòng',
            style: PT.body(14, PT.green),
          ),
          const SizedBox(height: 12),
          if (r.checkedIn && r.status == RentalStatus.active) ...[
            PrimaryButton(
              'Đánh giá người thuê',
              outline: true,
              onTap: () =>
                  openPage(ctx, ReviewScreen(state: state, rentalId: r.id)),
            ),
            const SizedBox(height: 12),
          ],
          PrimaryButton(
            'Liên hệ người thuê',
            onTap: () {
              final existing = state.conversations
                  .where(
                    (c) =>
                        c.participantId == r.tenantId && c.roomId == r.room.id,
                  )
                  .firstOrNull;
              final c =
                  existing ??
                  Conversation(
                    id: 'tenant-chat-${r.id}',
                    name: state.store.workspaceById(r.tenantId).fullName,
                    time: '',
                    subtitle: '',
                    participantId: r.tenantId,
                    roomId: r.room.id,
                    messages: [],
                  );
              if (existing == null) {
                state.conversations.add(c);
                state.changed();
              }
              openPage(ctx, ChatScreen(state: state, conversation: c));
            },
          ),
        ]),
    ],
  );
}

class SwapScreen extends StatefulWidget {
  final AppState state;
  final String? rentalId;
  const SwapScreen({super.key, required this.state, this.rentalId});
  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  int tab = 0;
  final reason = TextEditingController(),
      budget = TextEditingController(text: '4000000'),
      search = TextEditingController();
  late String? rentalId = widget.rentalId;
  String district = 'Quận 10',
      type = 'Studio',
      movingDate = '',
      filter = 'Tất cả';
  bool leaseholder = true;
  final habits = <String>{};
  @override
  void dispose() {
    reason.dispose();
    budget.dispose();
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FlowPage(
    state: widget.state,
    title: 'Đổi phòng',
    content: (ctx, f) {
      final s = widget.state;
      final rental = s.reviewableRentals
          .where((r) => rentalId == null || rentalId == r.id)
          .firstOrNull;
      final listings = s.store.swaps
          .where(
            (r) =>
                r.tenantId != s.userId &&
                ['Đã duyệt', 'Đang tìm phòng phù hợp'].contains(r.status),
          )
          .where((r) {
            final room = s.roomById(r.roomId);
            return room != null &&
                (filter == 'Tất cả' || room.district == filter) &&
                room.title.toLowerCase().contains(search.text.toLowerCase());
          })
          .toList();
      return [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < 3; i++)
              ChoiceChip(
                label: Text(['Khám phá', 'Tạo yêu cầu', 'Theo dõi'][i]),
                selected: i == tab,
                onSelected: (_) => setState(() => tab = i),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (tab == 0) ...[
          TextField(
            controller: search,
            decoration: const InputDecoration(
              labelText: 'Tìm tin đổi phòng',
              prefixIcon: Icon(LucideIcons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: filter,
            decoration: const InputDecoration(
              labelText: 'Khu vực phòng hiện tại',
            ),
            items: [
              'Tất cả',
              'Quận 10',
              'Quận 3',
              'Thủ Đức',
            ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() => filter = v!),
          ),
          const SizedBox(height: 16),
          if (listings.isEmpty)
            const EmptyState(
              'Chưa có tin phù hợp',
              'Tin đổi phòng đang mở của người khác sẽ xuất hiện tại đây.',
            ),
          for (final listing in listings)
            flowCard(s.roomById(listing.roomId)!.title, [
              Text(s.store.workspaceById(listing.tenantId).fullName),
              Text(listing.reason),
              Text(
                'Muốn chuyển: ${listing.targetDistrict} • ${listing.targetType}',
              ),
              Text('Ngân sách: ${listing.budgetMax}đ'),
              Text(listing.habits.join(' • ')),
              const SizedBox(height: 12),
              PrimaryButton(
                'Xem phòng hiện tại',
                outline: true,
                onTap: () => openPage(
                  ctx,
                  RoomDetailScreen(state: s, room: s.roomById(listing.roomId)!),
                ),
              ),
              const SizedBox(height: 12),
              if (rental == null)
                const Text('Cần nhận phòng trước khi gửi đề nghị')
              else ...[
                DropdownButtonFormField<String>(
                  initialValue: rental.id,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Phòng bạn muốn đề nghị đổi',
                  ),
                  items: s.reviewableRentals
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
                  onChanged: (id) => setState(() => rentalId = id),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  'Gửi đề nghị đổi phòng',
                  busy: f.busy,
                  onTap: f.busy
                      ? null
                      : () async {
                          if (await confirmAction(
                            ctx,
                            'Gửi đề nghị?',
                            'Đề nghị đổi ${rental.room.title} với ${s.roomById(listing.roomId)!.title}.',
                          )) {
                            if (await f.perform(
                                  () => s.workflows.propose(
                                    listing.id,
                                    rental.id,
                                    'Đề nghị đổi phòng',
                                  ),
                                ) &&
                                mounted) {
                              setState(() => tab = 2);
                            }
                          }
                        },
                ),
              ],
            ]),
        ],
        if (tab == 1) ...[
          if (rental == null)
            const EmptyState(
              'Cần có phòng đang thuê',
              'Nhận phòng trước khi tạo yêu cầu đổi phòng.',
            )
          else ...[
            DropdownButtonFormField<String>(
              initialValue: rental.id,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Hợp đồng hiện tại'),
              items: s.reviewableRentals
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
              onChanged: (v) => setState(() => rentalId = v),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Người ký hợp đồng chính'),
              subtitle: Text(
                leaseholder
                    ? 'Cần chủ trọ duyệt trước khi mở tin'
                    : 'Bắt đầu tìm phòng phù hợp',
              ),
              value: leaseholder,
              onChanged: (v) => setState(() => leaseholder = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: district,
              decoration: const InputDecoration(
                labelText: 'Khu vực muốn chuyển',
              ),
              items: [
                'Quận 10',
                'Quận 3',
                'Thủ Đức',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => district = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: type,
              decoration: const InputDecoration(
                labelText: 'Loại phòng mong muốn',
              ),
              items: [
                'Studio',
                'Phòng trọ',
                'Căn hộ mini',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => type = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budget,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ngân sách tối đa (đ/tháng)',
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(LucideIcons.calendar),
              label: Text(
                movingDate.isEmpty ? 'Chọn ngày mong muốn chuyển' : movingDate,
              ),
              onPressed: () async {
                final now = DateTime.now();
                final date = await showDatePicker(
                  context: ctx,
                  firstDate: DateTime(now.year, now.month, now.day),
                  lastDate: now.add(const Duration(days: 730)),
                  initialDate: now,
                );
                if (date != null && mounted) {
                  setState(
                    () => movingDate = date.toIso8601String().substring(0, 10),
                  );
                }
              },
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Không hút thuốc', 'Gọn gàng', 'Ngủ sớm', 'Yên tĩnh']
                  .map(
                    (h) => FilterChip(
                      label: Text(h),
                      selected: habits.contains(h),
                      onSelected: (v) => setState(() {
                        v ? habits.add(h) : habits.remove(h);
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Lý do và nhu cầu đổi phòng',
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              'Tạo yêu cầu',
              busy: f.busy,
              onTap: f.busy
                  ? null
                  : () async {
                      final ok = await f.perform(
                        () => s.workflows.createSwap(
                          SwapRequest(
                            roomId: rental.room.id,
                            reason: reason.text.trim(),
                            leaseholder: leaseholder,
                            targetDistrict: district,
                            targetType: type,
                            budgetMax: int.tryParse(budget.text) ?? 0,
                            movingDate: movingDate,
                            habits: habits.toList(),
                          ),
                        ),
                      );
                      if (ok && mounted) {
                        setState(() => tab = 2);
                        reason.clear();
                      }
                    },
            ),
          ],
        ],
        if (tab == 2) ...[
          if (s.swaps.isEmpty &&
              !s.store.proposals.any((p) => p.proposerId == s.userId))
            const EmptyState(
              'Chưa có yêu cầu',
              'Tạo tin hoặc gửi đề nghị trong mục Khám phá.',
            ),
          for (final r in s.swaps)
            flowCard('${r.id} • ${r.status}', [
              Text(
                s.roomById(r.roomId)?.title ?? r.roomId,
                style: PT.title(20),
              ),
              Text(r.reason),
              Text('${r.targetDistrict} • ${r.targetType} • ≤ ${r.budgetMax}đ'),
              if (r.movingDate.isNotEmpty)
                Text('Ngày chuyển dự kiến: ${r.movingDate}'),
              if (r.decisionNote.isNotEmpty)
                Text('Phản hồi chủ trọ: ${r.decisionNote}'),
              if ([
                'Chờ duyệt',
                'Đã duyệt',
                'Đang tìm phòng phù hợp',
                'Đã từ chối',
              ].contains(r.status))
                TextButton(
                  onPressed: f.busy
                      ? null
                      : () async {
                          if (await confirmAction(
                            ctx,
                            'Hủy yêu cầu ${r.id}?',
                            'Tin sẽ ngừng nhận đề nghị mới.',
                          )) {
                            await f.perform(() => s.workflows.cancelSwap(r.id));
                          }
                        },
                  child: const Text('Hủy yêu cầu'),
                ),
              for (final p in s.store.proposals.where(
                (p) => p.listingId == r.id,
              ))
                flowCard('Đề nghị ${p.id}', [
                  Text(s.store.workspaceById(p.proposerId).fullName),
                  Text(
                    s.store.rentals
                        .firstWhere((r) => r.id == p.offeredRentalId)
                        .room
                        .title,
                  ),
                  Text(p.note),
                  Text(p.status),
                  if (p.status == 'Chờ phản hồi') ...[
                    const SizedBox(height: 12),
                    PrimaryButton(
                      'Chấp nhận đề nghị',
                      onTap: f.busy
                          ? null
                          : () async {
                              if (await confirmAction(
                                ctx,
                                'Chấp nhận đề nghị?',
                                'Ghép đổi phòng chưa thay thế hợp đồng. Hai bên cần hoàn tất hợp đồng với chủ trọ.',
                              )) {
                                await f.perform(
                                  () => s.workflows.respondProposal(p.id, true),
                                );
                              }
                            },
                    ),
                    TextButton(
                      onPressed: f.busy
                          ? null
                          : () => f.perform(
                              () => s.workflows.respondProposal(p.id, false),
                            ),
                      child: const Text('Từ chối đề nghị'),
                    ),
                  ],
                ]),
              if (r.status == 'Đã ghép • chờ hợp đồng mới')
                const Text(
                  'Liên hệ chủ trọ để ký hợp đồng mới; app chưa tự chuyển người thuê hoặc đánh dấu hoàn tất.',
                ),
            ]),
          for (final p in s.store.proposals.where(
            (p) => p.proposerId == s.userId,
          ))
            flowCard('Đề nghị đã gửi • ${p.id}', [
              Text('Tin: ${p.listingId}'),
              Text(p.status),
              Text(p.note),
            ]),
        ],
      ];
    },
  );
}

class LandlordSwapsScreen extends StatelessWidget {
  final AppState state;
  const LandlordSwapsScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) => FlowPage(
    state: state,
    title: 'Yêu cầu đổi phòng',
    content: (ctx, f) => [
      if (state.swaps.isEmpty)
        const EmptyState(
          'Chưa có yêu cầu',
          'Chỉ yêu cầu thuộc phòng của bạn được hiển thị.',
        ),
      for (final s in state.swaps)
        flowCard('${s.id} • ${s.status}', [
          Text(state.roomById(s.roomId)?.title ?? s.roomId),
          Text(state.store.workspaceById(s.tenantId).fullName),
          Text(s.reason),
          Text('${s.targetDistrict} • ${s.targetType} • ${s.budgetMax}đ'),
          Text(s.decisionNote),
          if (s.status == 'Chờ duyệt') ...[
            const SizedBox(height: 12),
            PrimaryButton(
              'Duyệt yêu cầu',
              busy: f.busy,
              onTap: f.busy
                  ? null
                  : () => f.perform(
                      () => state.workflows.decideSwap(
                        s.id,
                        true,
                        'Chủ trọ đồng ý mở tin đổi phòng',
                      ),
                    ),
            ),
            TextButton(
              onPressed: f.busy
                  ? null
                  : () async {
                      final c = TextEditingController();
                      final note = await showDialog<String>(
                        context: ctx,
                        builder: (d) => AlertDialog(
                          title: const Text('Lý do từ chối'),
                          content: TextField(
                            controller: c,
                            decoration: const InputDecoration(
                              labelText: 'Lý do',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(d),
                              child: const Text('Quay lại'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(d, c.text),
                              child: const Text('Từ chối'),
                            ),
                          ],
                        ),
                      );
                      if (note != null) {
                        await f.perform(
                          () => state.workflows.decideSwap(s.id, false, note),
                        );
                      }
                    },
              child: const Text('Từ chối yêu cầu'),
            ),
          ],
        ]),
    ],
  );
}

class LandlordReviewsScreen extends StatelessWidget {
  final AppState state;
  const LandlordReviewsScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    final s = state;
    return FlowPage(
      state: s,
      title: 'Đánh giá',
      content: (ctx, f) => [
        PrimaryButton(
          'Viết đánh giá người thuê',
          onTap: () => openPage(ctx, ReviewScreen(state: s)),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          'Xem đánh giá nhận được / đã gửi',
          outline: true,
          onTap: () => openPage(ctx, ReviewHistoryScreen(state: s)),
        ),
        const SizedBox(height: 16),
        for (final r in s.store.reviewRecords.where(
          (r) => s.myRooms.any((room) => room.id == r.targetId),
        ))
          flowCard('${r.authorName} • ${r.rating}/5', [
            Text(r.comment),
            Text(r.tags.join(' • ')),
            Text('Hợp đồng: ${r.rentalId}'),
          ]),
      ],
    );
  }
}
