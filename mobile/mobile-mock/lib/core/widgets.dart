import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'theme.dart';
import 'device_media.dart';
import 'reference_photo.dart';
import '../app/navigation.dart';
import '../demo/models.dart';

void openPage(BuildContext context, Widget page, {ResourceRef? target}) {
  target ??= page is ResourceScreen ? (page as ResourceScreen).resource : null;
  final scope = AppScope.maybeOf(context);
  final policy = RoutePolicy.forPage(page);
  void push() {
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(
          name: page.runtimeType.toString(),
          arguments: target,
        ),
        builder: (_) => scope == null
            ? page
            : AccessGuard(
                state: scope.state,
                policy: policy,
                target: target,
                child: page,
              ),
      ),
    );
  }

  if (scope != null &&
      policy.evaluate(scope.state, target: target) ==
          AccessResult.loginRequired) {
    scope.requestLogin(context, push);
  } else {
    push();
  }
}

void message(BuildContext context, String text, {double bottomInset = 0}) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        margin: bottomInset > 0
            ? EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset)
            : null,
      ),
    );

class Brand extends StatelessWidget {
  final bool compact, small;
  const Brand({super.key, this.compact = false, this.small = false});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(
        width: 38,
        height: 42,
        child: ReferencePhoto(kind: PhotoKind.logo),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phòng Trọ Xanh',
              style: PT.brand(small ? 16 : (compact ? 18 : 22)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Không chỉ là nơi ở, mà là nhà',
              style: PT.caption(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  );
}

class RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String label;
  final Color color, background;
  final bool dot;
  final double size;
  const RoundButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.color = PT.deep,
    this.background = PT.grey,
    this.dot = false,
    this.size = 40,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    enabled: onTap != null,
    child: Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size < 48 ? 48 : size,
            height: size < 48 ? 48 : size,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: background,
                      shape: BoxShape.circle,
                      border: Border.all(color: PT.line.withValues(alpha: .8)),
                    ),
                    child: Icon(
                      icon == LucideIcons.heart && size > 55
                          ? Icons.favorite_rounded
                          : icon,
                      size: size > 55 ? 28 : 22,
                      color: onTap == null ? PT.muted : color,
                    ),
                  ),
                  if (dot)
                    Positioned(
                      right: 2,
                      top: 1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: PT.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class Header extends StatelessWidget {
  final VoidCallback onMap, onNotifications;
  final VoidCallback? onProfile;
  final bool admin, owner;
  final int unreadNotifications;
  const Header({
    super.key,
    required this.onMap,
    required this.onNotifications,
    this.onProfile,
    this.admin = false,
    this.owner = false,
    this.unreadNotifications = 0,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 14),
    child: Row(
      children: [
        Expanded(child: Brand(compact: true, small: owner)),
        if (!admin)
          RoundButton(icon: LucideIcons.map, label: 'Bản đồ', onTap: onMap),
        RoundButton(
          icon: LucideIcons.bell,
          label: unreadNotifications > 0
              ? 'Thông báo, $unreadNotifications chưa đọc'
              : 'Thông báo',
          dot: unreadNotifications > 0,
          onTap: onNotifications,
        ),
        if (admin) Pill('AD', dropdown: true, onTap: onMap),
        if (owner)
          GestureDetector(
            onTap: onProfile,
            child: const AvatarPhoto(size: 38, online: true),
          ),
      ],
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool outline;
  final bool busy;
  const PrimaryButton(
    this.label, {
    super.key,
    this.onTap,
    this.icon,
    this.outline = false,
    this.busy = false,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Semantics(
      button: true,
      enabled: onTap != null && !busy,
      child: Material(
        color: outline ? Colors.white : (onTap == null ? PT.line : PT.green),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: PT.green, width: outline ? 1 : 0),
        ),
        child: InkWell(
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PT.deep,
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else if (icon != null) ...[
                  Icon(
                    icon,
                    size: 23,
                    color: outline ? PT.green : Colors.white,
                  ),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: PT
                        .body(16, outline ? PT.green : Colors.white)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class Pill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool dropdown, dense;
  final Color color, bg;
  const Pill(
    this.label, {
    super.key,
    this.icon,
    this.onTap,
    this.dropdown = false,
    this.dense = false,
    this.color = PT.deep,
    this.bg = PT.mint,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: bg,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
      side: BorderSide(color: dropdown ? PT.line : Colors.transparent),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: onTap == null ? 0 : 48),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 7 : (dropdown ? 10 : 11),
            vertical: dense ? (icon == null ? 3 : 6) : (dropdown ? 7 : 8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon == LucideIcons.heart ? Icons.favorite_rounded : icon,
                  size: dense ? 14 : 17,
                  color: color,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: PT.body(dense ? (icon == null ? 11 : 10) : 12, color),
                ),
              ),
              if (dropdown) ...[
                const SizedBox(width: 5),
                Icon(LucideIcons.chevronDown, size: 14, color: color),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class AvatarPhoto extends StatelessWidget {
  final LocalPhoto? photo;
  final PhotoKind kind;
  final double size;
  final bool online;
  const AvatarPhoto({
    super.key,
    this.kind = PhotoKind.man,
    this.size = 52,
    this.online = false,
    this.photo,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ClipOval(
            child: photo == null
                ? ReferencePhoto(kind: kind)
                : LocalPhotoView(photo: photo!),
          ),
        ),
        if (online)
          Positioned(
            right: 0,
            bottom: 1,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: PT.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    ),
  );
}

class MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool spacious, framed;
  const MenuRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.spacious = false,
    this.framed = true,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.only(bottom: spacious ? 12 : 5),
    decoration: framed ? PT.card() : null,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: spacious
              ? EdgeInsets.symmetric(horizontal: framed ? 16 : 0, vertical: 14)
              : const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: PT.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: PT.deep, size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: PT.title(17)),
                    if (subtitle != null && spacious) const SizedBox(height: 5),
                    if (subtitle != null)
                      Text(subtitle!, style: PT.body(13, PT.muted)),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  final String title, subtitle;
  const PageHeading(this.title, this.subtitle, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: PT.title(28)),
        const SizedBox(height: 8),
        Text(subtitle, style: PT.body(15, PT.muted)),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final String title, description;
  final IconData icon;
  final Widget? action;
  const EmptyState(
    this.title,
    this.description, {
    super.key,
    this.icon = LucideIcons.search,
    this.action,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 20),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: PT.mint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 35, color: PT.green),
        ),
        const SizedBox(height: 18),
        Text(title, style: PT.title(22), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          description,
          style: PT.body(14, PT.muted),
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

class BasicPage extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? bottom;
  final VoidCallback? onBack;
  final bool customBack;
  const BasicPage({
    super.key,
    required this.title,
    required this.child,
    this.bottom,
    this.onBack,
    this.customBack = false,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title, style: PT.title(21)),
      leading: IconButton(
        tooltip: 'Quay lại',
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: customBack
            ? onBack
            : onBack ?? () => Navigator.maybePop(context),
      ),
    ),
    body: SafeArea(top: false, child: child),
    bottomNavigationBar: bottom == null
        ? null
        : SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: bottom,
            ),
          ),
  );
}

IconData amenityIcon(String label) => switch (label) {
  'Wifi riêng' => LucideIcons.wifi,
  'Máy lạnh' => LucideIcons.snowflake,
  'Bếp riêng' || 'Nấu ăn' => LucideIcons.utensils,
  'Đọc sách' => LucideIcons.bookOpen,
  'Du lịch' => LucideIcons.plane,
  _ => LucideIcons.armchair,
};
