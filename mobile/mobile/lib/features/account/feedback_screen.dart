import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/flow_page.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../api/http_review_repository.dart';

class SystemFeedbackScreen extends StatefulWidget {
  final AppState state;
  const SystemFeedbackScreen({super.key, required this.state});

  @override
  State<SystemFeedbackScreen> createState() => _SystemFeedbackScreenState();
}

class _SystemFeedbackScreenState extends State<SystemFeedbackScreen> {
  final comment = TextEditingController();
  int rating = 5;
  String category = 'Giao diện & Trải nghiệm';
  bool _loading = false;
  bool _submitting = false;
  SystemFeedbackDTO? _existing;

  final categories = [
    'Giao diện & Trải nghiệm',
    'Tìm kiếm & Khám phá',
    'Đặt thuê & Hợp đồng',
    'Ghép & Hoán đổi phòng',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _loadMyFeedback();
  }

  Future<void> _loadMyFeedback() async {
    if (!widget.state.authenticated) return;
    setState(() => _loading = true);
    try {
      final fb = await widget.state.reviewRepository.getMySystemFeedback();
      if (fb != null && mounted) {
        setState(() {
          _existing = fb;
          rating = fb.rating;
          category = fb.category.isNotEmpty ? fb.category : categories.first;
          comment.text = fb.comment;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FlowPage(
    state: widget.state,
    title: 'Góp ý hệ thống',
    content: (ctx, f) => [
      if (_loading)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        )
      else ...[
        Text(
          'Đánh giá & Góp ý nền tảng',
          style: PT.title(24),
        ),
        const SizedBox(height: 6),
        Text(
          _existing != null
              ? 'Bạn đã gửi đánh giá trước đó. Bạn có thể cập nhật nội dung bất cứ lúc nào.'
              : 'Ý kiến đóng góp của bạn giúp Phòng Trọ Xanh ngày càng hoàn thiện hơn.',
          style: PT.body(14, PT.muted),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => IconButton(
              iconSize: 40,
              icon: Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: PT.green,
              ),
              onPressed: f.busy || _submitting
                  ? null
                  : () => setState(() => rating = i + 1),
            ),
          ),
        ),
        Center(
          child: Text(
            '$rating / 5 sao',
            style: PT.body(16, PT.green).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: categories.contains(category) ? category : categories.first,
          decoration: const InputDecoration(labelText: 'Chủ đề góp ý'),
          items: categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: f.busy || _submitting
              ? null
              : (v) => setState(() => category = v ?? categories.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: comment,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Nội dung nhận xét hoặc đề xuất',
            hintText: 'Hãy chia sẻ cảm nhận hoặc các tính năng bạn muốn cải thiện...',
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          _existing != null ? 'Cập nhật góp ý' : 'Gửi góp ý',
          busy: f.busy || _submitting,
          onTap: f.busy || _submitting
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(ctx);
                  final navigator = Navigator.of(ctx);
                  if (comment.text.trim().isEmpty) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập nội dung nhận xét.'),
                        backgroundColor: PT.error,
                      ),
                    );
                    return;
                  }
                  setState(() => _submitting = true);
                  try {
                    final res = await widget.state.reviewRepository.createSystemFeedback(
                      rating: rating,
                      category: category,
                      comment: comment.text.trim(),
                    );
                    if (mounted) {
                      setState(() {
                        _existing = res;
                        _submitting = false;
                      });
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Gửi đánh giá hệ thống thành công! Cảm ơn bạn đã đóng góp.'),
                          backgroundColor: PT.green,
                        ),
                      );
                      navigator.pop();
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _submitting = false);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: PT.error,
                        ),
                      );
                    }
                  }
                },
        ),
      ],
    ],
  );
}
