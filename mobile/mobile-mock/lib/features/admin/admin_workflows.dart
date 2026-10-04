import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../core/flow_page.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../demo/models.dart';
import '../account/account_screens.dart';
import '../rooms/room_screens.dart';

class AdminScreen extends StatelessWidget {
  final AppState state;
  const AdminScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Header(
          admin: true,
          unreadNotifications: state.unreadNotifications,
          onMap: () => openPage(context, AdminUsersScreen(state: state)),
          onNotifications: () =>
              openPage(context, NotificationsScreen(state: state)),
        ),
        const PageHeading('Quản trị viên', 'Tổng quan hệ thống Phòng Trọ Xanh'),
        LayoutBuilder(
          builder: (context, c) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final stat in [
                ('Người dùng', state.store.profiles.length),
                ('Phòng trọ', state.rooms.length),
                (
                  'Báo cáo chờ xử lý',
                  state.store.reports
                      .where((r) => r.status == 'Chờ xử lý')
                      .length,
                ),
                (
                  'CCCD chờ duyệt',
                  state.store.kyc.where((k) => k.status == 'Chờ duyệt').length,
                ),
              ])
                SizedBox(
                  width: (c.maxWidth - 10) / 2,
                  child: flowCard(stat.$1, [
                    Text(
                      '${stat.$2}',
                      style: PT.title(32).copyWith(color: PT.green),
                    ),
                  ]),
                ),
            ],
          ),
        ),
        MenuRow(
          icon: LucideIcons.fileCheck,
          title: 'Duyệt CCCD',
          subtitle: 'Hồ sơ và kết quả theo submission ID',
          onTap: () => openPage(context, AdminQueueScreen(state: state)),
        ),
        MenuRow(
          icon: LucideIcons.house,
          title: 'Duyệt tin phòng',
          subtitle:
              '${state.rooms.where((r) => r.status == RoomStatus.pending).length} tin chờ duyệt',
          onTap: () => openPage(context, AdminRoomsScreen(state: state)),
        ),
        MenuRow(
          icon: LucideIcons.flag,
          title: 'Báo cáo vi phạm',
          subtitle: 'Nội dung, xử lý và lịch sử',
          onTap: () => openPage(context, AdminReportsScreen(state: state)),
        ),
        MenuRow(
          icon: LucideIcons.users,
          title: 'Quản lý người dùng',
          subtitle: 'Tra cứu, khóa / mở khóa',
          onTap: () => openPage(context, AdminUsersScreen(state: state)),
        ),
        const SizedBox(height: 16),
        Text(
          'Số liệu lấy từ kho demo đang dùng chung, cập nhật khi xử lý. Chưa có dữ liệu hoạt động thật để vẽ biểu đồ.',
          style: PT.body(13, PT.muted),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          'Đăng xuất',
          outline: true,
          onTap: () => AppScope.maybeOf(context)?.logout(),
        ),
      ],
    ),
  );
}

class AdminQueueScreen extends StatefulWidget {
  final AppState state;
  const AdminQueueScreen({super.key, required this.state});
  @override
  State<AdminQueueScreen> createState() => _AdminQueueScreenState();
}

class _AdminQueueScreenState extends State<AdminQueueScreen> {
  String filter = 'Chờ duyệt';
  @override
  Widget build(BuildContext context) => FlowPage(
    state: widget.state,
    title: 'Duyệt CCCD',
    content: (ctx, f) {
      final items = widget.state.store.kyc
          .where((k) => filter == 'Tất cả' || k.status == filter)
          .toList();
      return [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Chờ duyệt', 'Đã xác minh', 'Đã từ chối', 'Tất cả']
              .map(
                (v) => ChoiceChip(
                  label: Text(v),
                  selected: v == filter,
                  onSelected: (_) => setState(() => filter = v),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const EmptyState(
            'Không có hồ sơ trong mục này',
            'Hồ sơ gửi từ người thuê hoặc chủ trọ sẽ xuất hiện tại đây.',
          ),
        for (final k in items.reversed)
          MenuRow(
            icon: LucideIcons.fileCheck,
            title: widget.state.store.workspaceById(k.userId).fullName,
            subtitle: '${k.id} • ${k.status}',
            onTap: () => openPage(
              ctx,
              AdminDecisionScreen(state: widget.state, kind: 'kyc', id: k.id),
            ),
          ),
      ];
    },
  );
}

class AdminReportsScreen extends StatefulWidget {
  final AppState? state;
  const AdminReportsScreen({super.key, this.state});
  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String filter = 'Chờ xử lý';
  @override
  Widget build(BuildContext context) {
    final s = widget.state ?? AppScope.maybeOf(context)!.state;
    return FlowPage(
      state: s,
      title: 'Báo cáo vi phạm',
      content: (ctx, f) {
        final items = s.store.reports
            .where((r) => filter == 'Tất cả' || r.status == filter)
            .toList();
        return [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Chờ xử lý', 'Đã xử lý', 'Đã bỏ qua', 'Tất cả']
                .map(
                  (v) => ChoiceChip(
                    label: Text(v),
                    selected: v == filter,
                    onSelected: (_) => setState(() => filter = v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const EmptyState(
              'Không có báo cáo trong mục này',
              'Báo cáo từ app dùng chung hàng đợi này.',
            ),
          for (final r in items.reversed)
            MenuRow(
              icon: LucideIcons.flag,
              title: r.reason,
              subtitle: '${r.id} • ${r.targetType} ${r.targetId} • ${r.status}',
              onTap: () => openPage(
                ctx,
                AdminDecisionScreen(state: s, kind: 'report', id: r.id),
              ),
            ),
        ];
      },
    );
  }
}

class AdminUsersScreen extends StatefulWidget {
  final AppState? state;
  const AdminUsersScreen({super.key, this.state});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String query = '', filter = 'Tất cả';
  @override
  Widget build(BuildContext context) {
    final s = widget.state ?? AppScope.maybeOf(context)!.state;
    return FlowPage(
      state: s,
      title: 'Người dùng',
      content: (ctx, f) {
        final items = s.store.profiles.values
            .where(
              (p) =>
                  !s.store.deleted.contains(p.user.id) &&
                  '${s.store.workspace(p.user).fullName} ${p.user.email} ${p.user.phone}'
                      .toLowerCase()
                      .contains(query.toLowerCase()) &&
                  (filter == 'Tất cả' ||
                      (filter == 'Đã khóa') ==
                          s.store.blocked.contains(p.user.id)),
            )
            .toList();
        return [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Tìm tên, email, số điện thoại',
              prefixIcon: Icon(LucideIcons.search),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Tất cả', 'Hoạt động', 'Đã khóa']
                .map(
                  (v) => ChoiceChip(
                    label: Text(v),
                    selected: v == filter,
                    onSelected: (_) => setState(() => filter = v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const EmptyState(
              'Không có người dùng phù hợp',
              'Thay đổi từ khóa hoặc trạng thái.',
            ),
          for (final p in items)
            MenuRow(
              icon: LucideIcons.user,
              title: s.store.workspace(p.user).fullName,
              subtitle:
                  '${p.user.email} • ${p.user.role.name} • ${s.store.blocked.contains(p.user.id) ? 'Đã khóa' : 'Hoạt động'}',
              onTap: () => openPage(
                ctx,
                AdminDecisionScreen(state: s, kind: 'user', id: p.user.id),
              ),
            ),
        ];
      },
    );
  }
}

class AdminDecisionScreen extends StatefulWidget {
  final AppState state;
  final String kind, id;
  const AdminDecisionScreen({
    super.key,
    required this.state,
    required this.kind,
    required this.id,
  });
  @override
  State<AdminDecisionScreen> createState() => _AdminDecisionScreenState();
}

class _AdminDecisionScreenState extends State<AdminDecisionScreen> {
  final note = TextEditingController();
  String action = 'resolve';
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FlowPage(
    state: widget.state,
    title: 'Chi tiết ${widget.id}',
    content: (ctx, f) {
      final s = widget.state;
      if (widget.kind == 'kyc') {
        final k = s.store.kyc.where((k) => k.id == widget.id).firstOrNull;
        if (k == null) {
          return [
            const EmptyState(
              'Hồ sơ không tồn tại',
              'Quay lại danh sách để tải lại.',
            ),
          ];
        }
        return [
          flowCard(s.store.workspaceById(k.userId).fullName, [
            Text('${k.id} • ${k.status}'),
            Text('Số CCCD: ${k.number}'),
            Text(k.note),
          ]),
          VerificationDocument(
            state: s,
            userId: k.userId,
            reference: k.front,
            side: 'Mặt trước',
          ),
          const SizedBox(height: 16),
          VerificationDocument(
            state: s,
            userId: k.userId,
            reference: k.back,
            side: 'Mặt sau',
          ),
          const SizedBox(height: 16),
          if (k.status == 'Chờ duyệt') ...[
            TextField(
              controller: note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú / lý do từ chối',
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              'Duyệt hồ sơ',
              busy: f.busy,
              onTap: f.busy
                  ? null
                  : () => f.perform(
                      () => s.workflows.decideKyc(k.id, true, note.text),
                    ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              'Từ chối hồ sơ',
              outline: true,
              onTap: f.busy
                  ? null
                  : () => f.perform(
                      () => s.workflows.decideKyc(k.id, false, note.text),
                    ),
            ),
          ],
        ];
      }
      if (widget.kind == 'report') {
        final r = s.store.reports.where((r) => r.id == widget.id).firstOrNull;
        if (r == null) {
          return [
            const EmptyState('Không tìm thấy báo cáo', 'Quay lại danh sách.'),
          ];
        }
        return [
          flowCard('${r.id} • ${r.status}', [
            Text(r.reason, style: PT.title(22)),
            Text(r.details),
            Text('Đối tượng: ${r.targetType} ${r.targetId}'),
            Text('Người gửi: ${s.store.workspaceById(r.reporterId).fullName}'),
            ...r.history.map(Text.new),
          ]),
          if (r.status == 'Chờ xử lý') ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: action,
              decoration: const InputDecoration(labelText: 'Hành động'),
              items: const [
                DropdownMenuItem(
                  value: 'resolve',
                  child: Text('Đánh dấu đã xử lý'),
                ),
                DropdownMenuItem(
                  value: 'warn',
                  child: Text('Cảnh báo / ghi nhận'),
                ),
                DropdownMenuItem(
                  value: 'remove_content',
                  child: Text('Ẩn tin phòng'),
                ),
                DropdownMenuItem(
                  value: 'ban',
                  child: Text('Khóa tài khoản đối tượng'),
                ),
                DropdownMenuItem(
                  value: 'dismiss',
                  child: Text('Bỏ qua báo cáo'),
                ),
              ],
              onChanged: (v) => setState(() => action = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú xử lý (bắt buộc)',
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              'Xác nhận xử lý',
              busy: f.busy,
              onTap: f.busy
                  ? null
                  : () async {
                      if (await confirmAction(
                        ctx,
                        'Xử lý ${r.id}?',
                        'Hành động được lưu vào lịch sử. Ẩn tin hoặc khóa tài khoản sẽ cập nhật dữ liệu demo tương ứng.',
                      )) {
                        await f.perform(
                          () => s.workflows.resolveReport(
                            r.id,
                            action,
                            note.text,
                          ),
                        );
                      }
                    },
            ),
          ],
        ];
      }
      final p = s.store.profiles[widget.id];
      if (p == null) {
        return [
          const EmptyState('Không tìm thấy tài khoản', 'Quay lại danh sách.'),
        ];
      }
      final blocked = s.store.blocked.contains(widget.id);
      return [
        flowCard(s.store.workspace(p.user).fullName, [
          Text(p.user.email),
          Text(p.user.phone),
          Text('Vai trò: ${p.user.role.name}'),
          Text(blocked ? 'Đã khóa' : 'Hoạt động'),
          Text('Xác minh: ${s.store.workspace(p.user).verification}'),
        ]),
        if (p.user.id != s.userId) ...[
          TextField(
            controller: note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Lý do thay đổi trạng thái',
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            blocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
            busy: f.busy,
            onTap: f.busy
                ? null
                : () async {
                    if (await confirmAction(
                      ctx,
                      'Thay đổi trạng thái tài khoản?',
                      p.user.email,
                    )) {
                      await f.perform(
                        () => s.workflows.userStatus(
                          p.user.id,
                          !blocked,
                          note.text,
                        ),
                      );
                    }
                  },
          ),
        ],
      ];
    },
  );
}

class AdminRoomsScreen extends StatelessWidget {
  final AppState state;
  const AdminRoomsScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) => FlowPage(
    state: state,
    title: 'Duyệt tin phòng',
    content: (ctx, f) => [
      if (!state.rooms.any((r) => r.status == RoomStatus.pending))
        const EmptyState(
          'Không có tin chờ duyệt',
          'Tin mới / tin sửa của chủ trọ sẽ xuất hiện ở đây.',
        ),
      for (final r in state.rooms.where((r) => r.status == RoomStatus.pending))
        flowCard(r.title, [
          Text(r.address),
          Text('${r.price}đ/tháng • ${r.area}m² • Tầng ${r.floor}'),
          Text(r.landlordName),
          Text(r.description),
          const SizedBox(height: 12),
          PrimaryButton(
            'Xem chi tiết tin',
            outline: true,
            onTap: () => openPage(ctx, RoomDetailScreen(state: state, room: r)),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            'Duyệt tin phòng',
            busy: f.busy,
            onTap: f.busy
                ? null
                : () =>
                      f.perform(() => state.workflows.moderateRoom(r.id, true)),
          ),
          TextButton(
            onPressed: f.busy
                ? null
                : () => f.perform(
                    () => state.workflows.moderateRoom(r.id, false),
                  ),
            child: const Text('Từ chối / ẩn tin'),
          ),
        ]),
    ],
  );
}
