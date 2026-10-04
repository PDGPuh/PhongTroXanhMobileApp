import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../core/flow_page.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../domain/workflow_models.dart';

class PackagesScreen extends StatefulWidget {
  final AppState? state;
  const PackagesScreen({super.key, this.state});
  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  bool yearly = false;
  String? priorityPersonId;
  @override
  Widget build(BuildContext context) {
    final s = widget.state ?? AppScope.maybeOf(context)!.state;
    return FlowPage(
      state: s,
      title: 'Gói dịch vụ',
      content: (ctx, f) {
        final p = s.store.profiles[s.userId]!;
        return [
          flowCard('Gói hiện tại: ${p.package}', [
            if (p.packageExpiry != null)
              Text('Hết hạn: ${p.packageExpiry!.toString().substring(0, 10)}'),
            Text('Boost: ${p.boosts} • Super Match: ${p.superMatches}'),
            Text(
              s.unlimitedSwipes
                  ? 'Khám phá và ghép bạn: không giới hạn trong thời hạn gói'
                  : 'Lượt khám phá còn lại: ${s.roomQuota}',
            ),
            if (p.packageExpiry != null &&
                p.packageExpiry!.isBefore(DateTime.now()))
              const Text('Gói đã hết hạn. Quyền vuốt trở về gói miễn phí.'),
            if (p.boostedAt != null)
              Text(
                'Đã dùng Boost demo: ${p.boostedAt!.toString().substring(0, 16)}',
              ),
          ]),
          if (s.role == UserRole.landlord)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Thanh toán theo năm'),
              value: yearly,
              onChanged: (v) => setState(() => yearly = v),
            ),
          for (final plan in ServicePlan.catalog.where(
            (p) => p.landlord == (s.role == UserRole.landlord),
          ))
            flowCard(plan.name, [
              Text(
                '${yearly ? plan.yearly : plan.monthly}đ${yearly ? '/năm' : (['plus', 'gold', 'owner-pro', 'owner-premium'].contains(plan.id) ? '/tháng' : '')}',
                style: PT.title(25).copyWith(color: PT.green),
              ),
              Text(plan.description),
              const SizedBox(height: 16),
              PrimaryButton(
                'Chọn ${plan.name}',
                onTap: () => openPage(
                  ctx,
                  CheckoutScreen(state: s, plan: plan, yearly: yearly),
                ),
              ),
            ]),
          if (p.boosts > 0)
            PrimaryButton(
              'Dùng 1 lượt Boost demo',
              onTap: f.busy
                  ? null
                  : () => f.perform(() => s.workflows.consume('BOOST', null)),
            ),
          const SizedBox(height: 12),
          if (p.superMatches > 0) ...[
            DropdownButtonFormField<String>(
              initialValue: priorityPersonId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Hồ sơ gửi Super Match',
              ),
              items: s.people
                  .where((person) => !p.priorityPeople.contains(person.id))
                  .map(
                    (person) => DropdownMenuItem(
                      value: person.id,
                      child: Text(person.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => priorityPersonId = v),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              'Dùng 1 lượt Super Match demo',
              onTap: f.busy || priorityPersonId == null
                  ? null
                  : () async {
                      await f.perform(() async {
                        await s.workflows.consume('SUPER', priorityPersonId);
                        if (mounted) setState(() => priorityPersonId = null);
                      });
                    },
            ),
            const Text(
              'Gửi lời thích ưu tiên cho hồ sơ đã chọn. Match vẫn cần phản hồi hai chiều.',
            ),
          ],
          const SizedBox(height: 12),
          PrimaryButton(
            'Lịch sử giao dịch',
            outline: true,
            onTap: () => openPage(ctx, PaymentHistoryScreen(state: s)),
          ),
          const SizedBox(height: 14),
          Text(
            'Giao dịch mô phỏng không trừ tiền thật. Quyền lợi được giữ trong lần chạy hiện tại.',
            style: PT.body(12, PT.muted),
          ),
        ];
      },
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  final AppState state;
  final ServicePlan plan;
  final bool yearly;
  const CheckoutScreen({
    super.key,
    required this.state,
    required this.plan,
    this.yearly = false,
  });
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String method = 'MoMo';
  PaymentOrder? order;
  @override
  Widget build(BuildContext context) => FlowPage(
    state: widget.state,
    title: 'Xác nhận gói',
    content: (ctx, f) => [
      flowCard(widget.plan.name, [
        Text(
          '${widget.yearly ? widget.plan.yearly : widget.plan.monthly}đ',
          style: PT.title(28).copyWith(color: PT.green),
        ),
        Text(widget.yearly ? 'Thanh toán 12 tháng' : 'Theo lựa chọn gói'),
        Text(widget.plan.description),
      ]),
      const Text('Cổng thanh toán mô phỏng • không trừ tiền thật'),
      const SizedBox(height: 16),
      if (order == null) ...[
        DropdownButtonFormField<String>(
          initialValue: method,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Phương thức'),
          items: [
            'MoMo',
            'Ngân hàng',
            'Thẻ',
          ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => method = v!),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          'Tạo giao dịch demo',
          busy: f.busy,
          onTap: f.busy
              ? null
              : () async {
                  await f.perform(() async {
                    final o = await widget.state.workflows.checkout(
                      widget.plan,
                      widget.yearly,
                      method,
                    );
                    if (mounted) {
                      setState(() => order = o);
                    }
                  });
                },
        ),
      ] else ...[
        Text('${order!.id} • ${order!.status}', style: PT.title(22)),
        Text('Phương thức: ${order!.method}'),
        const SizedBox(height: 16),
        if (order!.status == 'Chờ thanh toán') ...[
          PrimaryButton(
            'Mô phỏng thanh toán thành công',
            busy: f.busy,
            onTap: f.busy
                ? null
                : () => f.perform(
                    () => widget.state.workflows.paymentResult(
                      order!.id,
                      'Thành công',
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            'Mô phỏng thất bại',
            outline: true,
            onTap: f.busy
                ? null
                : () => f.perform(
                    () => widget.state.workflows.paymentResult(
                      order!.id,
                      'Thất bại',
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            'Hủy giao dịch',
            outline: true,
            onTap: f.busy
                ? null
                : () => f.perform(
                    () => widget.state.workflows.paymentResult(
                      order!.id,
                      'Đã hủy',
                    ),
                  ),
          ),
        ] else ...[
          Icon(
            order!.status == 'Thành công'
                ? LucideIcons.circleCheck
                : LucideIcons.circleX,
            color: PT.green,
            size: 52,
          ),
          const SizedBox(height: 16),
          Text(
            order!.status == 'Thành công'
                ? 'Quyền lợi demo đã cập nhật một lần theo mã giao dịch.'
                : 'Giao dịch chưa kích hoạt quyền lợi. Bạn có thể tạo giao dịch mới.',
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            'Xem lịch sử giao dịch',
            outline: true,
            onTap: () =>
                openPage(ctx, PaymentHistoryScreen(state: widget.state)),
          ),
          const SizedBox(height: 12),
          PrimaryButton('Chọn gói khác', onTap: () => Navigator.pop(ctx)),
        ],
      ],
    ],
  );
}

class PaymentHistoryScreen extends StatelessWidget {
  final AppState state;
  const PaymentHistoryScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) => FlowPage(
    state: state,
    title: 'Lịch sử giao dịch',
    content: (ctx, f) => [
      if (!state.store.orders.any((o) => o.userId == state.userId))
        const EmptyState(
          'Chưa có giao dịch',
          'Giao dịch của tài khoản này sẽ xuất hiện tại đây.',
        ),
      for (final o
          in state.store.orders
              .where((o) => o.userId == state.userId)
              .toList()
              .reversed)
        flowCard('${o.id} • ${o.status}', [
          Text(o.plan.name),
          Text('${o.amount}đ • ${o.method}'),
          Text(o.createdAt.toString().substring(0, 16)),
          const Text('Giao dịch demo'),
          if (o.status == 'Chờ thanh toán') ...[
            const SizedBox(height: 12),
            PrimaryButton(
              'Mô phỏng thanh toán thành công',
              onTap: f.busy
                  ? null
                  : () => f.perform(
                      () => state.workflows.paymentResult(o.id, 'Thành công'),
                    ),
            ),
            TextButton(
              onPressed: f.busy
                  ? null
                  : () => f.perform(
                      () => state.workflows.paymentResult(o.id, 'Đã hủy'),
                    ),
              child: const Text('Hủy giao dịch'),
            ),
          ],
        ]),
    ],
  );
}
