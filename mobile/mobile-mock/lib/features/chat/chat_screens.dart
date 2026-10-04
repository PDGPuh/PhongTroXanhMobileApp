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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 16),
          child: Row(
            children: [
              Expanded(child: Text('Tin nhắn', style: PT.title(28))),
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
                          padding: const EdgeInsets.all(18),
                          child: Text(
                            'Bắt đầu trò chuyện',
                            style: PT.title(22),
                          ),
                        ),
                        ...widget.state.people.map(
                          (p) => ListTile(
                            leading: AvatarPhoto(kind: p.photo, size: 40),
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
              prefixIcon: const Icon(LucideIcons.search, size: 21),
              fillColor: PT.grey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (conversations.isEmpty)
          const EmptyState(
            'Không tìm thấy hội thoại',
            'Thử tìm theo tên người hoặc tên phòng.',
          ),
        ...conversations.map(
          (c) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: PT.line)),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AvatarPhoto(
                        kind: c.photo,
                        size: 58,
                        online: c.photo != PhotoKind.room,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 7,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(c.name, style: PT.title(17)),
                                if (c.host)
                                  const Pill('Chủ trọ', color: PT.green),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              c.messages.isNotEmpty
                                  ? '${c.messages.last.delivery == MessageDelivery.failed
                                        ? 'Chưa gửi: '
                                        : c.messages.last.delivery == MessageDelivery.sending
                                        ? 'Đang gửi: '
                                        : ''}${c.messages.last.text}'
                                  : c.subtitle,
                              style: PT.body(14, PT.muted),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            c.messages.isEmpty ? c.time : c.messages.last.time,
                            style: PT.body(12, PT.muted),
                          ),
                          const SizedBox(height: 10),
                          if (c.unread > 0)
                            Container(
                              width: 21,
                              height: 21,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: PT.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${c.unread}',
                                style: PT.body(12, Colors.white),
                              ),
                            )
                          else
                            const Icon(
                              LucideIcons.checkCheck,
                              size: 17,
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
              padding: const EdgeInsets.fromLTRB(8, 10, 13, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: PT.line)),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Quay lại',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.arrowLeft),
                  ),
                  AvatarPhoto(
                    kind: widget.conversation.photo,
                    size: 45,
                    online: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.conversation.participantName.isEmpty
                              ? widget.conversation.name
                              : widget.conversation.participantName,
                          style: PT.title(17),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: PT.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
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
                padding: const EdgeInsets.fromLTRB(12, 13, 12, 16),
                children: [
                  if (widget.conversation.messages.isEmpty)
                    const EmptyState(
                      'Nói lời chào',
                      'Bắt đầu bằng một lời chào và chia sẻ nhu cầu của bạn.',
                      icon: LucideIcons.messageCircle,
                    ),
                  ...widget.conversation.messages.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: m.mine
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!m.mine) ...[
                            AvatarPhoto(
                              kind: widget.conversation.photo,
                              size: 34,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Flexible(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * .76,
                              ),
                              child: Column(
                                crossAxisAlignment: m.mine
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: m.mine ? PT.sage : PT.grey,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(m.text, style: PT.body(14)),
                                        if (m.room &&
                                            widget.state.roomById(
                                                  m.roomId ??
                                                      widget
                                                          .conversation
                                                          .roomId ??
                                                      '',
                                                ) !=
                                                null) ...[
                                          const SizedBox(height: 8),
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
                                      style: PT.body(12, PT.muted),
                                    ),
                                  if (m.delivery == MessageDelivery.failed)
                                    TextButton.icon(
                                      onPressed: () => widget.state.sendAsync(
                                        widget.conversation,
                                        m.text,
                                        retryId: m.id,
                                      ),
                                      icon: const Icon(
                                        LucideIcons.rotateCcw,
                                        size: 16,
                                      ),
                                      label: const Text('Chưa gửi • Thử lại'),
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        m.time,
                                        style: PT.body(10, PT.muted),
                                      ),
                                      if (m.mine) ...[
                                        const SizedBox(width: 6),
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
                                          size: 14,
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                    background: PT.mint,
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Chia sẻ trong hội thoại',
                                style: PT.title(22),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 260,
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
                              const SizedBox(height: 10),
                              Text(
                                'Chọn ảnh từ thiết bị sẽ được nối ở giai đoạn tích hợp.',
                                style: PT.body(12, PT.muted),
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
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => send(),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: const BorderSide(color: PT.line),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  RoundButton(
                    icon: LucideIcons.send,
                    label: 'Gửi tin nhắn',
                    size: 45,
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
