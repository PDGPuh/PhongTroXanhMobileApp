import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_state.dart';
import '../../app/session.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'password_recovery.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final AppState state;
  const ForgotPasswordScreen({super.key, required this.state});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController(),
      otp = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  final form = GlobalKey<FormState>();
  PasswordRecoveryController? controller;
  Timer? ticker;
  bool obscure = true;
  @override
  void initState() {
    super.initState();
    final repo = widget.state.session.repository;
    if (repo is PasswordRecoveryRepository) {
      controller = PasswordRecoveryController(
        repo as PasswordRecoveryRepository,
      );
    }
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && controller?.step == 1) setState(() {});
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    controller?.dispose();
    for (final c in [email, otp, password, confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    final c = controller!;
    if (!form.currentState!.validate() || c.busy) return;
    FocusScope.of(context).unfocus();
    switch (c.step) {
      case 0:
        await c.send(email.text);
      case 1:
        await c.verify(otp.text);
      case 2:
        await c.reset(password.text, confirm.text);
    }
    if (mounted) form.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null) {
      return const BasicPage(
        title: 'Quên mật khẩu',
        child: EmptyState(
          'Chưa thể khôi phục mật khẩu',
          'Dịch vụ xác thực hiện chưa hỗ trợ thao tác này.',
        ),
      );
    }
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => PopScope(
        canPop: !c.busy && (c.step == 0 || c.step == 3),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !c.busy) c.back();
        },
        child: BasicPage(
          title: 'Quên mật khẩu',
          customBack: true,
          onBack: c.busy
              ? null
              : () {
                  if (c.step == 0 || c.step == 3) {
                    Navigator.pop(context);
                  } else {
                    c.back();
                  }
                },
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            children: [
              const Brand(),
              const SizedBox(height: 26),
              Text('Bước ${c.step + 1}/4', style: PT.body(13, PT.green)),
              const SizedBox(height: 8),
              Text(
                [
                  'Khôi phục tài khoản',
                  'Nhập mã OTP',
                  'Đặt mật khẩu mới',
                  'Đã đổi mật khẩu',
                ][c.step],
                style: PT.title(28),
              ),
              const SizedBox(height: 12),
              Text(
                [
                  'Nhập email đăng ký để nhận mã xác minh.',
                  'Nhập mã gồm 6 chữ số cho ${c.email}. Mã có hiệu lực 5 phút.',
                  'Mật khẩu cần ít nhất 6 ký tự. Bạn sẽ đăng nhập bằng mật khẩu mới.',
                  'Mật khẩu đã được cập nhật. Quay lại đăng nhập để tiếp tục.',
                ][c.step],
                style: PT.body(15, PT.muted),
              ),
              const SizedBox(height: 24),
              Form(
                key: form,
                child: Column(
                  children: [
                    if (c.step == 0)
                      TextFormField(
                        controller: email,
                        enabled: !c.busy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email đăng ký',
                          prefixIcon: Icon(LucideIcons.mail),
                        ),
                        validator: (v) =>
                            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(v?.trim() ?? '')
                            ? null
                            : 'Nhập email hợp lệ',
                        onFieldSubmitted: (_) => submit(),
                      ),
                    if (c.step == 1)
                      TextFormField(
                        controller: otp,
                        enabled: !c.busy,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Mã OTP 6 chữ số',
                          prefixIcon: Icon(LucideIcons.shieldCheck),
                        ),
                        validator: (v) =>
                            v?.length == 6 ? null : 'Nhập đủ 6 chữ số',
                        onFieldSubmitted: (_) => submit(),
                      ),
                    if (c.step == 2) ...[
                      TextFormField(
                        controller: password,
                        enabled: !c.busy,
                        obscureText: obscure,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu mới',
                          prefixIcon: const Icon(LucideIcons.lockKeyhole),
                          suffixIcon: IconButton(
                            tooltip: obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                            icon: Icon(
                              obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                            ),
                            onPressed: () => setState(() => obscure = !obscure),
                          ),
                        ),
                        validator: (v) => (v?.length ?? 0) >= 6
                            ? null
                            : 'Mật khẩu cần ít nhất 6 ký tự',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirm,
                        enabled: !c.busy,
                        obscureText: obscure,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Xác nhận mật khẩu',
                          prefixIcon: Icon(LucideIcons.lockKeyhole),
                        ),
                        validator: (v) => v == password.text
                            ? null
                            : 'Mật khẩu xác nhận chưa khớp',
                        onFieldSubmitted: (_) => submit(),
                      ),
                    ],
                  ],
                ),
              ),
              if (c.error != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(c.error!, style: PT.body(14, PT.error)),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                c.busy
                    ? 'Đang xử lý…'
                    : [
                        'Gửi mã OTP',
                        'Xác minh OTP',
                        'Cập nhật mật khẩu',
                        'Quay lại đăng nhập',
                      ][c.step],
                busy: c.busy,
                onTap: c.busy
                    ? null
                    : c.step == 3
                    ? () => Navigator.pop(context)
                    : submit,
              ),
              if (c.step == 1) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: c.busy || c.resendSeconds > 0
                      ? null
                      : () async {
                          if (await c.send(c.email)) otp.clear();
                        },
                  child: Text(
                    c.resendSeconds > 0
                        ? 'Gửi lại mã sau ${c.resendSeconds}s'
                        : 'Gửi lại mã OTP',
                  ),
                ),
                TextButton(
                  onPressed: c.busy ? null : c.changeEmail,
                  child: const Text('Thay đổi email'),
                ),
                if (widget.state.session.repository is DemoAuthRepository) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: PT.card(color: PT.mint),
                    child: Text(
                      'Chế độ demo • OTP: ${(widget.state.session.repository as DemoAuthRepository).demoOtp(c.email) ?? '—'}\nMã hiển thị tại đây để thử luồng; chưa gửi email.',
                      style: PT.body(13),
                    ),
                  ),
                ],
              ],
              if (c.step == 3)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Icon(
                    LucideIcons.circleCheck,
                    size: 64,
                    color: PT.green,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
