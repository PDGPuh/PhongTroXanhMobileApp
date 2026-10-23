import 'welcome_carousel.dart';
import '../account/account_workflows.dart';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_state.dart';
import '../../api/http_auth_repository.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../core/reference_photo.dart';
import 'google_auth_bridge.dart';
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
    backgroundColor: const Color(0xFFF5F9F7),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final carouselHeight = (constraints.maxHeight - 455).clamp(
            180.0,
            340.0,
          );
          return ListView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            children: [
              // Top Brand + Pill Skip Button
              Row(
                children: [
                  const Expanded(child: Brand(compact: true)),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: onExplore,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: PT.line.withValues(alpha: 0.85),
                          ),
                        ),
                        child: Text(
                          'Bỏ qua',
                          style: PT
                              .body(12.5, PT.deep)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Hero Carousel
              WelcomeCarousel(height: carouselHeight),
              const SizedBox(height: 12),

              // Cohesive Onboarding Value & Action Card
              Container(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: PT.line.withValues(alpha: 0.85)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C073B3C),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ở đúng người. Ở đúng nơi.',
                      style: PT.title(24).copyWith(height: 1.2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tìm phòng trọ xác thực và ghép bạn ở cùng lối sống.',
                      style: PT.body(13, PT.muted),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F9F6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: PT.line.withValues(alpha: 0.75),
                        ),
                      ),
                      child: const IntrinsicHeight(
                        child: Row(
                          children: [
                            _Feature(LucideIcons.house, 'Phòng xác thực'),
                            VerticalDivider(
                              width: 10,
                              thickness: 1,
                              indent: 4,
                              endIndent: 4,
                              color: PT.line,
                            ),
                            _Feature(LucideIcons.users, 'Ghép hợp gu'),
                            VerticalDivider(
                              width: 10,
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
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 4,
                      children: [
                        const Icon(
                          LucideIcons.shieldCheck,
                          color: PT.green,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '1.200+ phòng xác thực',
                          style: PT.body(12, PT.muted).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          child: Text('•', style: PT.body(12, PT.line)),
                        ),
                        const Icon(
                          LucideIcons.star,
                          color: PT.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '4.8/5 đánh giá',
                          style: PT.body(12, PT.muted).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: PT.mint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: PT.green),
        ),
        const SizedBox(height: 6),
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
    backgroundColor: const Color(0xFFF5F9F7),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final showBanner =
              !register &&
              constraints.maxHeight >= 640 &&
              textScale <= 1.25 &&
              MediaQuery.viewInsetsOf(context).bottom == 0 &&
              error == null;
          final bannerHeight = (constraints.maxHeight - 620).clamp(118.0, 172.0);
          return ListView(
            physics: const ClampingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            children: [
              // Top Navigation Bar
              Row(
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: widget.onBack,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: PT.line.withValues(alpha: 0.85),
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.arrowLeft,
                          size: 18,
                          color: PT.deep,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Brand(compact: true)),
                  if (constraints.maxWidth >= 350 && textScale <= 1.3)
                    const Pill(
                      'Bảo mật eKYC',
                      dense: true,
                      color: PT.green,
                      bg: PT.mint,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Hero Banner at Top (Clean Proptech visual context instead of floating at bottom)
              if (showBanner) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
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
                                PT.deep.withValues(alpha: 0.12),
                                PT.deep.withValues(alpha: 0.78),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 12,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                  LucideIcons.shieldCheck,
                                  size: 16,
                                  color: Color(0xFFA7F3D0),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '1.200+ phòng xác thực • Hợp đồng điện tử an tâm',
                                  style: PT
                                      .body(12, Colors.white)
                                      .copyWith(fontWeight: FontWeight.w600),
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
                const SizedBox(height: 16),
              ],

              // Main Elevated Auth Card
              Container(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: PT.line.withValues(alpha: 0.85)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C073B3C),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      register ? 'Đăng ký' : 'Đăng nhập',
                      style: PT.title(24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      register
                          ? 'Bắt đầu hành trình tìm nơi ở phù hợp.'
                          : 'Chào mừng bạn quay trở lại Phòng Trọ Xanh!',
                      style: PT.body(13, PT.muted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),

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
                            const SizedBox(height: 14),
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
                          const SizedBox(height: 14),
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
                            const SizedBox(height: 14),
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
                            const SizedBox(height: 14),
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
                    if (!register) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
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
                    ],
                    const SizedBox(height: 10),
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
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: PT.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: PT.error.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              error!,
                              style: PT.body(12.5, PT.error).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: PT.line)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Hoặc đăng nhập bằng',
                            textAlign: TextAlign.center,
                            style: PT.body(12, PT.muted),
                          ),
                        ),
                        const Expanded(child: Divider(color: PT.line)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFF8FBF9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          side: const BorderSide(color: PT.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: busy ? null : _handleGoogleSignIn,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: ReferencePhoto(
                                kind: PhotoKind.google,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Đăng nhập bằng Google',
                              style: PT.body(13.5, PT.deep).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Footer Switch Mode (Natural spacing right below the card)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PT.line.withValues(alpha: 0.75)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      register ? 'Đã có tài khoản?' : 'Chưa có tài khoản?',
                      style: PT.body(13, PT.muted),
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
                      child: Text(
                        register ? 'Đăng nhập' : 'Đăng ký',
                        style: PT.body(13, PT.green).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      busy = true;
      error = null;
    });

    final repo = widget.state.session.repository;
    String clientId = '26308985257-c3tkae8c2jjtgs1biimctm2ga0h70fc0.apps.googleusercontent.com';
    if (repo is HttpAuthRepository) {
      final fetched = await repo.getGoogleClientId();
      if (fetched != null && fetched.isNotEmpty) {
        clientId = fetched;
      }
    }

    try {
      final idToken = await requestGoogleIdToken(clientId);
      if (idToken != null && idToken.isNotEmpty) {
        final ok = await widget.state.authenticateWithGoogle(idToken, role: 'TENANT');
        if (!mounted) return;
        setState(() {
          busy = false;
          error = widget.state.session.error;
        });
        if (ok) {
          widget.onSignedIn();
        }
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = e.toString();
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      busy = false;
    });
  }
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
