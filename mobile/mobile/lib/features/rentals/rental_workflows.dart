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
  int cleanlinessRating = 5;
  int accuracyRating = 5;
  int communicationRating = 5;
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
                    cleanlinessRating = 5;
                    accuracyRating = 5;
                    communicationRating = 5;
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
              Text(
                'Chi tiết: Vệ sinh ${previous.cleanlinessRating}★ • Mô tả ${previous.accuracyRating}★ • Giao tiếp ${previous.communicationRating}★',
                style: PT.body(12, PT.muted),
              ),
              const SizedBox(height: 6),
              Text(previous.comment),
              Text(previous.tags.join(' • ')),
              if (previous.landlordReply != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Phản hồi chủ trọ: ${previous.landlordReply}',
                  style: PT.body(13, PT.green),
                ),
              ],
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: Text('Vệ sinh: $cleanlinessRating★'),
                  onPressed: f.busy
                      ? null
                      : () => setState(
                          () => cleanlinessRating = cleanlinessRating % 5 + 1,
                        ),
                ),
                ActionChip(
                  label: Text('Mô tả: $accuracyRating★'),
                  onPressed: f.busy
                      ? null
                      : () =>
                          setState(() => accuracyRating = accuracyRating % 5 + 1),
                ),
                ActionChip(
                  label: Text('Giao tiếp: $communicationRating★'),
                  onPressed: f.busy
                      ? null
                      : () => setState(
                          () =>
                              communicationRating = communicationRating % 5 + 1,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 12),
            TextField(
              controller: comment,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Chia sẻ trải nghiệm của bạn',
              ),
            ),
            const SizedBox(height: 14),
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
                        cleanlinessRating: cleanlinessRating,
                        accuracyRating: accuracyRating,
                        communicationRating: communicationRating,
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
            Text(
              'Vệ sinh ${r.cleanlinessRating}★ • Mô tả ${r.accuracyRating}★ • Giao tiếp ${r.communicationRating}★',
              style: PT.body(12, PT.green),
            ),
            const SizedBox(height: 10),
            Text(r.comment, style: PT.body(15)),
            Text(r.tags.join(' • ')),
            if (r.landlordReply != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: PT.card(color: PT.mint),
                child: Text(
                  'Phản hồi chủ trọ: ${r.landlordReply}',
                  style: PT.body(13),
                ),
              ),
            ],
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

class LandlordTenantsScreen extends StatefulWidget {
  final AppState state;
  final String? roomId;
  const LandlordTenantsScreen({super.key, required this.state, this.roomId});
  @override
  State<LandlordTenantsScreen> createState() => _LandlordTenantsScreenState();
}

class _LandlordTenantsScreenState extends State<LandlordTenantsScreen> {
  String filter = 'Tất cả';

  List<Rental> get allRentals => widget.state.rentals
      .where((r) => widget.roomId == null || r.room.id == widget.roomId)
      .toList();

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return FlowPage(
      state: state,
      title: 'Người thuê',
      content: (ctx, f) {
        final rentals = allRentals.where((r) {
          if (filter == 'Đã nhận phòng') {
            return r.checkedIn && r.status == RentalStatus.active;
          }
          if (filter == 'Chờ nhận phòng') {
            return !r.checkedIn && r.status == RentalStatus.active;
          }
          if (filter == 'Đã kết thúc') {
            return r.status == RentalStatus.terminated ||
                r.status == RentalStatus.expired;
          }
          return true;
        }).toList();

        final activeCount = allRentals
            .where((r) => r.status == RentalStatus.active)
            .length;
        final verifiedCount = allRentals
            .where(
              (r) =>
                  state.store.workspaceById(r.tenantId).verification ==
                  'Đã xác minh',
            )
            .length;
        final avgTrust = allRentals.isEmpty
            ? 90
            : (allRentals
                          .map(
                            (r) =>
                                state.store.profiles[r.tenantId]?.trustScore ??
                                88,
                          )
                          .reduce((a, b) => a + b) /
                      allRentals.length)
                  .round();

        return [
          LayoutBuilder(
            builder: (context, c) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final stat in [
                  (
                    'Đang thuê',
                    '$activeCount hợp đồng',
                    LucideIcons.fileCheck2,
                  ),
                  (
                    'TrustScore TB',
                    '$avgTrust/100 điểm',
                    LucideIcons.shieldCheck,
                  ),
                  (
                    'CCCD xác minh',
                    '$verifiedCount/${allRentals.length} khách',
                    LucideIcons.idCard,
                  ),
                ])
                  SizedBox(
                    width: c.maxWidth < 340
                        ? (c.maxWidth - 8) / 2
                        : (c.maxWidth - 16) / 3,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: PT.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: PT.mint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(stat.$3, size: 15, color: PT.green),
                          ),
                          const SizedBox(height: 8),
                          Text(stat.$1, style: PT.body(11, PT.muted)),
                          const SizedBox(height: 2),
                          Text(stat.$2, style: PT.title(15)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Tất cả',
              'Đã nhận phòng',
              'Chờ nhận phòng',
              'Đã kết thúc',
            ]
                .map(
                  (v) => ChoiceChip(
                    label: Text(v),
                    selected: filter == v,
                    onSelected: (_) => setState(() => filter = v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          if (rentals.isEmpty)
            const EmptyState(
              'Chưa có người thuê',
              'Hợp đồng thuộc phòng của bạn sẽ xuất hiện ở đây.',
            ),
          for (final r in rentals)
            flowCard(state.store.workspaceById(r.tenantId).fullName, [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PT.grey.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.room.title,
                      style: PT.body(15, PT.deep).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${r.id} • ${r.status.label}',
                      style: PT.body(12, PT.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.checkedIn ? 'Đã nhận phòng' : 'Chờ nhận phòng',
                      style: PT.body(13, PT.green).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Pill(
                    'TrustScore: ${state.store.profiles[r.tenantId]?.trustScore ?? 88}/100',
                    dense: true,
                    color: PT.green,
                  ),
                  Pill(
                    state.store.workspaceById(r.tenantId).verification,
                    dense: true,
                    color:
                        state.store.workspaceById(r.tenantId).verification ==
                            'Đã xác minh'
                        ? PT.green
                        : PT.amber,
                  ),
                  if (r.handoverConfirmed)
                    const Pill(
                      'Đã bàn giao phòng',
                      dense: true,
                      color: PT.green,
                    ),
                ],
              ),
              if (r.terminationReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PT.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Lý do thanh lý: ${r.terminationReason}',
                    style: PT.body(13, PT.error),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (!r.checkedIn && r.status == RentalStatus.active) ...[
                PrimaryButton(
                  'Xác nhận bàn giao phòng',
                  outline: true,
                  icon: LucideIcons.keyRound,
                  busy: f.busy,
                  onTap: f.busy
                      ? null
                      : () => f.perform(
                          () => state.workflows.confirmHandover(r.id),
                        ),
                ),
                const SizedBox(height: 10),
              ],
              if (r.checkedIn && r.status == RentalStatus.active) ...[
                PrimaryButton(
                  'Đánh giá người thuê',
                  outline: true,
                  icon: LucideIcons.star,
                  onTap: () => openPage(
                    ctx,
                    ReviewScreen(state: state, rentalId: r.id),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              PrimaryButton(
                'Liên hệ người thuê',
                icon: LucideIcons.messageSquare,
                onTap: () {
                  final existing = state.conversations
                      .where(
                        (c) =>
                            c.participantId == r.tenantId &&
                            c.roomId == r.room.id,
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
              if (r.status == RentalStatus.active) ...[
                const SizedBox(height: 6),
                TextButton.icon(
                  icon: const Icon(
                    LucideIcons.fileX,
                    size: 16,
                    color: PT.error,
                  ),
                  onPressed: f.busy
                      ? null
                      : () async {
                          final reasonCtrl = TextEditingController();
                          final reason = await showDialog<String>(
                            context: ctx,
                            builder: (d) => AlertDialog(
                              title: const Text('Chấm dứt hợp đồng'),
                              content: TextField(
                                controller: reasonCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Lý do chấm dứt / thanh lý',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(d),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(d, reasonCtrl.text),
                                  child: const Text('Xác nhận'),
                                ),
                              ],
                            ),
                          );
                          if (reason != null && reason.trim().isNotEmpty) {
                            await f.perform(
                              () => state.workflows.terminateRental(
                                r.id,
                                reason,
                              ),
                            );
                          }
                        },
                  label: Text(
                    'Chấm dứt hợp đồng',
                    style: PT.body(13, PT.error),
                  ),
                ),
              ],
            ]),
        ];
      },
    );
  }
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

class LandlordSwapsScreen extends StatefulWidget {
  final AppState state;
  const LandlordSwapsScreen({super.key, required this.state});
  @override
  State<LandlordSwapsScreen> createState() => _LandlordSwapsScreenState();
}

class _LandlordSwapsScreenState extends State<LandlordSwapsScreen> {
  String filter = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return FlowPage(
      state: state,
      title: 'Yêu cầu đổi phòng',
      content: (ctx, f) {
        final items = state.swaps.where((s) {
          if (filter == 'Chờ duyệt') return s.status == 'Chờ duyệt';
          if (filter == 'Đã duyệt') return s.status == 'Đã duyệt';
          if (filter == 'Lịch sử') return s.status != 'Chờ duyệt';
          return true;
        }).toList();

        return [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Tất cả', 'Chờ duyệt', 'Đã duyệt', 'Lịch sử']
                .map(
                  (v) => ChoiceChip(
                    label: Text(v),
                    selected: filter == v,
                    onSelected: (_) => setState(() => filter = v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const EmptyState(
              'Chưa có yêu cầu',
              'Chỉ yêu cầu thuộc phòng của bạn được hiển thị.',
            ),
          for (final s in items)
            flowCard('${s.id} • ${s.status}', [
              Text(
                state.roomById(s.roomId)?.title ?? s.roomId,
                style: PT.title(19),
              ),
              const SizedBox(height: 4),
              Text(
                state.store.workspaceById(s.tenantId).fullName,
                style: PT.body(14, PT.deep).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(s.reason),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Pill(s.targetDistrict, dense: true, color: PT.green),
                  Pill(s.targetType, dense: true, color: PT.green),
                  Pill('Ngân sách ≤ ${s.budgetMax}đ', dense: true, color: PT.green),
                ],
              ),
              if (s.decisionNote.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(s.decisionNote, style: PT.body(13, PT.muted)),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PT.mint.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PT.green.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.arrowLeftRight,
                          size: 16,
                          color: PT.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'So sánh người thuê chuyển đi & thay thế',
                            style: PT.title(15),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: PT.line),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.arrowUpRight,
                          size: 15,
                          color: PT.muted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Chuyển đi: ${state.store.workspaceById(s.tenantId).fullName} (TrustScore: ${state.store.profiles[s.tenantId]?.trustScore ?? 91}/100 • ${state.store.workspaceById(s.tenantId).verification})',
                            style: PT.body(13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Builder(
                      builder: (_) {
                        final prop = state.store.proposals
                            .where((p) => p.listingId == s.id)
                            .firstOrNull;
                        final text = prop != null
                            ? 'Chuyển đến: ${state.store.workspaceById(prop.proposerId).fullName} (TrustScore: ${state.store.profiles[prop.proposerId]?.trustScore ?? 90}/100 • ${state.store.workspaceById(prop.proposerId).verification})'
                            : 'Ứng viên dự kiến: ${state.people.firstOrNull?.name ?? 'Trần Gia Bảo'} (Hợp ${state.people.firstOrNull?.match ?? 94}% • Đã xác minh CCCD)';
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              LucideIcons.arrowDownLeft,
                              size: 15,
                              color: PT.green,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                text,
                                style: PT.body(13, PT.green).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(LucideIcons.fileText, size: 16),
                onPressed: () {
                  final roomTitle = state.roomById(s.roomId)?.title ?? s.roomId;
                  final outName = state.store
                      .workspaceById(s.tenantId)
                      .fullName;
                  final prop = state.store.proposals
                      .where((p) => p.listingId == s.id)
                      .firstOrNull;
                  final inName = prop != null
                      ? state.store.workspaceById(prop.proposerId).fullName
                      : (state.people.firstOrNull?.name ?? 'Trần Gia Bảo');
                  showDialog<void>(
                    context: ctx,
                    builder: (d) => AlertDialog(
                      title: const Text('Phụ lục hợp đồng nháp'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'PHỤ LỤC CHUYỂN NHƯỢNG HỢP ĐỒNG THUÊ',
                              style: PT.title(16),
                            ),
                            const SizedBox(height: 8),
                            Text('Phòng: $roomTitle'),
                            Text('Bên chuyển nhượng (A): $outName'),
                            Text('Bên nhận chuyển nhượng (B): $inName'),
                            Text(
                              'Ngày chuyển giao dự kiến: ${s.movingDate.isEmpty ? 'Đầu tháng tới' : s.movingDate}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Điều khoản: Bên B kế thừa toàn bộ quyền và nghĩa vụ hợp đồng thuê hiện tại, bao gồm khoản tiền đặt cọc đã nộp cho Chủ trọ.',
                              style: PT.body(13, PT.muted),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(d),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  );
                },
                label: const Text('Xem phụ lục hợp đồng nháp'),
              ),
              if (s.status == 'Chờ duyệt') ...[
                const SizedBox(height: 8),
                PrimaryButton(
                  'Duyệt yêu cầu',
                  icon: LucideIcons.check,
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
                              () =>
                                  state.workflows.decideSwap(s.id, false, note),
                            );
                          }
                        },
                  child: const Text('Từ chối yêu cầu'),
                ),
              ],
            ]),
        ];
      },
    );
  }
}

class LandlordReviewsScreen extends StatefulWidget {
  final AppState state;
  const LandlordReviewsScreen({super.key, required this.state});
  @override
  State<LandlordReviewsScreen> createState() => _LandlordReviewsScreenState();
}

class _LandlordReviewsScreenState extends State<LandlordReviewsScreen> {
  String filter = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return FlowPage(
      state: s,
      title: 'Đánh giá',
      content: (ctx, f) {
        final allReviews = s.store.reviewRecords
            .where((r) => s.myRooms.any((room) => room.id == r.targetId))
            .toList();
        final filtered = allReviews.where((r) {
          if (filter == 'Chưa phản hồi') return r.landlordReply == null;
          if (filter == '1-2 sao') return r.rating <= 2;
          if (filter == 'Khiếu nại') return r.disputeStatus != null;
          return true;
        }).toList();

        final avgRating = allReviews.isEmpty
            ? '4.9'
            : (allReviews.map((r) => r.rating).reduce((a, b) => a + b) /
                      allReviews.length)
                  .toStringAsFixed(1);
        final repliedCount = allReviews
            .where((r) => r.landlordReply != null)
            .length;

        return [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PT.line),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Điểm trung bình', style: PT.body(12, PT.muted)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 22,
                          color: PT.amber,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$avgRating (${allReviews.length} đánh giá)',
                            style: PT.title(20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Đã phản hồi', style: PT.body(12, PT.muted)),
                    const SizedBox(height: 4),
                    Text(
                      '$repliedCount/${allReviews.length} nhận xét',
                      style: PT.title(18).copyWith(color: PT.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            'Viết đánh giá người thuê',
            icon: LucideIcons.penLine,
            onTap: () => openPage(ctx, ReviewScreen(state: s)),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            'Xem đánh giá nhận được / đã gửi',
            outline: true,
            icon: LucideIcons.history,
            onTap: () => openPage(ctx, ReviewHistoryScreen(state: s)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Tất cả', 'Chưa phản hồi', '1-2 sao', 'Khiếu nại']
                .map(
                  (v) => ChoiceChip(
                    label: Text(v),
                    selected: filter == v,
                    onSelected: (_) => setState(() => filter = v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          for (final r in filtered)
            flowCard('${r.authorName} • ${r.rating}/5', [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Pill(
                    'Vệ sinh ${r.cleanlinessRating}/5',
                    dense: true,
                    color: PT.green,
                  ),
                  Pill(
                    'Mô tả ${r.accuracyRating}/5',
                    dense: true,
                    color: PT.green,
                  ),
                  Pill(
                    'Giao tiếp ${r.communicationRating}/5',
                    dense: true,
                    color: PT.green,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(r.comment, style: PT.body(14)),
              if (r.tags.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(r.tags.join(' • '), style: PT.body(12, PT.muted)),
              ],
              const SizedBox(height: 4),
              Text('Hợp đồng: ${r.rentalId}', style: PT.body(12, PT.muted)),
              if (r.landlordReply != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PT.mint,
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(
                      left: BorderSide(color: PT.green, width: 3),
                    ),
                  ),
                  child: Text(
                    'Phản hồi của bạn: ${r.landlordReply}',
                    style: PT.body(13, PT.deep),
                  ),
                ),
              ],
              if (r.disputeStatus != null) ...[
                const SizedBox(height: 8),
                Pill('Khiếu nại: ${r.disputeStatus}', color: PT.amber),
                if (r.disputeResolutionNote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Kết luận Admin: ${r.disputeResolutionNote}',
                      style: PT.body(12, PT.muted),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    icon: const Icon(LucideIcons.reply, size: 15),
                    onPressed: f.busy
                        ? null
                        : () async {
                            final c = TextEditingController(
                              text: r.landlordReply ?? '',
                            );
                            final reply = await showDialog<String>(
                              context: ctx,
                              builder: (d) => AlertDialog(
                                title: const Text('Phản hồi đánh giá'),
                                content: TextField(
                                  controller: c,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Nội dung phản hồi công khai',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(d),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(d, c.text),
                                    child: const Text('Gửi phản hồi'),
                                  ),
                                ],
                              ),
                            );
                            if (reply != null && reply.trim().isNotEmpty) {
                              await f.perform(
                                () => s.workflows.replyReview(r.id, reply),
                              );
                            }
                          },
                    label: Text(
                      r.landlordReply == null
                          ? 'Phản hồi đánh giá'
                          : 'Sửa phản hồi',
                    ),
                  ),
                  if (r.disputeStatus == null)
                    TextButton.icon(
                      icon: const Icon(
                        LucideIcons.flag,
                        size: 15,
                        color: PT.error,
                      ),
                      onPressed: f.busy
                          ? null
                          : () async {
                              final c = TextEditingController();
                              final reason = await showDialog<String>(
                                context: ctx,
                                builder: (d) => AlertDialog(
                                  title: const Text('Khiếu nại đánh giá'),
                                  content: TextField(
                                    controller: c,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      labelText:
                                          'Lý do khiếu nại lên Quản trị viên',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(d),
                                      child: const Text('Hủy'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(d, c.text),
                                      child: const Text('Gửi khiếu nại'),
                                    ),
                                  ],
                                ),
                              );
                              if (reason != null && reason.trim().isNotEmpty) {
                                await f.perform(
                                  () =>
                                      s.workflows.disputeReview(r.id, reason),
                                );
                              }
                            },
                      label: Text(
                        'Khiếu nại đánh giá',
                        style: PT.body(13, PT.error),
                      ),
                    ),
                ],
              ),
            ]),
        ];
      },
    );
  }
}
