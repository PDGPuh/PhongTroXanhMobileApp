import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../core/theme.dart';
import '../../core/swipe_card.dart';
import '../../core/tab_transition.dart';
import '../../core/widgets.dart';
import '../../core/reference_photo.dart';
import '../../domain/models.dart';
import '../chat/chat_screens.dart';
import '../account/account_screens.dart';
import 'room_filters.dart';
import 'directions_button.dart';
import 'room_gallery.dart';
import 'compare_screen.dart';

double _feedPhotoAspectRatio(BuildContext context) =>
    MediaQuery.sizeOf(context).height < 860 ? 2.2 : 1.9;

class DiscoverScreen extends StatefulWidget {
  final AppState state;
  final bool person;
  const DiscoverScreen({super.key, required this.state, this.person = false});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _deck = GlobalKey<SwipeCardState>();
  final _actions = GlobalKey();
  bool _busy = false;
  AppState get state => widget.state;
  bool get person => widget.person;

  String _millions(double amount) => (amount / 1e6)
      .toStringAsFixed(6)
      .replaceFirst(RegExp(r'\.?0+$'), '')
      .replaceAll('.', ',');

  String get _budgetLabel {
    final minimum = person ? 0.0 : state.roomController.minPrice;
    final maximum = person ? state.personBudget : state.maxPrice;
    return minimum == 0
        ? 'Đến ${_millions(maximum)} triệu'
        : '${_millions(minimum)} – ${_millions(maximum)} triệu';
  }

  Object get _identity => (
    state,
    state.userId,
    state.workflows.epoch,
    person,
    person ? state.personIndex : state.roomIndex,
    person
        ? state.filteredPeople.map((p) => p.id).join(',')
        : state.filteredRooms.map((r) => r.id).join(','),
  );

  void _requestSwipe(bool like) {
    if (_busy) return;
    withSession(context, () => _animateSwipe(like));
  }

  Future<void> _animateSwipe(bool like) async {
    if (!mounted ||
        _busy ||
        !TabActivity.isActiveOf(context) ||
        !state.authenticated ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    final quota = person ? state.roommateQuota : state.roomQuota;
    final index = person ? state.personIndex : state.roomIndex;
    final rooms = state.filteredRooms;
    final people = state.filteredPeople;
    if ((!state.unlimitedSwipes && quota <= 0) ||
        index >= (person ? people.length : rooms.length)) {
      return;
    }
    final identity = _identity;
    final room = person ? null : rooms[index];
    final candidate = person ? people[index] : null;
    final deck = _deck.currentState;
    if (deck == null) return;
    setState(() => _busy = true);
    try {
      final completed = await deck.swipe(like);
      if (!mounted ||
          !completed ||
          !TabActivity.isActiveOf(context) ||
          identity != _identity ||
          !(ModalRoute.of(context)?.isCurrent ?? true)) {
        deck.reset();
        return;
      }
      if (!state.swipe(person: person, like: like)) {
        deck.reset();
        return;
      }
      if (like && person) {
        showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text('Đã gửi lời thích!', style: PT.title(24)),
            content: Text(
              'Bạn đã thích ${candidate!.name}. Bạn sẽ được thông báo khi cả hai cùng thích nhau.',
              style: PT.body(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Tiếp tục khám phá'),
              ),
            ],
          ),
        );
      } else if (like) {
        final footer =
            _actions.currentContext?.findRenderObject() as RenderBox?;
        message(
          context,
          'Đã lưu ${room!.title}',
          bottomInset: footer?.size.height ?? 0,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = state.filteredRooms;
    final people = state.filteredPeople;
    final index = person ? state.personIndex : state.roomIndex;
    final count = person ? people.length : rooms.length;
    final quota = person ? state.roommateQuota : state.roomQuota;
    final workspace = state.authenticated
        ? state.store.workspace(state.session.user!)
        : null;
    final allowance = person
        ? (workspace?.roommateAllowance ?? 10)
        : (workspace?.roomAllowance ?? 15);
    final room = !person && index < rooms.length ? rooms[index] : null;
    final candidate = person && index < people.length ? people[index] : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final lockViewport = constraints.maxHeight >= 520 && textScale <= 1.25;
        final photoHeight = (constraints.maxHeight - (person ? 368 : 362))
            .clamp(120.0, 395.0);
        final hasDeckActions =
            (state.unlimitedSwipes || quota > 0) && index < count;
        final listMinHeight = lockViewport
            ? math.max(
                0.0,
                constraints.maxHeight - (hasDeckActions ? 74.0 : 12.0),
              )
            : 0.0;

        return Column(
          children: [
            Expanded(
              child: ListView(
                key: PageStorageKey(person ? 'roommates' : 'discover'),
                physics: lockViewport
                    ? const NeverScrollableScrollPhysics()
                    : const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: listMinHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Header(
                              unreadNotifications: state.unreadNotifications,
                              onMap: () =>
                                  openPage(context, MapScreen(state: state)),
                              onNotifications: () => openPage(
                                context,
                                NotificationsScreen(state: state),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        Pill(
                                          person
                                              ? _budgetLabel
                                              : state.district,
                                          icon: person
                                              ? LucideIcons.wallet
                                              : LucideIcons.mapPin,
                                          dropdown: true,
                                          dense: true,
                                          bg: Colors.white,
                                          onTap: () => showRoomFilters(
                                            context,
                                            state,
                                            person: person,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Pill(
                                          person
                                              ? (state.personDistrict ==
                                                        'Quận 10'
                                                    ? 'Gần Bách Khoa'
                                                    : state.personDistrict)
                                              : _budgetLabel,
                                          icon: person
                                              ? LucideIcons.graduationCap
                                              : LucideIcons.wallet,
                                          dropdown: true,
                                          dense: true,
                                          bg: Colors.white,
                                          onTap: () => showRoomFilters(
                                            context,
                                            state,
                                            person: person,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Pill(
                                          person ? state.gender : state.type,
                                          icon: person
                                              ? LucideIcons.users
                                              : LucideIcons.house,
                                          dropdown: true,
                                          dense: true,
                                          bg: Colors.white,
                                          onTap: () => showRoomFilters(
                                            context,
                                            state,
                                            person: person,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                RoundButton(
                                  icon: LucideIcons.slidersHorizontal,
                                  label: 'Bộ lọc',
                                  size: 34,
                                  background: Colors.white,
                                  onTap: () => showRoomFilters(
                                    context,
                                    state,
                                    person: person,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Material(
                                    color: const Color(0xFFF1F8F5),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () =>
                                          openPage(context, PackagesScreen()),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 11,
                                          vertical: 7,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              state.unlimitedSwipes
                                                              ? ''
                                                              : 'Còn ',
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              state.unlimitedSwipes
                                                              ? 'Không giới hạn'
                                                              : '$quota/$allowance',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                        TextSpan(
                                                          text: person
                                                              ? ' lượt ghép hôm nay'
                                                              : ' lượt vuốt hôm nay',
                                                        ),
                                                      ],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: PT.body(
                                                      11.5,
                                                      PT.deep,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3.5),
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    child:
                                                        TweenAnimationBuilder<
                                                          double
                                                        >(
                                                          tween: Tween<double>(
                                                            end:
                                                                state
                                                                    .unlimitedSwipes
                                                                ? 1.0
                                                                : (quota /
                                                                          allowance)
                                                                      .clamp(
                                                                        0.0,
                                                                        1.0,
                                                                      ),
                                                          ),
                                                          duration:
                                                              MediaQuery.disableAnimationsOf(
                                                                context,
                                                              )
                                                              ? Duration.zero
                                                              : const Duration(
                                                                  milliseconds:
                                                                      280,
                                                                ),
                                                          curve: Curves
                                                              .easeOutCubic,
                                                          builder:
                                                              (
                                                                context,
                                                                val,
                                                                _,
                                                              ) =>
                                                                  LinearProgressIndicator(
                                                                    value: val,
                                                                    minHeight:
                                                                        3,
                                                                    backgroundColor:
                                                                        PT.sage,
                                                                    color: PT
                                                                        .green,
                                                                  ),
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const ExcludeSemantics(
                                              child: Icon(
                                                LucideIcons.chevronRight,
                                                size: 14,
                                                color: PT.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (!person && textScale <= 1.25) ...[
                                  const SizedBox(width: 6),
                                  Pill(
                                    'Đã lưu',
                                    icon: LucideIcons.bookmark,
                                    dense: true,
                                    bg: Colors.white,
                                    onTap: () => openPage(
                                      context,
                                      SavedRoomsScreen(state: state),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Pill(
                                    'So sánh',
                                    icon: LucideIcons.columns2,
                                    dense: true,
                                    bg: Colors.white,
                                    onTap: () => openPage(
                                      context,
                                      CompareRoomsScreen(state: state),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (!person && textScale > 1.25) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Pill(
                                    'Đã lưu',
                                    icon: LucideIcons.bookmark,
                                    dense: true,
                                    bg: Colors.white,
                                    onTap: () => openPage(
                                      context,
                                      SavedRoomsScreen(state: state),
                                    ),
                                  ),
                                  Pill(
                                    'So sánh',
                                    icon: LucideIcons.columns2,
                                    dense: true,
                                    bg: Colors.white,
                                    onTap: () => openPage(
                                      context,
                                      CompareRoomsScreen(state: state),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (quota <= 0 && !state.unlimitedSwipes)
                          EmptyState(
                            'Hết lượt hôm nay',
                            'Bạn có thể quay lại ngày mai hoặc xem các gói bổ sung.',
                            action: PrimaryButton(
                              'Xem gói dịch vụ',
                              onTap: () => openPage(context, PackagesScreen()),
                            ),
                          )
                        else if (index >= count)
                          EmptyState(
                            count == 0
                                ? 'Không có kết quả phù hợp'
                                : 'Đã xem hết gợi ý',
                            count == 0
                                ? 'Thử mở rộng ngân sách hoặc thay đổi tiện ích, khu vực.'
                                : 'Thay đổi bộ lọc hoặc xem lại các gợi ý đã bỏ qua.',
                            action: PrimaryButton(
                              count == 0 ? 'Thay đổi bộ lọc' : 'Xem lại gợi ý',
                              onTap: count == 0
                                  ? () => showRoomFilters(
                                      context,
                                      state,
                                      person: person,
                                    )
                                  : () => state.resetDeck(person),
                            ),
                          )
                        else
                          SwipeCard(
                            key: _deck,
                            identity: _identity,
                            positiveLabel: person ? 'THÍCH' : 'LƯU',
                            onSwipeRequested: _requestSwipe,
                            next: index + 1 >= count
                                ? null
                                : person
                                ? PersonCard(
                                    person: people[index + 1],
                                    photoHeight: photoHeight,
                                    onInfo: () {},
                                    onLike: () {},
                                  )
                                : RoomCard(
                                    room: rooms[index + 1],
                                    saved: state.isSaved(rooms[index + 1].id),
                                    photoHeight: photoHeight,
                                    onInfo: () {},
                                    onSave: () {},
                                  ),
                            child: person
                                ? PersonCard(
                                    person: candidate!,
                                    photoHeight: photoHeight,
                                    onInfo: () => openPage(
                                      context,
                                      PersonDetailScreen(
                                        state: state,
                                        person: candidate,
                                      ),
                                    ),
                                    onLike: () => _requestSwipe(true),
                                  )
                                : RoomCard(
                                    room: room!,
                                    saved: state.isSaved(room.id),
                                    photoHeight: photoHeight,
                                    onSave: () => withSession(
                                      context,
                                      () => state.toggleSave(room.id),
                                    ),
                                    onInfo: () => openPage(
                                      context,
                                      RoomDetailScreen(
                                        state: state,
                                        room: room,
                                      ),
                                    ),
                                  ),
                          ),
                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (hasDeckActions)
              Padding(
                key: _actions,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    RoundButton(
                      icon: LucideIcons.undo2,
                      label: 'Hoàn tác',
                      size: 44,
                      color: PT.amber,
                      background: Colors.white,
                      onTap: _busy
                          ? null
                          : () =>
                                withSession(context, () => state.undo(person)),
                    ),
                    RoundButton(
                      icon: LucideIcons.x,
                      label: 'Bỏ qua',
                      size: 52,
                      color: PT.red,
                      background: Colors.white,
                      onTap: _busy ? null : () => _requestSwipe(false),
                    ),
                    RoundButton(
                      icon: LucideIcons.heart,
                      label: person ? 'Thích bạn ở' : 'Lưu phòng',
                      size: 56,
                      color: PT.green,
                      background: const Color(0xFFECFDF5),
                      onTap: _busy ? null : () => _requestSwipe(true),
                    ),
                    RoundButton(
                      icon: LucideIcons.info,
                      label: 'Xem chi tiết',
                      size: 44,
                      color: PT.deep,
                      background: Colors.white,
                      onTap: _busy
                          ? null
                          : () => openPage(
                              context,
                              person
                                  ? PersonDetailScreen(
                                      state: state,
                                      person: candidate!,
                                    )
                                  : RoomDetailScreen(
                                      state: state,
                                      room: room!,
                                    ),
                            ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class RoomCard extends StatelessWidget {
  final Room room;
  final bool saved;
  final double? photoHeight;
  final bool showExtendedInfo;
  final VoidCallback onSave, onInfo;
  const RoomCard({
    super.key,
    required this.room,
    required this.saved,
    this.photoHeight,
    this.showExtendedInfo = false,
    required this.onSave,
    required this.onInfo,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: PT.card(radius: 22),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            InkWell(
              onTap: onInfo,
              child: photoHeight != null
                  ? RoomGallery(
                      room: room,
                      height: photoHeight!,
                      allowSwipe: false,
                    )
                  : AspectRatio(
                      aspectRatio: _feedPhotoAspectRatio(context),
                      child: LayoutBuilder(
                        builder: (_, constraints) => RoomGallery(
                          room: room,
                          height: constraints.maxHeight,
                          allowSwipe: false,
                        ),
                      ),
                    ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Pill(
                'Match ${room.match}%',
                icon: LucideIcons.heart,
                color: PT.green,
                bg: Colors.white.withValues(alpha: .94),
                dense: true,
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: RoundButton(
                icon: saved ? LucideIcons.heartHandshake : LucideIcons.heart,
                label: saved ? 'Bỏ lưu phòng' : 'Yêu thích',
                size: 36,
                onTap: onSave,
                background: Colors.white.withValues(alpha: .94),
              ),
            ),
          ],
        ),
        InkWell(
          onTap: onInfo,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 11, 15, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      room.type,
                      style: PT
                          .body(12, PT.green)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text('  •  ', style: PT.body(12, PT.line)),
                    Expanded(
                      child: Text(
                        '${room.area} m² • Tầng ${room.floor}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PT.body(12, PT.muted),
                      ),
                    ),
                    const Icon(
                      LucideIcons.shieldCheck,
                      size: 13.5,
                      color: PT.green,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Chủ trọ xác thực',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PT
                            .body(11.5, PT.green)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  room.title,
                  style: PT.title(18.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _Location(room.district)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        room.priceLabel,
                        style: PT.price(17.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: room.amenities
                      .take(3)
                      .map(
                        (a) => Pill(
                          a,
                          icon: amenityIcon(a),
                          dense: true,
                          bg: const Color(0xFFF3F7F5),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class PersonCard extends StatelessWidget {
  final Person person;
  final double? photoHeight;
  final bool showExtendedInfo;
  final VoidCallback onLike, onInfo;
  const PersonCard({
    super.key,
    required this.person,
    this.photoHeight,
    this.showExtendedInfo = false,
    required this.onLike,
    required this.onInfo,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: PT.card(radius: 22),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            InkWell(
              onTap: onInfo,
              child: photoHeight != null
                  ? SizedBox(
                      height: photoHeight,
                      width: double.infinity,
                      child: ReferencePhoto(kind: person.photo),
                    )
                  : AspectRatio(
                      aspectRatio: _feedPhotoAspectRatio(context),
                      child: ReferencePhoto(kind: person.photo),
                    ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Pill(
                'Match ${person.match}%',
                icon: LucideIcons.heart,
                color: PT.green,
                bg: Colors.white.withValues(alpha: .94),
                dense: true,
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: RoundButton(
                icon: LucideIcons.heart,
                label: 'Thích hồ sơ',
                size: 36,
                onTap: onLike,
                background: Colors.white.withValues(alpha: .94),
              ),
            ),
            const Positioned(bottom: 10, right: 10, child: _Counter('1/1')),
          ],
        ),
        InkWell(
          onTap: onInfo,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 11, 15, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.shieldCheck,
                      size: 13.5,
                      color: PT.green,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Đã xác thực CCCD',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PT
                            .body(11.5, PT.green)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '≤ ${(person.budget / 1e6).toStringAsFixed(1)}tr/tháng',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PT
                            .body(12, PT.deep)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${person.name}, ${person.age}',
                        style: PT.title(18.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        person.school,
                        style: PT.body(12, PT.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '“${person.bio}”',
                  style: PT.body(12.5, PT.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: person.interests
                      .take(3)
                      .map(
                        (i) => Pill(
                          i,
                          icon: amenityIcon(i),
                          dense: true,
                          bg: const Color(0xFFF3F7F5),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Counter extends StatelessWidget {
  final String text;
  const _Counter(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .58),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: PT.body(11, Colors.white).copyWith(fontWeight: FontWeight.w600),
    ),
  );
}

class _Location extends StatelessWidget {
  final String district;
  const _Location(this.district);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(LucideIcons.mapPin, size: 15, color: PT.green),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          '$district, TP.HCM',
          style: PT.body(12.5, PT.muted).copyWith(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

void showRoomFilters(
  BuildContext context,
  AppState state, {
  bool person = false,
}) {
  if (!person) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => RoomFilterSheet(state: state),
    );
    return;
  }
  String area = person ? state.personDistrict : state.district,
      type = person ? state.habit : state.type,
      gender = state.gender;
  double price = person ? state.personBudget : state.maxPrice;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, set) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      person ? 'Bộ lọc bạn ở' : 'Bộ lọc phòng',
                      style: PT.title(25),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng bộ lọc',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Khu vực', style: PT.body(15)),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Tất cả', 'Quận 10', 'Quận 3', 'Thủ Đức']
                    .map(
                      (d) => ChoiceChip(
                        label: Text(d),
                        selected: d == area,
                        onSelected: (_) => set(() => area = d),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Ngân sách tối đa: ${(price / 1e6).toStringAsFixed(1)} triệu/tháng',
                style: PT.body(14),
              ),
              Slider(
                value: price,
                min: 1000000,
                max: 6000000,
                divisions: 10,
                label: '${(price / 1e6).toStringAsFixed(1)} triệu',
                onChanged: (v) => set(() => price = v),
              ),
              const SizedBox(height: 10),
              Text(
                person ? 'Lối sống phù hợp' : 'Loại phòng',
                style: PT.body(15),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    (person
                            ? [
                                'Tất cả',
                                'Gọn gàng',
                                'Không hút thuốc',
                                'Ngủ sớm',
                              ]
                            : ['Tất cả', 'Studio', 'Phòng trọ', 'Căn hộ mini'])
                        .map(
                          (t) => ChoiceChip(
                            label: Text(t),
                            selected: t == type,
                            onSelected: (_) => set(() => type = t),
                          ),
                        )
                        .toList(),
              ),
              if (person) ...[
                const SizedBox(height: 18),
                Text('Giới tính', style: PT.body(15)),
                Wrap(
                  spacing: 8,
                  children: ['Tất cả', 'Nữ', 'Nam']
                      .map(
                        (g) => ChoiceChip(
                          label: Text(g),
                          selected: gender == g,
                          onSelected: (_) => set(() => gender = g),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                'Áp dụng bộ lọc',
                onTap: () {
                  if (person) {
                    state.personFilters(area, gender, type, price);
                  } else {
                    state.filters(area, type, price);
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class RoomDetailScreen extends StatefulWidget implements ResourceScreen {
  @override
  ResourceRef get resource => ResourceRef(ResourceKind.room, room.id);
  final AppState state;
  final Room room;
  const RoomDetailScreen({super.key, required this.state, required this.room});
  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  int tab = 0;
  @override
  void initState() {
    super.initState();
    if (widget.state.authenticated) {
      widget.state.store
          .workspace(widget.state.session.user!)
          .viewed
          .add(widget.room.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.room;
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) {
              final galleryHeight = (viewport.maxHeight - 435).clamp(
                155.0,
                390.0,
              );
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  Stack(
                    children: [
                      RoomGallery(room: r, height: galleryHeight),
                      Positioned(
                    top: 8,
                    left: 10,
                    child: RoundButton(
                      icon: LucideIcons.arrowLeft,
                      label: 'Quay lại',
                      background: Colors.white,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 54,
                    child: RoundButton(
                      icon: LucideIcons.share2,
                      label: 'Chia sẻ phòng',
                      background: Colors.white,
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          builder: (context) => Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Chia sẻ phòng', style: PT.title(21)),
                                const SizedBox(height: 12),
                                Text(r.title, style: PT.body()),
                                const SizedBox(height: 12),
                                PrimaryButton(
                                  'Gửi trong tin nhắn',
                                  icon: LucideIcons.messageCircle,
                                  onTap: () {
                                    Navigator.pop(context);
                                    withSession(
                                      this.context,
                                      () => openPage(
                                        this.context,
                                        ChatScreen(
                                          state: widget.state,
                                          conversation: widget.state
                                              .contactRoom(r),
                                          room: r,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 10,
                    child: RoundButton(
                      icon: LucideIcons.heart,
                      label: 'Lưu hoặc bỏ lưu',
                      color: widget.state.isSaved(r.id) ? PT.red : PT.deep,
                      background: Colors.white,
                      onTap: () => withSession(
                        context,
                        () => widget.state.toggleSave(r.id),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Pill(r.type, color: PT.green, dense: true),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i <
                                        (double.tryParse(
                                              widget.state.roomRating(r.id),
                                            ) ??
                                            0)
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 14,
                                color: PT.green,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.state.roomRating(r.id),
                              style: PT.body(11),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '(${widget.state.store.reviewRecords.where((v) => v.targetType == 'ROOM' && v.targetId == r.id).length} đánh giá)',
                              style: PT.body(11, PT.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.title,
                      style: PT.title(18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(child: _Location(r.district)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(r.priceLabel, style: PT.price(18)),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 0,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 0,
                            ),
                          ),
                          onPressed: () => openPage(
                            context,
                            CompareRoomsScreen(
                              state: widget.state,
                              initialRoomId: r.id,
                            ),
                          ),
                          icon: const Icon(LucideIcons.columns2, size: 14),
                          label: const Text('So sánh phòng này'),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 0,
                            ),
                          ),
                          icon: const Icon(LucideIcons.flag, size: 14),
                          label: const Text('Báo cáo tin phòng'),
                          onPressed: () => withSession(
                            context,
                            () => openPage(
                              context,
                              ReportScreen(
                                state: widget.state,
                                targetType: 'ROOM',
                                targetId: r.id,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: PT.mint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _Spec(
                              LucideIcons.expand,
                              '${r.area} m²',
                              'Diện tích',
                            ),
                          ),
                          Expanded(
                            child: _Spec(
                              LucideIcons.blocks,
                              'Tầng ${r.floor}',
                              'Vị trí tầng',
                            ),
                          ),
                          Expanded(
                            child: _Spec(
                              LucideIcons.armchair,
                              r.type,
                              'Loại phòng',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: r.amenities
                          .map(
                            (a) => Pill(a, icon: amenityIcon(a), dense: true),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(
                        4,
                        (i) => Expanded(
                          child: InkWell(
                            onTap: () => setState(() => tab = i),
                            child: Semantics(
                              button: true,
                              selected: tab == i,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 34,
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        [
                                          'Mô tả',
                                          'Tiện ích',
                                          'Vị trí',
                                          'Đánh giá',
                                        ][i],
                                        style: PT
                                            .body(
                                              12,
                                              tab == i ? PT.green : PT.muted,
                                            )
                                            .copyWith(
                                              fontWeight: tab == i
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                            ),
                                      ),
                                    ),
                                    Container(
                                      height: 2,
                                      color: tab == i ? PT.green : PT.line,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (tab == 0) ...[
                      Text('Mô tả', style: PT.title(15)),
                      const SizedBox(height: 3),
                      Text(
                        r.description,
                        style: PT.body(12, PT.muted),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: PT.card(radius: 11),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const AvatarPhoto(size: 30, online: true),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Chủ trọ đối tác Phòng Trọ Xanh',
                                        style: PT.title(13),
                                      ),
                                      Text(
                                        'Phản hồi 98% • Thường trả lời < 15 phút',
                                        style: PT.body(10, PT.muted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Pill(
                                  'Đã xác thực CCCD',
                                  icon: LucideIcons.shieldCheck,
                                  color: PT.green,
                                  dense: true,
                                ),
                                Pill(
                                  'Nhận phòng QR minh bạch',
                                  icon: LucideIcons.qrCode,
                                  color: Color(0xFF1D62E0),
                                  bg: Color(0xFFEAF1FF),
                                  dense: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (tab == 1) ...[
                      Text('Giá & chi phí minh bạch', style: PT.title(15)),
                      const SizedBox(height: 4),
                      for (final fee in [
                        ('Tiền thuê', r.priceLabel),
                        ('Điện', r.electricity),
                        ('Nước', r.water),
                        ('Phí khác', r.otherFees),
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Expanded(child: Text(fee.$1, style: PT.body(12))),
                              Expanded(
                                child: Text(
                                  fee.$2,
                                  textAlign: TextAlign.right,
                                  style: PT.body(12, PT.green),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: PT.card(color: PT.mint, radius: 11),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.calculator,
                                  size: 14,
                                  color: PT.green,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'Dự toán tổng chi phí hàng tháng',
                                    style: PT.title(13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Tổng dự kiến / tháng',
                                    style: PT
                                        .body(12)
                                        .copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Text(
                                  '~${((r.price + 450000) / 1e6).toStringAsFixed(2)} triệu/tháng',
                                  style: PT.price(15),
                                ),
                              ],
                            ),
                            Text(
                              'Tiền cọc tiêu chuẩn (1 tháng): ${r.priceLabel}',
                              style: PT.body(10, PT.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (tab == 2) ...[
                      Text('Vị trí phòng', style: PT.title(15)),
                      const SizedBox(height: 4),
                      Text(
                        '${r.address}, ${r.district}, TP.HCM',
                        style: PT.body(12, PT.muted),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 85,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: const CustomPaint(
                            painter: StreetPainter(),
                            child: Center(
                              child: Icon(
                                LucideIcons.mapPin,
                                size: 28,
                                color: PT.green,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      PrimaryButton(
                        'Mở bản đồ',
                        icon: LucideIcons.map,
                        onTap: () => openPage(
                          context,
                          MapScreen(state: widget.state, roomId: r.id),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DirectionsButton(room: r),
                    ],
                    if (tab == 3) ...[
                      Text('Đánh giá từ người thuê', style: PT.title(15)),
                      const SizedBox(height: 6),
                      if (!widget.state.store.reviewRecords.any(
                        (v) => v.targetType == 'ROOM' && v.targetId == r.id,
                      ))
                        const Text('Chưa có đánh giá cho phòng này.'),
                      for (final review
                          in widget.state.store.reviewRecords.where(
                            (v) => v.targetType == 'ROOM' && v.targetId == r.id,
                          ))
                        Container(
                          padding: const EdgeInsets.all(9),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: PT.card(radius: 11),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${review.authorName} • ${review.rating}/5',
                                style: PT.title(14),
                              ),
                              const SizedBox(height: 3),
                              Text(review.comment, style: PT.body(12)),
                              Text(
                                '${review.tags.join(' • ')} • HĐ: ${review.rentalId}',
                                style: PT.body(10, PT.muted),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: PT.line)),
            ),
            padding: const EdgeInsets.fromLTRB(13, 6, 13, 8),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: PrimaryButton(
                    widget.state.isSaved(r.id) ? 'Đã lưu' : 'Lưu',
                    icon: LucideIcons.bookmark,
                    outline: true,
                    onTap: () => withSession(
                      context,
                      () => widget.state.toggleSave(r.id),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: PrimaryButton(
                    'Liên hệ',
                    icon: LucideIcons.messageCircle,
                    onTap: () => withSession(
                      context,
                      () => openPage(
                        context,
                        ChatScreen(
                          state: widget.state,
                          conversation: widget.state.contactRoom(r),
                          room: r,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Spec extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _Spec(this.icon, this.title, this.subtitle);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: PT.green),
      const SizedBox(width: 6),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: PT.body(11)),
            Text(subtitle, style: PT.body(10, PT.muted)),
          ],
        ),
      ),
    ],
  );
}

class MenuReview extends StatelessWidget {
  final String name, text;
  const MenuReview({super.key, required this.name, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(11),
    decoration: PT.card(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AvatarPhoto(size: 30),
            const SizedBox(width: 8),
            Text(name, style: PT.title(15)),
            const Spacer(),
            Text('★ 4.8', style: PT.body(12, PT.green)),
          ],
        ),
        const SizedBox(height: 6),
        Text(text, style: PT.body(12, PT.muted)),
        const SizedBox(height: 5),
        const Pill(
          'Đã xác nhận thuê',
          icon: LucideIcons.shieldCheck,
          color: PT.green,
          dense: true,
        ),
      ],
    ),
  );
}

class PersonDetailScreen extends StatelessWidget implements ResourceScreen {
  @override
  ResourceRef get resource => ResourceRef(ResourceKind.person, person.id);
  final AppState state;
  final Person person;
  const PersonDetailScreen({
    super.key,
    required this.state,
    required this.person,
  });
  @override
  Widget build(BuildContext context) => BasicPage(
    title: 'Hồ sơ bạn ở',
    bottom: PrimaryButton(
      'Nhắn tin',
      icon: LucideIcons.messageCircle,
      onTap: () => withSession(
        context,
        () => openPage(
          context,
          ChatScreen(state: state, conversation: state.contactPerson(person)),
        ),
      ),
    ),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ReferencePhoto(kind: person.photo, height: 155),
        ),
        const SizedBox(height: 10),
        Text('${person.name}, ${person.age}', style: PT.title(22)),
        const SizedBox(height: 4),
        Text(person.school, style: PT.body(13, PT.muted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            Pill(
              'Tương thích ${person.match}%',
              icon: LucideIcons.heart,
              color: PT.green,
              dense: true,
            ),
            const Pill(
              'Sinh viên đã xác thực',
              icon: LucideIcons.shieldCheck,
              color: Color(0xFF0E7A56),
              bg: Color(0xFFE7F7F0),
              dense: true,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(person.bio, style: PT.body(13, PT.muted)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(11),
          decoration: PT.card(color: const Color(0xFFF7FBF9)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.sparkles,
                    size: 16,
                    color: PT.green,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Phân tích độ hợp lối sống',
                      style: PT.title(16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final metric in [
                (
                  'Giờ giấc sinh hoạt',
                  '${(person.match + 2).clamp(75, 99)}%',
                  ((person.match + 2).clamp(75, 99)) / 100.0,
                ),
                (
                  'Mức độ ngăn nắp & vệ sinh',
                  '${(person.match + 4).clamp(78, 99)}%',
                  ((person.match + 4).clamp(78, 99)) / 100.0,
                ),
                (
                  'Ngân sách thuê phòng',
                  '${(person.match - 1).clamp(72, 98)}%',
                  ((person.match - 1).clamp(72, 98)) / 100.0,
                ),
                (
                  'Thói quen & sở thích chung',
                  '${person.match}%',
                  person.match / 100.0,
                ),
              ]) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(metric.$1, style: PT.body(12)),
                          ),
                          Text(
                            metric.$2,
                            style: PT
                                .body(11, PT.green)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      RepaintBoundary(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: metric.$3,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFE3EFEA),
                            color: PT.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text('Sở thích & lối sống', style: PT.title(18)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...person.interests,
            ...person.habits,
          ].map((s) => Pill(s, dense: true)).toList(),
        ),
        const SizedBox(height: 10),
        Text(
          'Ngân sách tối đa ${(person.budget / 1e6).toStringAsFixed(1)} triệu/tháng',
          style: PT.body(13),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          icon: const Icon(LucideIcons.flag, size: 16),
          label: const Text('Báo cáo hồ sơ'),
          onPressed: () => withSession(
            context,
            () => openPage(
              context,
              ReportScreen(
                state: state,
                targetType: 'USER',
                targetId: person.id,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class SavedRoomsScreen extends StatelessWidget {
  final AppState state;
  const SavedRoomsScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final rooms = state.rooms
          .where((r) => state.saved.contains(r.id))
          .toList();
      return BasicPage(
        title: 'Phòng đã lưu',
        bottom: rooms.isEmpty
            ? null
            : PrimaryButton(
                'So sánh phòng',
                outline: true,
                onTap: () => openPage(
                  context,
                  CompareRoomsScreen(
                    state: state,
                    initialRoomId: rooms.first.id,
                  ),
                ),
              ),
        child: rooms.isEmpty
            ? const EmptyState(
                'Chưa có phòng đã lưu',
                'Bấm trái tim hoặc vuốt phải để lưu phòng yêu thích.',
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: rooms
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: RoomCard(
                          room: r,
                          saved: true,
                          onSave: () => state.toggleSave(r.id),
                          onInfo: () => openPage(
                            context,
                            RoomDetailScreen(state: state, room: r),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
      );
    },
  );
}

class MapScreen extends StatefulWidget {
  final AppState state;
  final String? roomId;
  const MapScreen({super.key, required this.state, this.roomId});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int selected = 0;
  bool initialized = false;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, _) {
      final rooms = [...widget.state.filteredRooms];
      if (widget.roomId != null) {
        final target = widget.state.roomById(widget.roomId!);
        final access = const RoutePolicy(public: true).evaluate(
          widget.state,
          target: ResourceRef(ResourceKind.room, widget.roomId!),
        );
        if (access != AccessResult.allowed) return AccessNotice(result: access);
        if (target!.latitude == null || target.longitude == null) {
          return const BasicPage(
            title: 'Vị trí phòng',
            child: EmptyState(
              'Chưa có tọa độ',
              'Liên hệ chủ trọ để được hướng dẫn địa chỉ.',
            ),
          );
        }
        if (!rooms.any((r) => r.id == target.id)) rooms.add(target);
        if (!initialized) {
          selected = rooms.indexWhere((r) => r.id == target.id);
          initialized = true;
        }
      }
      if (rooms.isEmpty) {
        return BasicPage(
          title: 'Bản đồ phòng trọ',
          child: EmptyState(
            'Không có phòng phù hợp',
            'Thay đổi bộ lọc để tìm phòng khác.',
            action: TextButton(
              onPressed: () => showRoomFilters(context, widget.state),
              child: const Text('Bộ lọc'),
            ),
          ),
        );
      }
      selected = selected.clamp(0, rooms.length - 1);
      return BasicPage(
        title: 'Bản đồ phòng trọ',
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(LucideIcons.mapPin, color: PT.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vị trí minh họa • ${rooms.length} phòng',
                      style: PT.body(14),
                    ),
                  ),
                  Pill(
                    'TP.HCM',
                    onTap: () => showRoomFilters(context, widget.state),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: StreetPainter()),
                  ),
                  const Positioned(
                    left: 20,
                    top: 65,
                    child: Text(
                      'QUẬN 10',
                      style: TextStyle(color: PT.muted, letterSpacing: 2),
                    ),
                  ),
                  const Positioned(
                    right: 20,
                    bottom: 60,
                    child: Text(
                      'ĐH Bách Khoa',
                      style: TextStyle(color: PT.muted),
                    ),
                  ),
                  for (var i = 0; i < rooms.length; i++)
                    Positioned(
                      left: 30 + (i % 2) * 150.0,
                      top: 70 + i * 60.0,
                      child: Pill(
                        '${(rooms[i].price / 1e6).toStringAsFixed(1)} triệu',
                        icon: LucideIcons.house,
                        color: selected == i ? Colors.white : PT.green,
                        bg: selected == i ? PT.green : Colors.white,
                        onTap: () => setState(() => selected = i),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: PT.card(),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: SizedBox(
                      width: 66,
                      height: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(9)),
                        child: RoomPhoto(room: rooms[selected]),
                      ),
                    ),
                    title: Text(rooms[selected].title, style: PT.title(16)),
                    subtitle: Text(
                      rooms[selected].priceLabel,
                      style: PT.body(13, PT.green),
                    ),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () => openPage(
                      context,
                      RoomDetailScreen(
                        state: widget.state,
                        room: rooms[selected],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: DirectionsButton(room: rooms[selected]),
            ),
          ],
        ),
      );
    },
  );
}

class StreetPainter extends CustomPainter {
  const StreetPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEBEFEC),
    );
    final green = Paint()..color = const Color(0xFFD3E8D5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .6, 0, size.width * .3, size.height * .4),
        const Radius.circular(20),
      ),
      green,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * .6, size.width * .25, size.height * .4),
        const Radius.circular(20),
      ),
      green,
    );
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 8;
    for (double x = -size.height; x < size.width; x += 55) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * .6, size.height),
        road,
      );
    }
    for (double y = 0; y < size.height; y += 60) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + math.sin(y) * 15),
        road,
      );
    }
    canvas.drawLine(
      Offset(0, size.height * .4),
      Offset(size.width, size.height * .65),
      Paint()
        ..color = const Color(0xFFFBF6DF)
        ..strokeWidth = 15,
    );
  }

  @override
  bool shouldRepaint(StreetPainter old) => false;
}
