import 'dart:math' as math;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final carouselHeight = (constraints.maxHeight - 392).clamp(
            140.0,
            415.0,
          );
          final lockViewport =
              constraints.maxHeight >= 520 && textScale <= 1.25;
          final minContentHeight = lockViewport
              ? math.max(0.0, constraints.maxHeight - 16)
              : 0.0;
          return ListView(
            physics: lockViewport
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: minContentHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Brand(compact: true)),
                        TextButton(
                          onPressed: onExplore,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                          ),
                          child: Text(
                            'Bỏ qua',
                            style: PT
                                .body(13, PT.muted)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: WelcomeCarousel(height: carouselHeight),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ở đúng người. Ở đúng nơi.',
                          style: PT.title(25).copyWith(height: 1.18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tìm phòng trọ xác thực và ghép bạn ở cùng lối sống.',
                          style: PT.body(13, PT.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F8F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: PT.line.withValues(alpha: .7),
                            ),
                          ),
                          child: const IntrinsicHeight(
                            child: Row(
                              children: [
                                _Feature(LucideIcons.house, 'Phòng xác thực'),
                                VerticalDivider(
                                  width: 8,
                                  thickness: 1,
                                  indent: 4,
                                  endIndent: 4,
                                  color: PT.line,
                                ),
                                _Feature(LucideIcons.users, 'Ghép hợp gu'),
                                VerticalDivider(
                                  width: 8,
                                  thickness: 1,
                                  indent: 4,
                                  endIndent: 4,
                                  color: PT.line,
                                ),
                                _Feature(
                                  LucideIcons.shieldCheck,
                                  'Hợp đồng số',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PrimaryButton(
                          'Bắt đầu tìm phòng',
                          icon: LucideIcons.search,
                          onTap: onExplore,
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          'Đăng nhập',
                          icon: LucideIcons.user,
                          outline: true,
                          onTap: onLogin,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 4,
                          children: [
                            const Icon(
                              LucideIcons.shieldCheck,
                              color: PT.green,
                              size: 13.5,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '1.200+ phòng xác thực',
                              style: PT.body(11.5, PT.muted),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text('•', style: PT.body(11.5, PT.line)),
                            ),
                            const Icon(
                              LucideIcons.star,
                              color: PT.green,
                              size: 13.5,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '4.8/5 đánh giá',
                              style: PT.body(11.5, PT.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: PT.green),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PT.body(11.5, PT.deep).copyWith(fontWeight: FontWeight.w600),
        ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final lockViewport =
              !register &&
              constraints.maxHeight >= 520 &&
              textScale <= 1.25 &&
              MediaQuery.viewInsetsOf(context).bottom == 0;
          final minContentHeight = lockViewport
              ? math.max(0.0, constraints.maxHeight - 16)
              : 0.0;
          final showBanner =
              lockViewport && constraints.maxHeight >= 620 && error == null;
          final bannerHeight = (constraints.maxHeight - 545).clamp(72.0, 260.0);
          return ListView(
            physics: lockViewport
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: minContentHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Quay lại',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(LucideIcons.arrowLeft),
                              onPressed: widget.onBack,
                            ),
                            const SizedBox(width: 4),
                            const Expanded(child: Brand(compact: true)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          register ? 'Đăng ký' : 'Đăng nhập',
                          style: PT.title(22),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          register
                              ? 'Bắt đầu hành trình tìm nơi ở phù hợp.'
                              : 'Chào mừng bạn quay trở lại Phòng Trọ Xanh!',
                          style: PT.body(12, PT.muted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        if (!register) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: PT.card(color: PT.mint, radius: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thử tài khoản mẫu (chạm để điền nhanh)',
                                  style: PT.caption(PT.deep),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    for (final account in [
                                      (
                                        'Người thuê',
                                        'tenant@demo.vn',
                                        LucideIcons.user,
                                      ),
                                      (
                                        'Chủ trọ',
                                        'landlord@demo.vn',
                                        LucideIcons.house,
                                      ),
                                      (
                                        'Quản trị',
                                        'admin@demo.vn',
                                        LucideIcons.shieldCheck,
                                      ),
                                    ])
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          child: Material(
                                            color: login.text == account.$2
                                                ? PT.green
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              9,
                                            ),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                              onTap: busy
                                                  ? null
                                                  : () => setState(() {
                                                      login.text = account.$2;
                                                      password.text = 'demo123';
                                                    }),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 7,
                                                    ),
                                                child: Column(
                                                  children: [
                                                    Icon(
                                                      account.$3,
                                                      size: 14,
                                                      color:
                                                          login.text ==
                                                              account.$2
                                                          ? Colors.white
                                                          : PT.green,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      account.$1,
                                                      style: PT.caption(
                                                        login.text == account.$2
                                                            ? Colors.white
                                                            : PT.deep,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
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
                                  validator: (v) =>
                                      register && (v?.trim().isEmpty ?? true)
                                      ? 'Nhập họ và tên'
                                      : null,
                                ),
                                const SizedBox(height: 8),
                              ],
                              TextFormField(
                                controller: login,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.username],
                                decoration: InputDecoration(
                                  labelText: register
                                      ? 'Email'
                                      : 'Email hoặc số điện thoại',
                                  prefixIcon: const Icon(LucideIcons.mail),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Nhập email hoặc số điện thoại'
                                    : register &&
                                          !RegExp(
                                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                          ).hasMatch(v.trim())
                                    ? 'Nhập email hợp lệ'
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: password,
                                obscureText: obscure,
                                autofillHints: const [AutofillHints.password],
                                decoration: InputDecoration(
                                  labelText: 'Mật khẩu',
                                  prefixIcon: const Icon(
                                    LucideIcons.lockKeyhole,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: obscure
                                        ? 'Hiện mật khẩu'
                                        : 'Ẩn mật khẩu',
                                    icon: Icon(
                                      obscure
                                          ? LucideIcons.eyeOff
                                          : LucideIcons.eye,
                                    ),
                                    onPressed: () =>
                                        setState(() => obscure = !obscure),
                                  ),
                                ),
                                validator: (v) => v == null || v.length < 6
                                    ? 'Mật khẩu cần ít nhất 6 ký tự'
                                    : null,
                              ),
                              if (register) ...[
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: phone,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Số điện thoại',
                                    prefixIcon: Icon(LucideIcons.phone),
                                  ),
                                  validator: (v) =>
                                      register &&
                                          !RegExp(
                                            r'^\d{9,11}$',
                                          ).hasMatch(v?.trim() ?? '')
                                      ? 'Số điện thoại cần 9–11 chữ số'
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: confirm,
                                  obscureText: obscure,
                                  decoration: const InputDecoration(
                                    labelText: 'Xác nhận mật khẩu',
                                    prefixIcon: Icon(LucideIcons.lockKeyhole),
                                  ),
                                  validator: (v) =>
                                      register && v != password.text
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
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                              ),
                              onPressed: busy
                                  ? null
                                  : () => openPage(
                                      context,
                                      ForgotPasswordScreen(state: widget.state),
                                    ),
                              child: const Text('Quên mật khẩu?'),
                            ),
                          ),
                        const SizedBox(height: 4),
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
                            padding: const EdgeInsets.only(top: 6),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(error!, style: PT.body(12, PT.error)),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Flexible(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  'Hoặc đăng nhập bằng',
                                  textAlign: TextAlign.center,
                                  style: PT.body(11, PT.muted),
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final social in [
                              ('Google', PhotoKind.google),
                              ('Apple', PhotoKind.apple),
                              ('Facebook', PhotoKind.facebook),
                            ])
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 8,
                                      ),
                                      side: const BorderSide(color: PT.line),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                    ),
                                    onPressed: () => message(
                                      context,
                                      'Đăng nhập ${social.$1} sẽ hoạt động khi nối dịch vụ xác thực.',
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: ReferencePhoto(
                                            kind: social.$2,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            social.$1,
                                            style: PT.body(11),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (showBanner)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: bannerHeight,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                const ReferencePhoto(),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        PT.deep.withValues(alpha: 0.72),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 12,
                                  right: 12,
                                  bottom: 10,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.shieldCheck,
                                        size: 16,
                                        color: Color(0xFFA7F3D0),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '1.200+ phòng xác thực • Hợp đồng điện tử an tâm',
                                          style: PT
                                              .body(11, Colors.white)
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          register ? 'Đã có tài khoản?' : 'Chưa có tài khoản?',
                          style: PT.body(12, PT.muted),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
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
                  ],
                ),
              ),
            ],
          );
        },
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
