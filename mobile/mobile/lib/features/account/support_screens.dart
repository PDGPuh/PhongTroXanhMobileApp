import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../core/flow_page.dart';
import '../../core/widgets.dart';

class SupportScreen extends StatefulWidget {
  final AppState state;
  const SupportScreen({super.key, required this.state});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final subject = TextEditingController(), content = TextEditingController();
  @override
  void dispose() {
    subject.dispose();
    content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FlowPage(
    state: widget.state,
    title: 'Liên hệ hỗ trợ',
    content: (ctx, f) => [
      const Text(
        'Yêu cầu hỗ trợ demo được lưu cùng tài khoản. Chưa gửi email hay thông báo cho nhân viên thật.',
      ),
      const SizedBox(height: 16),
      TextField(
        controller: subject,
        decoration: const InputDecoration(labelText: 'Tiêu đề'),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: content,
        maxLines: 5,
        decoration: const InputDecoration(labelText: 'Nội dung cần hỗ trợ'),
      ),
      const SizedBox(height: 16),
      PrimaryButton(
        'Gửi yêu cầu hỗ trợ',
        busy: f.busy,
        onTap: f.busy
            ? null
            : () async {
                if (await f.perform(
                  () => widget.state.workflows.support(
                    subject.text,
                    content.text,
                  ),
                )) {
                  subject.clear();
                  content.clear();
                }
              },
      ),
      const SizedBox(height: 24),
      for (final t
          in widget.state.store.tickets
              .where((t) => t.userId == widget.state.userId)
              .toList()
              .reversed)
        flowCard('${t.id} • ${t.status}', [Text(t.subject), Text(t.content)]),
    ],
  );
}

class DeleteAccountScreen extends StatefulWidget {
  final AppState state;
  const DeleteAccountScreen({super.key, required this.state});
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final password = TextEditingController();
  bool acknowledged = false;
  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FlowPage(
    state: widget.state,
    title: 'Xóa tài khoản demo',
    content: (ctx, f) => [
      const Text(
        'Tài khoản này sẽ không đăng nhập lại được trong phiên demo. Lời thích, phòng lưu, bản nháp và hội thoại riêng được xóa; hồ sơ hợp đồng/giao dịch đã tạo vẫn lưu để đối chiếu. Tải lại trang sẽ khởi tạo dữ liệu demo mới.',
      ),
      const SizedBox(height: 16),
      TextField(
        controller: password,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
      ),
      const SizedBox(height: 12),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Tôi hiểu và muốn xóa tài khoản demo'),
        value: acknowledged,
        onChanged: f.busy
            ? null
            : (v) => setState(() => acknowledged = v ?? false),
      ),
      const SizedBox(height: 16),
      PrimaryButton(
        'Xác nhận xóa tài khoản',
        busy: f.busy,
        onTap: !acknowledged || f.busy
            ? null
            : () async {
                if (await confirmAction(
                  ctx,
                  'Xóa tài khoản demo?',
                  widget.state.email,
                )) {
                  if (await f.perform(
                        () =>
                            widget.state.workflows.deleteAccount(password.text),
                      ) &&
                      ctx.mounted) {
                    AppScope.maybeOf(ctx)?.logout();
                  }
                }
              },
      ),
    ],
  );
}

class PublicProfileScreen extends StatelessWidget {
  final AppState state;
  const PublicProfileScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) => FlowPage(
    state: state,
    title: 'Xem trước hồ sơ công khai',
    content: (ctx, f) {
      final p = state.store.profiles[state.userId]!;
      return [
        flowCard(state.fullName, [
          AvatarPhoto(kind: p.avatar, photo: p.avatarPhoto, size: 80),
          const SizedBox(height: 12),
          Text(state.bio),
          Text('${p.gender} • ${p.district}'),
          Text(p.school),
          Text('${p.budgetMin} – ${p.budgetMax}đ/tháng'),
          Text(state.interests.join(' • ')),
          Text(state.verification),
        ]),
        Text(
          state.settings['public'] == false
              ? 'Hồ sơ đang ẩn khỏi khám phá ghép bạn.'
              : 'Hồ sơ đang cho phép hiển thị ghép bạn.',
        ),
      ];
    },
  );
}
