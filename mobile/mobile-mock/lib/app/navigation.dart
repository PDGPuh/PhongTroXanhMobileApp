import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../demo/models.dart';
import 'app_state.dart';
import '../features/rooms/compare_screen.dart';
import '../features/auth/auth_screens.dart';
import '../features/rooms/room_screens.dart';
import '../features/account/account_screens.dart';
import '../features/rentals/rental_screens.dart';
import '../features/landlord/landlord_screens.dart';
import '../features/admin/admin_screens.dart';

enum AccessResult { allowed, loginRequired, denied, missing }

abstract interface class ResourceScreen {
  ResourceRef get resource;
}

class RoutePolicy {
  final bool public;
  final UserRole? role;
  const RoutePolicy({this.public = false, this.role});
  static RoutePolicy forPage(Widget page) {
    if (page is AdminScreen ||
        page is AdminQueueScreen ||
        page is AdminUsersScreen ||
        page is AdminReportsScreen ||
        page is AdminDecisionScreen ||
        page is AdminRoomsScreen) {
      return const RoutePolicy(role: UserRole.admin);
    }
    if (page is LandlordScreen ||
        page is LandlordRoomsScreen ||
        page is LandlordQRScreen ||
        page is LandlordSwapsScreen ||
        page is LandlordReviewsScreen ||
        page is ManageRoomScreen ||
        page is PostRoomScreen ||
        page is LandlordTenantsScreen) {
      return const RoutePolicy(role: UserRole.landlord);
    }
    if (page is CheckInScreen || page is SwapScreen || page is MatchesScreen) {
      return const RoutePolicy(role: UserRole.tenant);
    }
    if (page is WelcomeScreen ||
        page is LoginScreen ||
        page is ForgotPasswordScreen ||
        page is DiscoverScreen ||
        page is RoomDetailScreen ||
        page is PersonDetailScreen ||
        page is MapScreen ||
        page is CompareRoomsScreen ||
        page is HelpScreen) {
      return const RoutePolicy(public: true);
    }
    return const RoutePolicy();
  }

  AccessResult evaluate(AppState state, {ResourceRef? target}) {
    if (!public && !state.authenticated) return AccessResult.loginRequired;
    if (role != null && state.role != role) return AccessResult.denied;
    if (target != null) {
      if (!state.resourceExists(target)) return AccessResult.missing;
      if (target.kind == ResourceKind.room) {
        final room = state.roomById(target.id)!;
        if (role == UserRole.landlord && room.landlordId != state.userId) {
          return AccessResult.denied;
        }
        if ((room.status == RoomStatus.hidden ||
                room.status == RoomStatus.pending) &&
            room.landlordId != state.userId &&
            !(state.authenticated && state.role == UserRole.admin)) {
          return AccessResult.denied;
        }
      }
    }
    return AccessResult.allowed;
  }
}

/// Route arguments retain resource identity independently of widget instances.
class AppDestination {
  final String path;
  final ResourceRef? target;
  const AppDestination(this.path, {this.target});
  factory AppDestination.room(String id) =>
      AppDestination('/rooms/$id', target: ResourceRef(ResourceKind.room, id));
  factory AppDestination.person(String id) => AppDestination(
    '/roommates/$id',
    target: ResourceRef(ResourceKind.person, id),
  );
  factory AppDestination.chat(String id) => AppDestination(
    '/chat/$id',
    target: ResourceRef(ResourceKind.conversation, id),
  );
  factory AppDestination.rental(String id) => AppDestination(
    '/rentals/$id',
    target: ResourceRef(ResourceKind.rental, id),
  );
  static AppDestination? parse(String name) {
    final uri = Uri.tryParse(name);
    if (uri == null) return null;
    final p = uri.pathSegments;
    if (p.length == 2 && p[1].isNotEmpty) {
      return switch (p[0]) {
        'rooms' => AppDestination.room(p[1]),
        'roommates' => AppDestination.person(p[1]),
        'chat' => AppDestination.chat(p[1]),
        'rentals' => AppDestination.rental(p[1]),
        _ => null,
      };
    }
    return const {
          '/discover',
          '/profile',
          '/saved',
          '/matches',
          '/check-in',
          '/swap',
          '/notifications',
          '/landlord',
          '/admin',
          '/admin/cccd',
          '/admin/users',
          '/admin/reports',
          '/admin/rooms',
          '/packages',
          '/payments',
          '/reviews',
          '/verification',
          '/edit-profile',
          '/onboarding',
          '/landlord/tenants',
          '/landlord/swaps',
          '/landlord/qr',
          '/my-reports',
        }.contains(uri.path)
        ? AppDestination(uri.path)
        : null;
  }
}

class AppScope extends InheritedNotifier<AppState> {
  final void Function(BuildContext context, VoidCallback onReady) requestLogin;
  final VoidCallback logout;
  const AppScope({
    super.key,
    required AppState state,
    required this.requestLogin,
    required this.logout,
    required super.child,
  }) : super(notifier: state);
  AppState get state => notifier!;
  static AppScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>();
}

void withSession(BuildContext context, VoidCallback action) {
  final scope = AppScope.maybeOf(context);
  if (scope == null || scope.state.authenticated) {
    action();
  } else {
    scope.requestLogin(context, () {
      if (context.mounted) action();
    });
  }
}

class AccessGuard extends StatelessWidget {
  final AppState state;
  final Widget child;
  final RoutePolicy policy;
  final ResourceRef? target;
  const AccessGuard({
    super.key,
    required this.state,
    required this.child,
    required this.policy,
    this.target,
  });
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final result = policy.evaluate(state, target: target);
      if (result == AccessResult.allowed) return child;
      return AccessNotice(
        result: result,
        onLogin: result == AccessResult.loginRequired
            ? () => AppScope.maybeOf(context)?.requestLogin(context, () {})
            : null,
      );
    },
  );
}

class AccessNotice extends StatelessWidget {
  final AccessResult result;
  final VoidCallback? onLogin;
  const AccessNotice({super.key, required this.result, this.onLogin});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        result == AccessResult.missing ? 'Không tìm thấy' : 'Tài khoản',
      ),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              result == AccessResult.missing
                  ? Icons.search_off
                  : Icons.lock_outline,
              size: 56,
              color: PT.green,
            ),
            const SizedBox(height: 20),
            Text(
              switch (result) {
                AccessResult.loginRequired => 'Đăng nhập để tiếp tục',
                AccessResult.denied => 'Bạn không có quyền truy cập',
                _ => 'Nội dung không còn tồn tại',
              },
              style: PT.title(24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              result == AccessResult.loginRequired
                  ? 'Thông tin và thao tác này thuộc tài khoản của bạn.'
                  : 'Quay lại để chọn nội dung khác.',
              style: PT.body(14, PT.muted),
              textAlign: TextAlign.center,
            ),
            if (onLogin != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: FilledButton(
                  onPressed: onLogin,
                  child: const Text('Đăng nhập'),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
