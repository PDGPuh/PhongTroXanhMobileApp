import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_state.dart';
import '../../core/async_resource.dart';
import '../../core/device_media.dart';
import '../../core/flow_page.dart';
import '../../core/reference_photo.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../chat/chat_screens.dart';
import '../landlord/landlord_screens.dart';
import '../rooms/room_screens.dart';

class ProfileSetupScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback? onComplete;
  const ProfileSetupScreen({super.key, required this.state, this.onComplete});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, mail, bio, school, minimum, maximum;
  late String gender, district, birthday;
  late PhotoKind avatar;
  LocalPhoto? avatarPhoto;
  late Set<String> interests;
  late bool smoke, early, tidy;
  int step = 0;
  String get draftKey =>
      widget.onComplete == null ? 'profile-form' : 'onboarding';
  bool get owner => widget.state.role == UserRole.landlord;
  List<String> get steps => owner
      ? ['Hồ sơ', 'Phòng trọ', 'Xác minh', 'Hoàn tất']
      : ['Hồ sơ', 'Sở thích', 'Lối sống', 'Nhu cầu ở', 'Xác minh', 'Hoàn tất'];
  @override
  void initState() {
    super.initState();
    final s = widget.state;
    final p = s.store.profiles[s.userId]!;
    Map<String, dynamic> d = {};
    try {
      d = jsonDecode(s.drafts[draftKey] ?? '{}') as Map<String, dynamic>;
    } catch (_) {
      /* Ignore an obsolete draft. */
    }
    name = TextEditingController(text: d['name'] ?? s.fullName);
    mail = TextEditingController(text: d['email'] ?? s.email);
    bio = TextEditingController(text: d['bio'] ?? s.bio);
    school = TextEditingController(text: d['school'] ?? p.school);
    minimum = TextEditingController(text: '${d['min'] ?? p.budgetMin}');
    maximum = TextEditingController(text: '${d['max'] ?? p.budgetMax}');
    gender = d['gender'] ?? p.gender;
    district = d['district'] ?? p.district;
    birthday = d['birthday'] ?? p.birthday;
    avatar = PhotoKind.values.firstWhere(
      (a) => a.name == d['avatar'],
      orElse: () => p.avatar,
    );
    avatarPhoto = d.containsKey('avatarPhoto')
        ? s.ownPhoto(d['avatarPhoto'])
        : p.avatarPhoto;
    interests = {...(d['interests'] as List?)?.cast<String>() ?? s.interests};
    smoke = d['smoke'] ?? s.smoking;
    early = d['early'] ?? s.earlySleep;
    tidy = d['tidy'] ?? s.tidy;
    step = (d['step'] as int? ?? 0).clamp(0, steps.length - 1);
    for (final c in [name, mail, bio, school, minimum, maximum]) {
      c.addListener(saveDraft);
    }
  }

  void saveDraft() => widget.state.drafts[draftKey] = jsonEncode({
    'name': name.text,
    'email': mail.text,
    'bio': bio.text,
    'school': school.text,
    'min': minimum.text,
    'max': maximum.text,
    'gender': gender,
    'district': district,
    'birthday': birthday,
    'avatar': avatar.name,
    'avatarPhoto': avatarPhoto?.id,
    'interests': interests.toList(),
    'smoke': smoke,
    'early': early,
    'tidy': tidy,
    'step': step,
  });
  void change(VoidCallback fn) {
    setState(fn);
    saveDraft();
  }

  @override
  void dispose() {
    for (final c in [name, mail, bio, school, minimum, maximum]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FlowPage(
    state: widget.state,
    title: widget.onComplete == null ? 'Chỉnh sửa hồ sơ' : 'Hoàn thiện hồ sơ',
    content: (ctx, f) {
      final all = widget.onComplete == null;
      return [
        if (!all) ...[
          LinearProgressIndicator(
            value: (step + 1) / steps.length,
            color: PT.green,
            backgroundColor: PT.mint,
          ),
          const SizedBox(height: 16),
          Text(
            'Bước ${step + 1}/${steps.length} • ${steps[step]}',
            style: PT.title(25),
          ),
          const SizedBox(height: 20),
        ],
        Form(
          key: form,
          child: Column(
            children: [
              if (all || step == 0)
                flowCard('Thông tin của bạn', [
                  Center(
                    child: AvatarPhoto(
                      kind: avatar,
                      photo: avatarPhoto,
                      size: 90,
                    ),
                  ),
                  PrimaryButton(
                    'Chọn ảnh đại diện từ thiết bị',
                    outline: true,
                    onTap: f.busy
                        ? null
                        : () async {
                            final camera = await choosePhotoSource(ctx);
                            if (camera == null || !ctx.mounted) return;
                            await f.perform(() async {
                              final photos = await widget.state.pickMedia(
                                camera: camera,
                              );
                              if (mounted && photos.isNotEmpty) {
                                change(() => avatarPhoto = photos.first);
                              }
                            });
                          },
                  ),
                  Center(
                    child: TextButton(
                      onPressed: f.busy
                          ? null
                          : () async {
                              final value =
                                  await showModalBottomSheet<PhotoKind>(
                                    context: ctx,
                                    builder: (sheet) => SafeArea(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Wrap(
                                          spacing: 16,
                                          children: [
                                            for (final kind in [
                                              PhotoKind.man,
                                              PhotoKind.woman,
                                              PhotoKind.host,
                                            ])
                                              InkWell(
                                                onTap: () =>
                                                    Navigator.pop(sheet, kind),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  child: AvatarPhoto(
                                                    kind: kind,
                                                    size: 70,
                                                  ),
                                                ),
                                              ),
                                            const Text(
                                              'Chọn avatar mẫu để thử giao diện',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                              if (value != null && mounted) {
                                change(() {
                                  avatar = value;
                                  avatarPhoto = null;
                                });
                              }
                            },
                      child: const Text('Đổi ảnh đại diện'),
                    ),
                  ),
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Nhập họ tên' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: mail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email hồ sơ'),
                    validator: (v) =>
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v ?? '')
                        ? null
                        : 'Email chưa hợp lệ',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Email đăng nhập: ${widget.state.session.user!.email}',
                    style: PT.body(12, PT.muted),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: school,
                    decoration: const InputDecoration(
                      labelText: 'Trường học / nơi làm việc',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: gender,
                    decoration: const InputDecoration(labelText: 'Giới tính'),
                    items: ['Nữ', 'Nam', 'Khác']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => change(() => gender = v!),
                  ),
                  TextButton.icon(
                    icon: const Icon(LucideIcons.calendar),
                    label: Text(
                      birthday.isEmpty
                          ? 'Chọn ngày sinh'
                          : 'Ngày sinh: $birthday',
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final date = await showDatePicker(
                        context: ctx,
                        firstDate: DateTime(1900),
                        lastDate: now,
                        initialDate: DateTime(now.year - 21),
                      );
                      if (date != null && mounted) {
                        change(
                          () => birthday = date.toIso8601String().substring(
                            0,
                            10,
                          ),
                        );
                      }
                    },
                  ),
                  TextField(
                    controller: bio,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Giới thiệu bản thân',
                    ),
                  ),
                ]),
              if (all || (!owner && step == 1))
                flowCard('Sở thích', [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        ['Nấu ăn', 'Đọc sách', 'Du lịch', 'Âm nhạc', 'Thể thao']
                            .map(
                              (i) => FilterChip(
                                label: Text(i),
                                selected: interests.contains(i),
                                onSelected: (v) => change(() {
                                  v ? interests.add(i) : interests.remove(i);
                                }),
                              ),
                            )
                            .toList(),
                  ),
                ]),
              if (all || (!owner && step == 2))
                flowCard('Lối sống', [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Chấp nhận hút thuốc'),
                    value: smoke,
                    onChanged: (v) => change(() => smoke = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ngủ sớm'),
                    value: early,
                    onChanged: (v) => change(() => early = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gọn gàng'),
                    value: tidy,
                    onChanged: (v) => change(() => tidy = v),
                  ),
                ]),
              if (all || (!owner && step == 3))
                flowCard('Nhu cầu ở', [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: district,
                    decoration: const InputDecoration(
                      labelText: 'Khu vực mong muốn',
                    ),
                    items: ['Quận 10', 'Quận 3', 'Thủ Đức']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => change(() => district = v!),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: minimum,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ngân sách tối thiểu (đ)',
                    ),
                    validator: (v) => (int.tryParse(v ?? '') ?? -1) < 0
                        ? 'Nhập ngân sách hợp lệ'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: maximum,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ngân sách tối đa (đ)',
                    ),
                    validator: (v) =>
                        (int.tryParse(v ?? '') ?? 0) <= 0 ||
                            (int.tryParse(v ?? '') ?? 0) <
                                (int.tryParse(minimum.text) ?? 0)
                        ? 'Tối đa phải lớn hơn hoặc bằng tối thiểu'
                        : null,
                  ),
                ]),
              if (!all && owner && step == 1)
                flowCard('Phòng trọ của bạn', [
                  Text(
                    '${widget.state.myRooms.length} phòng trong tài khoản',
                    style: PT.body(15),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    'Đăng phòng mới',
                    onTap: () =>
                        openPage(ctx, PostRoomScreen(state: widget.state)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bạn có thể bổ sung phòng sau khi hoàn thiện hồ sơ.',
                  ),
                ]),
              if (!all && step == steps.length - 2)
                flowCard('Xác minh tài khoản', [
                  Text(widget.state.verification, style: PT.body(16, PT.green)),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    'Mở xác minh CCCD',
                    onTap: () =>
                        openPage(ctx, VerificationScreen(state: widget.state)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Có thể xác minh sau tại Cá nhân. Hồ sơ chờ duyệt vẫn giữ nguyên trạng thái.',
                  ),
                ]),
              if (!all && step == steps.length - 1)
                flowCard('Sẵn sàng bắt đầu', [
                  Text(name.text, style: PT.title(24)),
                  Text(
                    '$district • ${maximum.text}đ/tháng',
                    style: PT.body(15),
                  ),
                  Text(interests.join(' • ')),
                  Text('Xác minh: ${widget.state.verification}'),
                ]),
            ],
          ),
        ),
        if (!all && step > 0) ...[
          PrimaryButton(
            'Bước trước',
            outline: true,
            onTap: f.busy ? null : () => change(() => step--),
          ),
          const SizedBox(height: 12),
        ],
        PrimaryButton(
          all
              ? 'Lưu thay đổi'
              : step == steps.length - 1
              ? 'Bắt đầu khám phá'
              : 'Tiếp tục',
          busy: f.busy,
          onTap: f.busy
              ? null
              : () async {
                  if (!(form.currentState?.validate() ?? true)) {
                    return;
                  }
                  if (!all && step < steps.length - 1) {
                    change(() => step++);
                    return;
                  }
                  final ok = await f.perform(
                    () => widget.state.workflows.run('profile', () {
                      if (name.text.trim().isEmpty ||
                          (int.tryParse(maximum.text) ?? 0) <
                              (int.tryParse(minimum.text) ?? 0)) {
                        throw const RepositoryFailure(
                          RepositoryFault.server,
                          'Kiểm tra họ tên và ngân sách.',
                        );
                      }
                      widget.state.updateProfile(
                        name.text.trim(),
                        mail.text.trim(),
                        bio.text.trim(),
                      );
                      widget.state.preferences(interests, smoke, early, tidy);
                      final p =
                          widget.state.store.profiles[widget.state.userId]!;
                      p.school = school.text.trim();
                      p.avatar = avatar;
                      p.avatarPhoto = avatarPhoto;
                      p.gender = gender;
                      p.birthday = birthday;
                      p.district = district;
                      p.budgetMin = int.tryParse(minimum.text) ?? 0;
                      p.budgetMax = int.tryParse(maximum.text) ?? 3000000;
                      if (!all) {
                        p.onboardingDone = true;
                      }
                      widget.state.drafts.remove(draftKey);
                    }),
                  );
                  if (ok && ctx.mounted) {
                    widget.onComplete == null
                        ? Navigator.pop(ctx)
                        : widget.onComplete!();
                  }
                },
        ),
        const SizedBox(height: 14),
        Text(
          'Bản nháp được giữ theo tài khoản khi quay lại; đăng xuất sẽ xóa bản nháp.',
          style: PT.body(12, PT.muted),
        ),
      ];
    },
  );
}

class EditProfileScreen extends StatelessWidget {
  final AppState state;
  const EditProfileScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) => ProfileSetupScreen(state: state);
}

class VerificationScreen extends StatefulWidget {
  final AppState state;
  const VerificationScreen({super.key, required this.state});
  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final number = TextEditingController();
  bool front = false, back = false;
  String? frontId, backId;
  @override
  void dispose() {
    number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FlowPage(
    state: widget.state,
    title: 'Xác minh tài khoản',
    content: (ctx, f) {
      final k = widget.state.store.kyc
          .where((k) => k.userId == widget.state.userId)
          .lastOrNull;
      final canSubmit = k == null || k.status == 'Đã từ chối';
      return [
        const Icon(LucideIcons.shieldCheck, size: 52, color: PT.green),
        const SizedBox(height: 20),
        Text('Thêm một bước để an tâm hơn', style: PT.title(27)),
        const SizedBox(height: 14),
        if (k != null)
          flowCard('Hồ sơ ${k.id}', [
            Text(k.status, style: PT.body(16, PT.green)),
            if (k.note.isNotEmpty) Text('Ghi chú: ${k.note}'),
            Text('Gửi: ${k.createdAt.toLocal().toString().substring(0, 16)}'),
            const SizedBox(height: 12),
            VerificationDocument(
              state: widget.state,
              userId: k.userId,
              reference: k.front,
              side: 'Mặt trước',
            ),
            const SizedBox(height: 12),
            VerificationDocument(
              state: widget.state,
              userId: k.userId,
              reference: k.back,
              side: 'Mặt sau',
            ),
          ]),
        if (canSubmit) ...[
          TextField(
            controller: number,
            keyboardType: TextInputType.number,
            maxLength: 12,
            decoration: const InputDecoration(labelText: 'Số CCCD (12 chữ số)'),
          ),
          for (final side in ['Mặt trước', 'Mặt sau'])
            flowCard(side, [
              if (side == 'Mặt trước' ? front : back) ...[
                VerificationDocument(
                  state: widget.state,
                  userId: widget.state.userId!,
                  reference: (side == 'Mặt trước' ? frontId : backId) ?? 'demo',
                  side: side,
                ),
                TextButton(
                  onPressed: f.busy
                      ? null
                      : () => setState(() {
                          side == 'Mặt trước' ? front = false : back = false;
                          side == 'Mặt trước' ? frontId = null : backId = null;
                        }),
                  child: Text('Xóa ảnh $side'),
                ),
              ],
              PrimaryButton(
                'Chọn ảnh $side từ thiết bị',
                outline: true,
                onTap: f.busy
                    ? null
                    : () async {
                        final camera = await choosePhotoSource(ctx);
                        if (camera == null || !ctx.mounted) return;
                        await f.perform(() async {
                          final photos = await widget.state.pickMedia(
                            camera: camera,
                          );
                          if (!mounted || photos.isEmpty) return;
                          setState(() {
                            if (side == 'Mặt trước') {
                              front = true;
                              frontId = photos.first.id;
                            } else {
                              back = true;
                              backId = photos.first.id;
                            }
                          });
                        });
                      },
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                'Chọn ảnh mẫu $side',
                outline: true,
                onTap: f.busy
                    ? null
                    : () => setState(() {
                        side == 'Mặt trước' ? front = true : back = true;
                        side == 'Mặt trước' ? frontId = null : backId = null;
                      }),
              ),
            ]),
          Text(
            'Ảnh từ thiết bị chỉ lưu trong bộ nhớ của lần chạy này; chưa gửi lên máy chủ. Có thể dùng ảnh mẫu để thử luồng.',
            style: PT.body(13, PT.muted),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            k == null ? 'Gửi xác minh' : 'Gửi lại hồ sơ',
            busy: f.busy,
            onTap: f.busy
                ? null
                : () => f.perform(
                    () => widget.state.workflows.submitKyc(
                      number.text.trim(),
                      front ? frontId ?? 'demo-front' : '',
                      back ? backId ?? 'demo-back' : '',
                    ),
                  ),
          ),
        ] else ...[
          const Text('Theo dõi kết quả tại đây và trong thông báo.'),
          const SizedBox(height: 16),
          PrimaryButton(
            'Kiểm tra trạng thái',
            outline: true,
            onTap: f.busy ? null : f.load,
          ),
        ],
      ];
    },
  );
}

class VerificationDocument extends StatelessWidget {
  final AppState state;
  final String userId, reference, side;
  const VerificationDocument({
    super.key,
    required this.state,
    required this.userId,
    required this.reference,
    required this.side,
  });
  @override
  Widget build(BuildContext context) {
    if (state.userId != userId && state.role != UserRole.admin) {
      return const Text('Bạn không có quyền xem giấy tờ này.');
    }
    if ([
      'demo',
      'demo-front',
      'demo-back',
      'front',
      'back',
    ].contains(reference)) {
      return DemoDocumentPreview(side: side);
    }
    final photo = state.store.workspaceById(userId).media[reference];
    if (photo == null) {
      return const Text(
        'Ảnh không còn trong lần chạy này. Vui lòng gửi lại hồ sơ.',
      );
    }
    return LocalPhotoView(
      photo: photo,
      height: 180,
      fit: BoxFit.contain,
      label: 'Ảnh CCCD $side',
    );
  }
}

class MatchesScreen extends StatefulWidget {
  final AppState state;
  const MatchesScreen({super.key, required this.state});
  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => FlowPage(
    state: widget.state,
    title: 'Bạn đã match',
    content: (ctx, f) {
      final s = widget.state;
      final matches = s.store.matches[s.userId] ?? {};
      final gold =
          s.unlimitedSwipes &&
          s.store.profiles[s.userId]?.package == 'Green Gold';
      final activeTab = tab == 2 && !gold ? 0 : tab;
      final ids = activeTab == 0
          ? matches
          : activeTab == 1
          ? s.liked.difference(matches)
          : (s.store.incomingLikes[s.userId] ?? <String>{}).difference(matches);
      return [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Đã ghép'),
              selected: activeTab == 0,
              onSelected: (_) => setState(() => tab = 0),
            ),
            ChoiceChip(
              label: const Text('Đã gửi lời thích'),
              selected: activeTab == 1,
              onSelected: (_) => setState(() => tab = 1),
            ),
            if (gold)
              ChoiceChip(
                label: const Text('Đã thích bạn'),
                selected: activeTab == 2,
                onSelected: (_) => setState(() => tab = 2),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (ids.isEmpty)
          EmptyState(
            activeTab == 0
                ? 'Chưa có match hai chiều'
                : activeTab == 1
                ? 'Chưa gửi lời thích'
                : 'Chưa có lời thích mới',
            'Khám phá bạn ở để tìm người phù hợp.',
            icon: LucideIcons.users,
          ),
        for (final p in s.people.where((p) => ids.contains(p.id)))
          flowCard(p.name, [
            AvatarPhoto(kind: p.photo, size: 70),
            const SizedBox(height: 12),
            Text('${p.match}% phù hợp • ${p.district}'),
            if (s.store.profiles[s.userId]!.priorityPeople.contains(p.id))
              const Text('Đã gửi Super Match'),
            const SizedBox(height: 12),
            PrimaryButton(
              'Xem hồ sơ',
              outline: true,
              onTap: () =>
                  openPage(ctx, PersonDetailScreen(state: s, person: p)),
            ),
            const SizedBox(height: 12),
            if (activeTab == 0) ...[
              PrimaryButton(
                'Nhắn tin',
                onTap: () => openPage(
                  ctx,
                  ChatScreen(state: s, conversation: s.contactPerson(p)),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                'Hủy ghép',
                outline: true,
                onTap: f.busy
                    ? null
                    : () async {
                        if (await confirmAction(
                          ctx,
                          'Hủy ghép với ${p.name}?',
                          'Lời thích và match này sẽ được gỡ. Hội thoại cũ vẫn được giữ.',
                        )) {
                          await f.perform(() => s.workflows.unmatch(p.id));
                        }
                      },
              ),
            ] else if (s.store.incomingLikes[s.userId]?.contains(p.id) ??
                false) ...[
              const Text('Hồ sơ này cũng đã thích bạn • phản hồi demo có sẵn'),
              const SizedBox(height: 12),
              PrimaryButton(
                activeTab == 2
                    ? 'Thích lại và ghép bạn'
                    : 'Xác nhận match hai chiều',
                busy: f.busy,
                onTap: f.busy
                    ? null
                    : () async {
                        if (await f.perform(
                              () => s.workflows.confirmMatch(
                                p.id,
                                likeBack: activeTab == 2,
                              ),
                            ) &&
                            mounted) {
                          setState(() => tab = 0);
                        }
                      },
              ),
            ] else
              const Text('Đã gửi lời thích • đang chờ phản hồi'),
          ]),
      ];
    },
  );
}

class ReportScreen extends StatefulWidget {
  final AppState state;
  final String targetType, targetId;
  const ReportScreen({
    super.key,
    required this.state,
    required this.targetType,
    required this.targetId,
  });
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final details = TextEditingController();
  String reason = 'Thông tin sai sự thật', receipt = '';
  @override
  void dispose() {
    details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FlowPage(
    state: widget.state,
    title: 'Báo cáo vi phạm',
    content: (ctx, f) => [
      if (receipt.isNotEmpty)
        EmptyState(
          'Đã tiếp nhận $receipt',
          'Bạn có thể xem trạng thái tại Báo cáo của tôi. Admin xử lý cùng hồ sơ này.',
          icon: LucideIcons.circleCheck,
        )
      else ...[
        Text(
          'Đối tượng: ${widget.targetType} • ${widget.targetId}',
          style: PT.body(14),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: reason,
          decoration: const InputDecoration(labelText: 'Lý do'),
          items: [
            'Thông tin sai sự thật',
            'Nội dung không phù hợp',
            'Quấy rối',
            'Lừa đảo',
          ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => reason = v!),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: details,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Mô tả và bằng chứng liên quan',
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          'Gửi báo cáo',
          busy: f.busy,
          onTap: f.busy
              ? null
              : () async {
                  await f.perform(() async {
                    final record = await widget.state.workflows.report(
                      widget.targetType,
                      widget.targetId,
                      reason,
                      details.text,
                    );
                    if (mounted) {
                      setState(() => receipt = record.id);
                    }
                  });
                },
        ),
      ],
    ],
  );
}

class MyReportsScreen extends StatelessWidget {
  final AppState state;
  const MyReportsScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) => FlowPage(
    state: state,
    title: 'Báo cáo của tôi',
    content: (ctx, f) => [
      if (!state.store.reports.any((r) => r.reporterId == state.userId))
        const EmptyState(
          'Chưa có báo cáo',
          'Báo cáo từ phòng, hồ sơ hoặc hội thoại sẽ xuất hiện ở đây.',
        ),
      for (final r in state.store.reports.where(
        (r) => r.reporterId == state.userId,
      ))
        flowCard('${r.id} • ${r.status}', [
          Text(r.reason),
          Text(r.details),
          ...r.history.map(Text.new),
        ]),
    ],
  );
}
