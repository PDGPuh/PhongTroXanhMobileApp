import 'package:flutter/material.dart';

import '../account/account_workflows.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../core/reference_photo.dart';
import '../../demo/models.dart';
import '../rooms/room_screens.dart';
import '../rooms/room_gallery.dart';

class MessagesScreen extends StatefulWidget {
  final AppState state;
  const MessagesScreen({super.key, required this.state});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final conversations = widget.state.conversations
        .where(
          (c) =>
              ('${c.name} ${c.participantName} ${c.subtitle} ${c.messages.map((m) => m.text).join(' ')}')
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 10),
          child: Row(
            children: [
              Expanded(child: Text('Tin nhắn', style: PT.title(22))),
              RoundButton(
                icon: LucideIcons.userRoundPlus,
                label: 'Tin nhắn mới',
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (context) => SafeArea(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Bắt đầu trò chuyện',
                            style: PT.title(20),
                          ),
                        ),
                        ...widget.state.people.map(
                          (p) => ListTile(
                            leading: AvatarPhoto(kind: p.photo, size: 38),
                            title: Text(p.name),
                            onTap: () {
                              Navigator.pop(context);
                              openPage(
                                this.context,
                                ChatScreen(
                                  state: widget.state,
                                  conversation: widget.state.contactPerson(p),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              RoundButton(
                icon: LucideIcons.ellipsisVertical,
                label: 'Tùy chọn tin nhắn',
                onTap: () {
                  for (final c in widget.state.conversations) {
                    widget.state.read(c);
                  }
                  message(context, 'Đã đánh dấu tất cả là đã đọc');
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.zero,
          child: TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm tin nhắn, tên hoặc nội dung...',
              prefixIcon: const Icon(LucideIcons.search, size: 19),
              fillColor: PT.grey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (conversations.isEmpty)
          const EmptyState(
            'Không tìm thấy hội thoại',
            'Thử tìm theo tên người hoặc tên phòng.',
          ),
        ...conversations.map(
          (c) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: PT.card(
              color: c.unread > 0 ? const Color(0xFFF3FBF7) : Colors.white,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  widget.state.read(c);
                  openPage(
                    context,
                    ChatScreen(state: widget.state, conversation: c),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AvatarPhoto(
                        kind: c.photo,
                        size: 46,
                        online: c.photo != PhotoKind.room,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(c.name, style: PT.title(15)),
                                if (c.host)
                                  const Pill(
                                    'Chủ trọ',
                                    color: PT.green,
                                    dense: true,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              c.messages.isNotEmpty
                                  ? '${c.messages.last.delivery == MessageDelivery.failed
                                        ? 'Chưa gửi: '
                                        : c.messages.last.delivery == MessageDelivery.sending
                                        ? 'Đang gửi: '
                                        : ''}${c.messages.last.text}'
                                  : c.subtitle,
                              style: PT.body(12, PT.muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            c.messages.isEmpty ? c.time : c.messages.last.time,
                            style: PT.body(11, PT.muted),
                          ),
                          const SizedBox(height: 6),
                          if (c.unread > 0)
                            Container(
                              width: 19,
                              height: 19,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: PT.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${c.unread}',
                                style: PT.body(11, Colors.white),
                              ),
                            )
                          else
                            const Icon(
                              LucideIcons.checkCheck,
                              size: 16,
                              color: PT.green,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ChatScreen extends StatefulWidget implements ResourceScreen {
  @override
  ResourceRef get resource =>
      ResourceRef(ResourceKind.conversation, conversation.id);
  final AppState state;
  final Conversation conversation;
  final Room? room;
  const ChatScreen({
    super.key,
    required this.state,
    required this.conversation,
    this.room,
  });
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final draft = TextEditingController(), scroll = ScrollController();
  bool sending = false;
  late final draftOwner = widget.state.userId;
  @override
  void initState() {
    super.initState();
    draft.text = widget.state.drafts['chat-${widget.conversation.id}'] ?? '';
    draft.addListener(() {
      if (widget.state.userId == draftOwner && widget.state.authenticated) {
        widget.state.drafts['chat-${widget.conversation.id}'] = draft.text;
      }
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.state.userId == draftOwner) {
        widget.state.read(widget.conversation);
      }
      if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    draft.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (sending || draft.text.trim().isEmpty) return;
    final text = draft.text;
    setState(() => sending = true);
    final request = widget.state.sendAsync(widget.conversation, text);
    draft.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
    await request;
    if (mounted) setState(() => sending = false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, _) => Scaffold(
      backgroundColor: const Color(0xFFFDFFFF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: PT.line)),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Quay lại',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.arrowLeft),
                  ),
                  AvatarPhoto(
                    kind: widget.conversation.photo,
                    size: 38,
                    online: true,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.conversation.participantName.isEmpty
                              ? widget.conversation.name
                              : widget.conversation.participantName,
                          style: PT.title(15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: PT.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Đang hoạt động',
                                style: PT.body(10, PT.muted),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  RoundButton(
                    icon: LucideIcons.phone,
                    label: 'Gọi điện',
                    size: 34,
                    background: PT.mint,
                    onTap: () => message(
                      context,
                      'Tính năng gọi điện sẽ mở khi kết nối dịch vụ thực tế.',
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Tùy chọn hội thoại',
                    icon: const Icon(LucideIcons.ellipsisVertical),
                    onSelected: (v) {
                      if (v == 'mute') {
                        widget.state.toggleConversationMute(
                          widget.conversation.id,
                        );
                      } else {
                        openPage(
                          context,
                          ReportScreen(
                            state: widget.state,
                            targetType: 'CONVERSATION',
                            targetId: widget.conversation.id,
                          ),
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'mute',
                        child: Text(
                          widget.state.conversationMuted(widget.conversation.id)
                              ? 'Bật thông báo'
                              : 'Tắt thông báo',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'report',
                        child: Text('Báo cáo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                children: [
                  if (widget.conversation.messages.isEmpty)
                    const EmptyState(
                      'Nói lời chào',
                      'Bắt đầu bằng một lời chào và chia sẻ nhu cầu của bạn.',
                      icon: LucideIcons.messageCircle,
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final prompt in [
                            'Phòng còn trống không ạ?',
                            'Mình muốn hẹn xem phòng',
                            'Chi phí điện nước thế nào?',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Pill(
                                prompt,
                                icon: LucideIcons.sparkles,
                                color: PT.green,
                                bg: PT.mint,
                                dense: true,
                                onTap: () {
                                  draft.text = prompt;
                                  draft.selection = TextSelection.collapsed(
                                    offset: prompt.length,
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  ...widget.conversation.messages.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: m.mine
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!m.mine) ...[
                            AvatarPhoto(
                              kind: widget.conversation.photo,
                              size: 30,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * .78,
                              ),
                              child: Column(
                                crossAxisAlignment: m.mine
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: m.mine ? PT.sage : PT.grey,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(m.text, style: PT.body(13)),
                                        if (m.room &&
                                            widget.state.roomById(
                                                  m.roomId ??
                                                      widget
                                                          .conversation
                                                          .roomId ??
                                                      '',
                                                ) !=
                                                null) ...[
                                          const SizedBox(height: 6),
                                          SharedRoomCard(
                                            state: widget.state,
                                            room: widget.state.roomById(
                                              m.roomId ??
                                                  widget.conversation.roomId ??
                                                  '',
                                            )!,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (m.delivery == MessageDelivery.sending)
                                    Text(
                                      'Đang gửi…',
                                      style: PT.body(11, PT.muted),
                                    ),
                                  if (m.delivery == MessageDelivery.failed)
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () => widget.state.sendAsync(
                                        widget.conversation,
                                        m.text,
                                        retryId: m.id,
                                      ),
                                      icon: const Icon(
                                        LucideIcons.rotateCcw,
                                        size: 14,
                                      ),
                                      label: const Text('Chưa gửi • Thử lại'),
                                    ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        m.time,
                                        style: PT.body(10, PT.muted),
                                      ),
                                      if (m.mine) ...[
                                        const SizedBox(width: 5),
                                        Icon(
                                          m.delivery == MessageDelivery.sending
                                              ? LucideIcons.clock
                                              : m.delivery ==
                                                    MessageDelivery.failed
                                              ? LucideIcons.circleAlert
                                              : LucideIcons.check,
                                          color:
                                              m.delivery ==
                                                  MessageDelivery.failed
                                              ? PT.red
                                              : PT.green,
                                          size: 13,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: PT.line)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RoundButton(
                    icon: LucideIcons.image,
                    label: 'Đính kèm',
                    size: 36,
                    background: PT.mint,
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Chia sẻ trong hội thoại',
                                style: PT.title(20),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 220,
                                child: ListView(
                                  children: [
                                    for (final selected
                                        in widget.state.rooms.where(
                                          (r) =>
                                              r.status ==
                                                  RoomStatus.available ||
                                              r.landlordId ==
                                                  widget.state.userId,
                                        ))
                                      MenuRow(
                                        icon: LucideIcons.house,
                                        title: selected.title,
                                        subtitle: selected.priceLabel,
                                        onTap: () {
                                          widget.state.sendAsync(
                                            widget.conversation,
                                            'Mình chia sẻ phòng này nhé.',
                                            roomId: selected.id,
                                          );
                                          Navigator.pop(context);
                                        },
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Chọn ảnh từ thiết bị sẽ được nối ở giai đoạn tích hợp.',
                                style: PT.body(11, PT.muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: draft,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => send(),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: PT.line),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  RoundButton(
                    icon: LucideIcons.send,
                    label: 'Gửi tin nhắn',
                    size: 40,
                    color: Colors.white,
                    background: PT.green,
                    onTap: sending || draft.text.trim().isEmpty ? null : send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SharedRoomCard extends StatelessWidget {
  final AppState state;
  final Room room;
  const SharedRoomCard({super.key, required this.state, required this.room});
  @override
  Widget build(BuildContext context) => Container(
    decoration: PT.card(),
    padding: const EdgeInsets.all(6),
    child: Column(
      children: [
        InkWell(
          onTap: () =>
              openPage(context, RoomDetailScreen(state: state, room: room)),
          child: Row(
            children: [
              SizedBox(
                width: 108,
                height: 82,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  child: RoomPhoto(room: room),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.title, style: PT.title(13)),
                    const SizedBox(height: 5),
                    Text(
                      '${room.district}, TP.HCM',
                      style: PT.body(10, PT.muted),
                    ),
                    const SizedBox(height: 5),
                    Text(room.priceLabel, style: PT.price(15)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () =>
              openPage(context, MapScreen(state: state, roomId: room.id)),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: PT.mint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.mapPin, color: PT.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Xem vị trí trên bản đồ', style: PT.body(11)),
                ),
                const Icon(LucideIcons.chevronRight, size: 16),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
