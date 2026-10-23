import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'theme.dart';
import 'device_media.dart';
import 'reference_photo.dart';
import '../app/navigation.dart';
import '../domain/models.dart';

void openPage(BuildContext context, Widget page, {ResourceRef? target}) {
  final scope = AppScope.maybeOf(context);
  try {
    final dynamic p = page;
    if (p.room != null) scope?.state.cacheRoom(p.room);
  } catch (_) {}
  try {
    final dynamic p = page;
    if (p.person != null) scope?.state.cachePerson(p.person);
  } catch (_) {}
  target ??= page is ResourceScreen ? (page as ResourceScreen).resource : null;
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
      SizedBox(
        width: small ? 28 : 32,
        height: small ? 30 : 34,
        child: const ReferencePhoto(kind: PhotoKind.logo),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Phòng Trọ Xanh',
              style: PT.brand(small ? 15 : (compact ? 18 : 19)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!compact && !small)
              Text(
                'Không chỉ là nơi ở, mà là nhà',
                style: PT.caption(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    ],
  );
}

class _TapScale extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double pressedScale;
  const _TapScale({
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.93,
  });
  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (!widget.enabled || reduced) return widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        if (!_pressed) setState(() => _pressed = true);
      },
      onPointerUp: (_) {
        if (_pressed) setState(() => _pressed = false);
      },
      onPointerCancel: (_) {
        if (_pressed) setState(() => _pressed = false);
      },
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: Duration(milliseconds: _pressed ? 90 : 180),
        curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
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
    this.size = 36,
  });
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final resolvedIcon = icon == LucideIcons.heart && size >= 50
        ? Icons.favorite_rounded
        : icon;
    final iconSize = size >= 56
        ? 26.0
        : (size >= 46 ? 21.0 : (size <= 32 ? 17.0 : 19.0));
    return Semantics(
      button: true,
      label: label,
      enabled: onTap != null,
      child: Tooltip(
        message: label,
        child: _TapScale(
          enabled: onTap != null,
          pressedScale: size >= 46 ? 0.90 : 0.93,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: size < 44 ? 44 : size,
                height: size < 44 ? 44 : size,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: reduced
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: background,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: size >= 46
                                ? color.withValues(alpha: .22)
                                : PT.line.withValues(alpha: .85),
                            width: size >= 46 ? 1.4 : 1,
                          ),
                          boxShadow: size >= 44
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: .12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: AnimatedSwitcher(
                          duration: reduced
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            resolvedIcon,
                            key: ValueKey(resolvedIcon),
                            size: iconSize,
                            color: onTap == null ? PT.muted : color,
                          ),
                        ),
                      ),
                      if (dot)
                        Positioned(
                          right: 1,
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
      ),
    );
  }
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
    padding: const EdgeInsets.only(top: 2, bottom: 4),
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
        if (admin) Pill('AD', dropdown: true, dense: true, onTap: onMap),
        if (owner)
          GestureDetector(
            onTap: onProfile,
            child: const AvatarPhoto(size: 34, online: true),
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
      child: _TapScale(
        enabled: onTap != null && !busy,
        pressedScale: 0.97,
        child: Material(
          color: outline ? Colors.white : (onTap == null ? PT.line : PT.green),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: PT.green, width: outline ? 1.2 : 0),
          ),
          child: InkWell(
            onTap: busy ? null : onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12.5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: PT.deep,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else if (icon != null) ...[
                    Icon(
                      icon,
                      size: 19,
                      color: outline ? PT.green : Colors.white,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: PT
                          .body(14.5, outline ? PT.green : Colors.white)
                          .copyWith(fontWeight: FontWeight.w700),
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
  Widget build(BuildContext context) => _TapScale(
    enabled: onTap != null,
    pressedScale: 0.95,
    child: Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: dropdown ? PT.line : Colors.transparent),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: onTap == null ? 0 : (dense ? 32 : 36),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 8.5 : (dropdown ? 11 : 10.5),
              vertical: dense
                  ? (icon == null ? 3.5 : 4.5)
                  : (dropdown ? 6.5 : 6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon == LucideIcons.heart ? Icons.favorite_rounded : icon,
                    size: dense ? 13.5 : 15,
                    color: color,
                  ),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: PT
                        .body(dense ? 11.5 : 12.5, color)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (dropdown) ...[
                  const SizedBox(width: 4),
                  Icon(LucideIcons.chevronDown, size: 13.5, color: color),
                ],
              ],
            ),
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
  final String? name;
  final String? imageUrl;

  const AvatarPhoto({
    super.key,
    this.kind = PhotoKind.man,
    this.size = 52,
    this.online = false,
    this.photo,
    this.name,
    this.imageUrl,
  });

  static const List<Color> _avatarColors = [
    Color(0xFF0F766E), // Teal
    Color(0xFF1E40AF), // Blue
    Color(0xFF6D28D9), // Purple
    Color(0xFFBE185D), // Pink
    Color(0xFFC2410C), // Orange
    Color(0xFF047857), // Green
    Color(0xFF4338CA), // Indigo
    Color(0xFF0369A1), // Sky
  ];

  Color _nameColor(String text) {
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return _avatarColors[hash.abs() % _avatarColors.length];
  }

  String _initial(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return '?';
    final parts =
        clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _buildContent() {
    if (photo != null) {
      return LocalPhotoView(photo: photo!);
    }
    if (imageUrl != null &&
        imageUrl!.trim().isNotEmpty &&
        (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'))) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    if (name != null && name!.trim().isNotEmpty) {
      final color = _nameColor(name!);
      return Container(
        color: color,
        alignment: Alignment.center,
        child: Text(
          _initial(name!),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.40,
            letterSpacing: -0.5,
          ),
        ),
      );
    }
    return ReferencePhoto(kind: kind);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ClipOval(
            child: _buildContent(),
          ),
        ),
        if (online)
          Positioned(
            right: 0,
            bottom: 1,
            child: Container(
              width: (size * 0.28).clamp(8.0, 14.0),
              height: (size * 0.28).clamp(8.0, 14.0),
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
    margin: EdgeInsets.only(bottom: spacious ? 6 : 4),
    decoration: framed ? PT.card() : null,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: spacious
              ? EdgeInsets.symmetric(horizontal: framed ? 12 : 0, vertical: 9)
              : const EdgeInsets.all(6),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: PT.mint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: PT.deep, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: PT.title(15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && spacious) const SizedBox(height: 2),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: PT.body(12, PT.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 18),
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
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: PT.title(21),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: PT.body(12, PT.muted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: PT.mint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: PT.green),
        ),
        const SizedBox(height: 12),
        Text(title, style: PT.title(18), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          description,
          style: PT.body(13, PT.muted),
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[const SizedBox(height: 14), action!],
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
      title: Text(title, style: PT.title(18)),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
