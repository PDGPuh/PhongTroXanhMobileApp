import 'welcome_carousel.dart';
import '../account/account_workflows.dart';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../core/reference_photo.dart';
import 'recovery_screen.dart';
export 'recovery_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onExplore, onLogin;
  const WelcomeScreen({
    super.key,
    required this.onExplore,
    required this.onLogin,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(17, 12, 17, 22),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onExplore,
              child: Text('Bỏ qua', style: PT.body(14, PT.muted)),
            ),
          ),
          const Brand(),
          const SizedBox(height: 23),
          Text(
            'Ở đúng người.\nỞ đúng nơi.',
            style: PT.title(34).copyWith(height: 1.35),
          ),
          const SizedBox(height: 14),
          Text(
            'Dễ dàng tìm phòng trọ phù hợp\nvà kết nối với những người bạn cùng lối sống.',
            style: PT.body(16, PT.muted),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Feature(LucideIcons.house, 'Hàng ngàn\nphòng trọ đẹp'),
              _Feature(LucideIcons.users, 'Tìm bạn ở\nphù hợp'),
              _Feature(LucideIcons.shieldCheck, 'Phòng xác thực\nan tâm thuê'),
            ],
          ),
          const SizedBox(height: 20),
          const WelcomeCarousel(),
          const SizedBox(height: 18),
          PrimaryButton(
            'Bắt đầu tìm phòng',
            icon: LucideIcons.search,
            onTap: onExplore,
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            'Đăng nhập',
            icon: LucideIcons.user,
            outline: true,
            onTap: onLogin,
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              const Icon(LucideIcons.shieldCheck, color: PT.green, size: 17),
              const SizedBox(width: 6),
              Text('1.200+ phòng xác thực', style: PT.body(11, PT.muted)),
              const SizedBox(width: 10),
              const Icon(LucideIcons.star, color: PT.green, size: 17),
              const SizedBox(width: 6),
              Text('4.8/5 đánh giá', style: PT.body(11, PT.muted)),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Feature(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: const BoxDecoration(
            color: PT.mint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 25),
        ),
        const SizedBox(height: 7),
        Text(label, textAlign: TextAlign.center, style: PT.body(12, PT.muted)),
      ],
    ),
  );
}

class LoginScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onSignedIn, onBack;
  const LoginScreen({
    super.key,
    required this.state,
    required this.onSignedIn,
    required this.onBack,
  });
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final login = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController(),
      phone = TextEditingController(),
      confirm = TextEditingController();
  bool obscure = true, register = false, busy = false;
  String? error;
  @override
  void dispose() {
    login.dispose();
    password.dispose();
    name.dispose();
    phone.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Quay lại',
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: widget.onBack,
            ),
          ),
          const SizedBox(height: 12),
          const Center(child: Brand()),
          const SizedBox(height: 30),
          Text(
            register ? 'Đăng ký' : 'Đăng nhập',
            style: PT.title(32),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 13),
          Text(
            register ? 'Bắt đầu hành trình tìm nơi ở phù hợp.' : 'Chào mừng bạn quay trở lại!\nCùng xây dựng những không gian sống tốt đẹp hơn.',
            style: PT.body(14, PT.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Form(
            key: form,
            child: Column(
              children: [
                if (register) ...[
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon: Icon(LucideIcons.user),
                    ),
                    validator: (v) => register && (v?.trim().isEmpty ?? true)
                        ? 'Nhập họ và tên'
                        : null,
                  ),
                  const SizedBox(height: 13),
                ],
                TextFormField(
                  controller: login,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  decoration: InputDecoration(
                    labelText: register ? 'Email' : 'Email hoặc số điện thoại',
                    prefixIcon: Icon(LucideIcons.mail),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nhập email hoặc số điện thoại'
                      : register &&
                            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(v.trim())
                      ? 'Nhập email hợp lệ'
                      : null,
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: password,
                  obscureText: obscure,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(LucideIcons.lockKeyhole),
                    suffixIcon: IconButton(
                      tooltip: obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                      icon: Icon(
                        obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                      ),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 6
                      ? 'Mật khẩu cần ít nhất 6 ký tự'
                      : null,
                ),
                if (register) ...[
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(LucideIcons.phone),
                    ),
                    validator: (v) =>
                        register &&
                            !RegExp(r'^\d{9,11}$').hasMatch(v?.trim() ?? '')
                        ? 'Số điện thoại cần 9–11 chữ số'
                        : null,
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: confirm,
                    obscureText: obscure,
                    decoration: const InputDecoration(
                      labelText: 'Xác nhận mật khẩu',
                      prefixIcon: Icon(LucideIcons.lockKeyhole),
                    ),
                    validator: (v) => register && v != password.text
                        ? 'Mật khẩu xác nhận chưa khớp'
                        : null,
                  ),
                ],
              ],
            ),
          ),
          if (!register)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: busy
                    ? null
                    : () => openPage(
                        context,
                        ForgotPasswordScreen(state: widget.state),
                      ),
                child: const Text('Quên mật khẩu?'),
              ),
            ),
          const SizedBox(height: 8),
          PrimaryButton(
            register ? 'Tạo tài khoản' : 'Đăng nhập',
            busy: busy,
            onTap: busy
                ? null
                : () async {
                    if (!form.currentState!.validate()) return;
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    final ok = register
                        ? await widget.state.session.register(
                            email: login.text,
                            password: password.text,
                            name: name.text,
                            phone: phone.text.trim(),
                          )
                        : await widget.state.authenticate(
                            login.text,
                            password.text,
                          );
                    if (!context.mounted) return;
                    setState(() {
                      busy = false;
                      error = widget.state.session.error;
                    });
                    if (!ok) return;
                    if (register) {
                      openPage(
                        context,
                        OnboardingScreen(
                          state: widget.state,
                          onComplete: () {
                            Navigator.pop(context);
                            widget.onSignedIn();
                          },
                        ),
                      );
                    } else {
                      widget.onSignedIn();
                    }
                  },
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Semantics(
                liveRegion: true,
                child: Text(error!, style: PT.body(14, PT.error)),
              ),
            ),
          if (!register)
            ExpansionTile(
              title: Text('Thử tài khoản mẫu', style: PT.body(13, PT.green)),
              subtitle: Text(
                'Dữ liệu demo • mật khẩu demo123',
                style: PT.body(11, PT.muted),
              ),
              children: [
                for (final account in [
                  ('Người thuê', 'tenant@demo.vn'),
                  ('Chủ trọ', 'landlord@demo.vn'),
                  ('Quản trị', 'admin@demo.vn'),
                ])
                  ListTile(
                    title: Text(account.$1),
                    subtitle: Text(account.$2),
                    onTap: busy
                        ? null
                        : () => setState(() {
                            login.text = account.$2;
                            password.text = 'demo123';
                          }),
                  ),
              ],
            ),
          const SizedBox(height: 21),
          Row(
            children: [
              const Expanded(child: Divider()),
              Flexible(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  child: Text(
                    'Hoặc đăng nhập bằng',
                    textAlign: TextAlign.center,
                    style: PT.body(12, PT.muted),
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              for (final social in [
                ('Google', PhotoKind.google),
                ('Apple', PhotoKind.apple),
                ('Facebook', PhotoKind.facebook),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 14,
                        ),
                        side: const BorderSide(color: PT.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => message(
                        context,
                        'Đăng nhập ${social.$1} sẽ hoạt động khi nối dịch vụ xác thực.',
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: ReferencePhoto(kind: social.$2),
                          ),
                          const SizedBox(width: 6),
                          Flexible(child: Text(social.$1, style: PT.body(12))),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                register ? 'Đã có tài khoản?' : 'Chưa có tài khoản?',
                style: PT.body(13, PT.muted),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() {
                        register = !register;
                        error = null;
                        form.currentState?.reset();
                      }),
                child: Text(register ? 'Đăng nhập' : 'Đăng ký'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const ReferencePhoto(kind: PhotoKind.illustration, height: 155),
        ],
      ),
    ),
  );
}

class OnboardingScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback onComplete;
  const OnboardingScreen({
    super.key,
    required this.state,
    required this.onComplete,
  });
  @override
  Widget build(BuildContext context) =>
      ProfileSetupScreen(state: state, onComplete: onComplete);
}
