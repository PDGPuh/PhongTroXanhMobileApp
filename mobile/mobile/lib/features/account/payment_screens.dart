import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/http_payment_repository.dart';
import '../../app/app_state.dart';
import '../../app/navigation.dart';
import '../../core/flow_page.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/models.dart';
import '../../domain/workflow_models.dart';

String _formatVND(num amount) {
  final s = amount.toInt().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return '${buffer.toString()}đ';
}

class PackagesScreen extends StatefulWidget {
  final AppState? state;
  const PackagesScreen({super.key, this.state});
  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  bool yearly = false;
  String? priorityPersonId;
  List<ServicePlan>? loadedPlans;
  ConsumableBalanceDTO? consumableBalance;
  List<ActiveSubscriptionDTO> activeSubscriptions = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPlansAndBalance();
  }

  Future<void> _fetchPlansAndBalance() async {
    final s = widget.state ?? AppScope.maybeOf(context)?.state;
    if (s == null) return;
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        s.paymentRepository.getPlans().catchError((_) => <PackagePlanDTO>[]),
        s.paymentRepository.getMyConsumables().then((v) => v as dynamic).catchError((_) => null),
        s.paymentRepository.getMySubscriptions().catchError((_) => <ActiveSubscriptionDTO>[]),
      ]);

      final planDtos = results[0] as List<PackagePlanDTO>;
      final cons = results[1] as ConsumableBalanceDTO?;
      final subs = results[2] as List<ActiveSubscriptionDTO>;

      if (planDtos.isNotEmpty && mounted) {
        final converted = planDtos.map((dto) {
          final isLandlord = dto.targetRole.toUpperCase() == 'LANDLORD';
          final feats = <String>[];
          if (dto.swipesPerDay > 0) {
            feats.add('${dto.swipesPerDay} lượt quẹt mỗi ngày');
          }
          if (dto.boosts > 0) {
            feats.add('Tặng ${dto.boosts} lượt đẩy ${isLandlord ? 'tin phòng VIP' : 'hồ sơ'} (24h/lượt)');
          }
          if (dto.priceMonthly == 0) {
            feats.add('Tìm kiếm và khám phá phòng trọ miễn phí');
          } else if (isLandlord) {
            feats.add('Tiếp cận người thuê tiềm năng nhanh chóng');
            feats.add('Hỗ trợ ưu tiên duyệt tin & quản lý hợp đồng');
          } else {
            feats.add('Bộ lọc lối sống và bạn ở cùng chi tiết');
            feats.add('Ưu tiên ghép đôi & xem ai đã thích');
          }

          return ServicePlan(
            dto.id,
            dto.name,
            dto.priceMonthly.toInt(),
            dto.priceMonthly == 0
                ? 'Gói khởi đầu cơ bản'
                : 'Nâng cấp quyền lợi và tăng tốc kết nối',
            yearly: dto.priceYearly.toInt(),
            extraSwipes: dto.swipesPerDay,
            boosts: dto.boosts,
            landlord: isLandlord,
            features: feats,
          );
        }).toList();

        setState(() {
          loadedPlans = converted;
          consumableBalance = cons;
          activeSubscriptions = subs;
        });
      }
    } catch (_) {
      // Fallback silently to offline catalog
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state ?? AppScope.maybeOf(context)!.state;
    final plansToDisplay = loadedPlans ?? s.store.plans;
    final isLandlord = s.role == UserRole.landlord;

    return FlowPage(
      state: s,
      title: 'Gói dịch vụ',
      content: (ctx, f) {
        final p = s.store.profiles[s.userId]!;
        final activeSub = activeSubscriptions.firstOrNull;

        return [
          flowCard('Gói hiện tại: ${activeSub?.planName ?? p.package}', [
            if (activeSub?.endDate != null)
              Text('Hết hạn: ${activeSub!.endDate!.substring(0, 10)}')
            else if (p.packageExpiry != null)
              Text('Hết hạn: ${p.packageExpiry!.toString().substring(0, 10)}'),
            Text(
              'Lượt Boost: ${consumableBalance?.boostsLeft ?? p.boosts} • Super Match: ${p.superMatches}',
            ),
            Text(
              s.unlimitedSwipes
                  ? 'Khám phá và ghép bạn: Không giới hạn trong thời hạn gói'
                  : 'Lượt khám phá hôm nay: ${consumableBalance?.swipesLeft ?? s.roomQuota}',
            ),
            if (p.packageExpiry != null &&
                p.packageExpiry!.isBefore(DateTime.now()) &&
                activeSub == null)
              const Text('Gói đã hết hạn. Quyền lợi trở về gói miễn phí.'),
            if (p.boostedAt != null)
              Text(
                'Đã dùng Boost gần nhất: ${p.boostedAt!.toString().substring(0, 16)}',
              ),
          ]),
          if (isLandlord)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Thanh toán theo năm (tiết kiệm hơn)'),
              value: yearly,
              onChanged: (v) => setState(() => yearly = v),
            ),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            ),
          for (final plan in plansToDisplay.where(
            (p) => p.landlord == isLandlord,
          )) ...[
            Builder(
              builder: (c) {
                final isCurrent = activeSub?.planId == plan.id ||
                    (plan.id == 'FREE' && activeSub == null && p.package == 'FREE');
                final isFree = plan.monthly == 0;
                final price = yearly ? plan.yearly : plan.monthly;

                return flowCard(
                  plan.name,
                  [
                    Row(
                      children: [
                        if (!isFree)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(
                              LucideIcons.crown,
                              size: 20,
                              color: Colors.amber,
                            ),
                          ),
                        Text(
                          isFree
                              ? 'Miễn phí'
                              : '${_formatVND(price)}${yearly ? '/năm' : '/tháng'}',
                          style: PT.title(24).copyWith(
                            color: isFree ? PT.deep : PT.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isCurrent) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: PT.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Đang dùng',
                              style: PT.caption(PT.green).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(plan.description, style: PT.body(14, PT.muted)),
                    if (plan.features.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      for (final feat in plan.features)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Icon(
                                  LucideIcons.check,
                                  size: 15,
                                  color: PT.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(feat, style: PT.body(13, PT.deep)),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 16),
                    if (isFree)
                      PrimaryButton(
                        isCurrent ? 'Gói hiện tại' : 'Gói mặc định',
                        outline: true,
                        onTap: null,
                      )
                    else
                      PrimaryButton(
                        'Thanh toán PayOS - ${plan.name}',
                        onTap: () => openPage(
                          ctx,
                          CheckoutScreen(state: s, plan: plan, yearly: yearly),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          if (p.boosts > 0)
            PrimaryButton(
              'Dùng 1 lượt Boost ${isLandlord ? 'đẩy tin' : 'hồ sơ'}',
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
              'Dùng 1 lượt Super Match',
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
            'Hỗ trợ thanh toán bảo mật tức thì qua cổng PayOS (VietQR, Napas, Mobile Banking).',
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
  CreatePaymentResponseDTO? payOsResponse;
  String? paymentStatus;
  bool isCheckingStatus = false;

  int get amount => widget.yearly ? widget.plan.yearly : widget.plan.monthly;

  Future<void> _initiatePayOsPayment(FlowPageState f) async {
    await f.perform(() async {
      final res = await widget.state.paymentRepository.createPayment(
        packageId: widget.plan.id,
        paymentMethod: 'PAYOS',
      );
      if (mounted) {
        setState(() {
          payOsResponse = res;
          paymentStatus = 'PENDING';
        });
      }
    });
  }

  Future<void> _checkPaymentResult(FlowPageState f) async {
    if (payOsResponse == null) return;
    setState(() => isCheckingStatus = true);
    try {
      final result = await widget.state.paymentRepository.getPaymentResult(
        payOsResponse!.transactionCode,
      );
      final status = result['status']?.toUpperCase() ?? 'PENDING';
      if (mounted) {
        setState(() {
          paymentStatus = status;
        });
        if (status == 'SUCCESS') {
          // Update local state profile
          final p = widget.state.store.profiles[widget.state.userId];
          if (p != null) {
            p.package = widget.plan.name;
            p.packageExpiry = DateTime.now().add(
              Duration(days: widget.yearly ? 365 : 30),
            );
            p.boosts += widget.plan.boosts;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thanh toán thành công! Gói dịch vụ đã được kích hoạt.'),
              backgroundColor: PT.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Trạng thái hiện tại: $status. Vui lòng thử lại sau vài giây.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chưa thể kiểm tra trạng thái: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isCheckingStatus = false);
    }
  }

  Future<void> _openPayOsCheckoutUrl() async {
    final url = payOsResponse?.paymentUrl;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) => FlowPage(
    state: widget.state,
    title: 'Thanh toán gói dịch vụ',
    content: (ctx, f) => [
      flowCard(widget.plan.name, [
        Row(
          children: [
            const Icon(LucideIcons.crown, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text(
              _formatVND(amount),
              style: PT.title(28).copyWith(color: PT.green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.yearly ? 'Thời hạn: 12 tháng (1 năm)' : 'Thời hạn: 30 ngày (1 tháng)',
          style: PT.body(14, PT.muted),
        ),
        const SizedBox(height: 6),
        Text(widget.plan.description),
      ]),
      const SizedBox(height: 12),

      if (payOsResponse == null) ...[
        flowCard('Phương thức thanh toán', [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PT.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PT.green.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PT.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.qrCode, color: PT.green, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cổng thanh toán PayOS',
                        style: PT.body(15).copyWith(fontWeight: FontWeight.bold, color: PT.deep),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Quét mã VietQR, chuyển khoản nhanh 24/7 mọi ngân hàng',
                        style: PT.body(13, PT.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.circleCheck, color: PT.green, size: 22),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 16),
        PrimaryButton(
          'Tạo mã thanh toán PayOS',
          busy: f.busy,
          onTap: f.busy ? null : () => _initiatePayOsPayment(f),
        ),
      ] else ...[
        // Giao diện thanh toán PayOS trực quan
        flowCard('Thông tin thanh toán PayOS', [
          Text(
            'Mã đơn hàng: ${payOsResponse!.transactionCode}',
            style: PT.title(16).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Số tiền cần thanh toán: ${_formatVND(payOsResponse!.amount > 0 ? payOsResponse!.amount : amount)}',
            style: PT.title(18).copyWith(color: PT.green, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Builder(
                  builder: (ctx) {
                    final qrData = (payOsResponse!.qrCode != null && payOsResponse!.qrCode!.isNotEmpty)
                        ? payOsResponse!.qrCode!
                        : payOsResponse!.paymentUrl;
                    if (qrData.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: PT.line),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: qrData,
                            size: 200,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mở app ngân hàng bất kỳ để quét mã VietQR',
                          style: PT.caption(PT.muted),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            'Mở trang thanh toán PayOS',
            onTap: _openPayOsCheckoutUrl,
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            isCheckingStatus ? 'Đang kiểm tra...' : 'Kiểm tra kết quả giao dịch',
            outline: true,
            busy: isCheckingStatus,
            onTap: isCheckingStatus ? null : () => _checkPaymentResult(f),
          ),
          if (paymentStatus == 'SUCCESS') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PT.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.circleCheck, color: PT.green, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Giao dịch thành công! Gói ${widget.plan.name} đã được kích hoạt.',
                      style: PT.body(14, PT.green).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Hỗ trợ mô phỏng test nếu môi trường dev chưa thanh toán tiền thật
          TextButton(
            onPressed: () async {
              await f.perform(() async {
                final p = widget.state.store.profiles[widget.state.userId];
                if (p != null) {
                  p.package = widget.plan.name;
                  p.packageExpiry = DateTime.now().add(
                    Duration(days: widget.yearly ? 365 : 30),
                  );
                  p.boosts += widget.plan.boosts;
                }
                if (mounted) {
                  setState(() => paymentStatus = 'SUCCESS');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã kích hoạt gói thành công (Chế độ mô phỏng)')),
                  );
                }
              });
            },
            child: const Text('Mô phỏng thanh toán thành công (Test Dev)'),
          ),
          TextButton(
            onPressed: () => setState(() => payOsResponse = null),
            child: const Text('Hủy / Quay lại chọn gói khác'),
          ),
        ]),
      ],
    ],
  );
}

class PaymentHistoryScreen extends StatefulWidget {
  final AppState state;
  const PaymentHistoryScreen({super.key, required this.state});
  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<TransactionDTO>? serverTransactions;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => isLoading = true);
    try {
      final txs = await widget.state.paymentRepository.getMyTransactions();
      if (mounted) setState(() => serverTransactions = txs);
    } catch (_) {
      // Keep store orders fallback
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => FlowPage(
    state: widget.state,
    title: 'Lịch sử giao dịch',
    content: (ctx, f) {
      final localOrders = widget.state.store.orders
          .where((o) => o.userId == widget.state.userId)
          .toList()
          .reversed;

      final hasServerData = serverTransactions != null && serverTransactions!.isNotEmpty;
      final hasLocalData = localOrders.isNotEmpty;

      return [
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          ),
        if (!isLoading && !hasServerData && !hasLocalData)
          const EmptyState(
            'Chưa có giao dịch',
            'Các giao dịch nạp tiền và mua gói qua PayOS sẽ hiển thị tại đây.',
          ),
        if (hasServerData) ...[
          Text('Giao dịch trực tuyến (PayOS)', style: PT.title(16)),
          const SizedBox(height: 8),
          for (final tx in serverTransactions!)
            flowCard('${tx.transactionCode} • ${_renderStatusText(tx.status)}', [
              Text('Gói dịch vụ: ${tx.packageId}'),
              Text(
                'Số tiền: ${_formatVND(tx.amount)} • Cổng: ${tx.paymentMethod}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (tx.createdAt != null)
                Text('Thời gian: ${tx.createdAt!.substring(0, 16)}', style: PT.caption(PT.muted)),
            ]),
          const SizedBox(height: 16),
        ],
        if (hasLocalData) ...[
          Text('Giao dịch trên thiết bị', style: PT.title(16)),
          const SizedBox(height: 8),
          for (final o in localOrders)
            flowCard('${o.id} • ${o.status}', [
              Text(o.plan.name),
              Text('${_formatVND(o.amount)} • ${o.method}'),
              Text(o.createdAt.toString().substring(0, 16)),
            ]),
        ],
      ];
    },
  );

  String _renderStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return 'Thành công';
      case 'PENDING':
        return 'Chờ thanh toán';
      case 'FAILED':
        return 'Thất bại';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}
