import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app_state.dart';
import 'navigation.dart';
import '../core/async_resource.dart';
import '../core/theme.dart';
import '../core/tab_transition.dart';
import '../core/tab_navigation_bar.dart';
import '../domain/models.dart';
import '../features/auth/auth_screens.dart';
import '../features/rooms/room_screens.dart';
import '../features/chat/chat_screens.dart';
import '../features/account/account_screens.dart';
import '../features/rentals/rental_screens.dart';
import '../features/landlord/landlord_screens.dart';
import '../features/admin/admin_screens.dart';

class PhongTroXanhApp extends StatefulWidget {
  final AppState? state;
  final String? initialScreen;
  final bool demoPreview;
  const PhongTroXanhApp({
    super.key,
    this.state,
    this.initialScreen,
    this.demoPreview = const bool.fromEnvironment('PTX_DEMO_PREVIEW'),
  });
  @override
  State<PhongTroXanhApp> createState() => _PhongTroXanhAppState();
}

class _PhongTroXanhAppState extends State<PhongTroXanhApp> {
  late final AppState state = widget.state ?? AppState();
  late final String initial =
      widget.initialScreen ?? Uri.base.queryParameters['screen'] ?? 'welcome';
  late final ValueNotifier<String> mode = ValueNotifier(
    initial == 'welcome'
        ? 'welcome'
        : initial == 'login'
        ? 'login'
        : 'app',
  );
  final navigatorKey = GlobalKey<NavigatorState>();
  bool wasAuthenticated = false;
  @override
  void initState() {
    super.initState();
    if (widget.demoPreview && initial != 'welcome' && initial != 'login') {
      state.session.startDemo(
        initial == 'landlord'
            ? UserRole.landlord
            : initial == 'admin'
            ? UserRole.admin
            : UserRole.tenant,
      );
    }
    wasAuthenticated = state.authenticated;
    state.session.addListener(sessionChanged);
    state.loadRooms();
  }

  void sessionChanged() {
    if (wasAuthenticated && !state.authenticated) {
      mode.value = 'welcome';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          navigatorKey.currentState?.popUntil((route) => route.isFirst);
        }
      });
    }
    wasAuthenticated = state.authenticated;
  }

  void requestLogin(BuildContext context, VoidCallback onReady) {
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/login'),
        builder: (loginContext) => LoginScreen(
          state: state,
          onBack: () => Navigator.pop(loginContext),
          onSignedIn: () {
            mode.value = 'app';
            Navigator.pop(loginContext);
            if (state.authenticated) onReady();
          },
        ),
      ),
    );
  }

  String initialPath(String route) {
    if (kIsWeb && Uri.base.fragment.startsWith('/')) {
      return Uri.base.fragment;
    }
    return Uri.tryParse(route)?.path ?? '/';
  }

  Widget destination(AppDestination? route) {
    if (route == null) return const AccessNotice(result: AccessResult.missing);
    final target = route.target;
    Widget? page;
    if (target != null) {
      page = switch (target.kind) {
        ResourceKind.room =>
          state.roomById(target.id) == null
              ? null
              : RoomDetailScreen(
                  state: state,
                  room: state.roomById(target.id)!,
                ),
        ResourceKind.person =>
          state.personById(target.id) == null
              ? null
              : PersonDetailScreen(
                  state: state,
                  person: state.personById(target.id)!,
                ),
        ResourceKind.conversation =>
          state.conversationById(target.id) == null
              ? null
              : ChatScreen(
                  state: state,
                  conversation: state.conversationById(target.id)!,
                ),
        ResourceKind.rental =>
          state.rentalById(target.id) == null
              ? null
              : RentalsScreen(state: state, rentalId: target.id),
        _ => null,
      };
    } else {
      page = switch (route.path) {
        '/discover' => DiscoverScreen(state: state),
        '/profile' => ProfileScreen(state: state, onLogout: logout),
        '/saved' => SavedRoomsScreen(state: state),
        '/matches' => MatchesScreen(state: state),
        '/admin/rooms' => AdminRoomsScreen(state: state),
        '/packages' => PackagesScreen(state: state),
        '/payments' => PaymentHistoryScreen(state: state),
        '/reviews' => ReviewHistoryScreen(state: state),
        '/verification' => VerificationScreen(state: state),
        '/edit-profile' => EditProfileScreen(state: state),
        '/onboarding' => OnboardingScreen(
          state: state,
          onComplete: () => navigatorKey.currentState?.maybePop(),
        ),
        '/landlord/tenants' => LandlordTenantsScreen(state: state),
        '/landlord/swaps' => LandlordSwapsScreen(state: state),
        '/landlord/qr' => LandlordQRScreen(state: state),
        '/my-reports' => MyReportsScreen(state: state),
        '/check-in' => CheckInScreen(state: state),
        '/swap' => SwapScreen(state: state),
        '/notifications' => NotificationsScreen(state: state),
        '/landlord' => LandlordScreen(state: state),
        '/admin' => AdminScreen(state: state),
        '/admin/cccd' => AdminQueueScreen(state: state),
        '/admin/users' => AdminUsersScreen(),
        '/admin/reports' => AdminReportsScreen(),
        _ => null,
      };
    }
    final policy = page == null
        ? RoutePolicy(
            public:
                target?.kind == ResourceKind.room ||
                target?.kind == ResourceKind.person,
          )
        : RoutePolicy.forPage(page);
    return AccessGuard(
      state: state,
      policy: policy,
      target: target,
      child: page ?? const AccessNotice(result: AccessResult.missing),
    );
  }

  @override
  void dispose() {
    state.session.removeListener(sessionChanged);
    if (widget.state == null) {
      state.dispose();
    }
    mode.dispose();
    super.dispose();
  }

  void login() => mode.value = 'login';
  void explore() => mode.value = 'app';
  void logout() {
    state.logout();
    mode.value = 'welcome';
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  Widget home() {
    if (mode.value == 'welcome') {
      return WelcomeScreen(onExplore: explore, onLogin: login);
    }
    if (mode.value == 'login') {
      return LoginScreen(
        state: state,
        onSignedIn: explore,
        onBack: () => mode.value = 'welcome',
      );
    }
    return AppShell(
      key: const ValueKey('app-shell'),
      state: state,
      onLogout: logout,
      initialTab: switch (initial) {
        'roommate' => 1,
        'messages' => 3,
        'profile' => 4,
        'admin' => 4,
        _ => 0,
      },
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Phòng Trọ Xanh',
    navigatorKey: navigatorKey,
    onGenerateRoute: (settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => destination(
        settings.arguments is AppDestination
            ? settings.arguments as AppDestination
            : AppDestination.parse(settings.name ?? ''),
      ),
    ),
    debugShowCheckedModeBanner: false,
    theme: PT.theme,
    builder: (context, child) => ColoredBox(
      color: const Color(0xFFF2F6F4),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: LayoutBuilder(
            builder: (context, c) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(size: Size(math.min(c.maxWidth, 430), c.maxHeight)),
              child: AppScope(
                state: state,
                requestLogin: requestLogin,
                logout: logout,
                child: child!,
              ),
            ),
          ),
        ),
      ),
    ),
    onGenerateInitialRoutes: (initialRoute) => [
      MaterialPageRoute<void>(
        builder: (_) => ListenableBuilder(
          listenable: Listenable.merge([state, mode]),
          builder: (_, _) => home(),
        ),
      ),
      if (initialPath(initialRoute) != '/')
        MaterialPageRoute<void>(
          settings: RouteSettings(name: initialRoute),
          builder: (_) =>
              destination(AppDestination.parse(initialPath(initialRoute))),
        )
      else if (initial == 'detail')
        MaterialPageRoute<void>(
          builder: (_) => destination(AppDestination.room('r1')),
        ),
      if (initialPath(initialRoute) == '/' && initial == 'chat')
        MaterialPageRoute<void>(
          builder: (_) => destination(AppDestination.chat('c1')),
        ),
    ],
  );
}

class AppShell extends StatefulWidget {
  final AppState state;
  final VoidCallback onLogout;
  final int initialTab;
  const AppShell({
    super.key,
    required this.state,
    required this.onLogout,
    this.initialTab = 0,
  });
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int tab = widget.initialTab;
  bool _photosWarmed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_photosWarmed) return;
    _photosWarmed = true;
    // Warm the two reference sheets used by the next tabs without building
    // their screens or starting their data requests.
    for (final asset in ['roommate', 'messages']) {
      precacheImage(AssetImage('assets/references/$asset.png'), context);
    }
  }

  void selectTab(int next) {
    if (next == tab) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!kIsWeb) HapticFeedback.selectionClick();
    setState(() => tab = next);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final landlord = state.role == UserRole.landlord,
        admin = state.role == UserRole.admin;
    final navLabelLines =
        landlord ||
            MediaQuery.sizeOf(context).width < 360 ||
            MediaQuery.textScalerOf(context).scale(12) > 14
        ? 2
        : 1;
    final labels = landlord
        ? ['Tổng quan', 'Quản lý phòng', 'Tin nhắn', 'Đánh giá', 'Cá nhân']
        : [
            'Khám phá',
            'Bạn ở',
            'Nhận phòng',
            'Tin nhắn',
            admin ? 'Quản trị' : 'Cá nhân',
          ];
    final icons = landlord
        ? [
            LucideIcons.house,
            LucideIcons.clipboardList,
            LucideIcons.messageCircle,
            LucideIcons.star,
            LucideIcons.user,
          ]
        : [
            LucideIcons.search,
            LucideIcons.house,
            LucideIcons.circlePlus,
            LucideIcons.messageCircle,
            LucideIcons.user,
          ];
    final pages = landlord
        ? <Widget>[
            LandlordScreen(state: state),
            LandlordRoomsScreen(state: state, standalone: false),
            MessagesScreen(state: state),
            LandlordReviewsScreen(state: state),
            ProfileScreen(state: state, onLogout: widget.onLogout),
          ]
        : <Widget>[
            RoomFeedView(state: state),
            DiscoverScreen(state: state, person: true),
            AccessGuard(
              state: state,
              policy: const RoutePolicy(role: UserRole.tenant),
              child: CheckInScreen(state: state),
            ),
            AccessGuard(
              state: state,
              policy: const RoutePolicy(),
              child: MessagesScreen(state: state),
            ),
            admin
                ? AccessGuard(
                    state: state,
                    policy: const RoutePolicy(role: UserRole.admin),
                    child: AdminScreen(state: state),
                  )
                : AccessGuard(
                    state: state,
                    policy: const RoutePolicy(),
                    child: ProfileScreen(
                      state: state,
                      onLogout: widget.onLogout,
                    ),
                  ),
          ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: TabTransitionStack(
          key: ValueKey((state.userId, state.role)),
          index: tab,
          children: pages,
        ),
      ),
      bottomNavigationBar: TabNavigationBar(
        index: tab,
        labels: labels,
        icons: icons,
        labelLines: navLabelLines,
        unreadIndex: state.conversations.any((c) => c.unread > 0)
            ? (landlord ? 2 : 3)
            : null,
        onSelected: selectTab,
      ),
    );
  }
}

class RoomFeedView extends StatelessWidget {
  final AppState state;
  const RoomFeedView({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    final feed = state.roomController.feed;
    if (feed.phase == ResourcePhase.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (feed.phase == ResourcePhase.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: PT.green),
              const SizedBox(height: 16),
              Text(
                feed.error!.message,
                style: PT.body(16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: state.loadRooms,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    return DiscoverScreen(state: state);
  }
}
