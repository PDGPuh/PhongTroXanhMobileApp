import 'package:flutter/material.dart';

import '../app/app_state.dart';
import 'async_resource.dart';
import 'device_media.dart';
import 'theme.dart';
import 'widgets.dart';

typedef FlowBuilder = List<Widget> Function(BuildContext, FlowPageState);

class FlowPage extends StatefulWidget {
  final AppState state;
  final String title;
  final FlowBuilder content;
  const FlowPage({
    super.key,
    required this.state,
    required this.title,
    required this.content,
  });
  @override
  State<FlowPage> createState() => FlowPageState();
}

class FlowPageState extends State<FlowPage> {
  bool loading = true, busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    final ok = await perform(
      () => widget.state.workflows.run('load-${widget.title}', () => true),
    );
    if (mounted) {
      setState(() => loading = !ok);
    }
  }

  Future<bool> perform(Future<dynamic> Function() action) async {
    if (!mounted || busy) return false;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
      return true;
    } on MediaFailure catch (e) {
      if (mounted) setState(() => error = e.message);
      return false;
    } on RepositoryFailure catch (e) {
      if (mounted) {
        setState(() => error = e.message);
      }
      return false;
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Không thể hoàn tất. Vui lòng thử lại.');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => BasicPage(
    title: widget.title,
    child: ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) => loading
          ? Center(
              child: error == null
                  ? RepaintBoundary(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.8,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: PT.card(color: const Color(0xFFF7FAF9)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 14,
                                    width: 140,
                                    decoration: BoxDecoration(
                                      color: PT.mint,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    height: 11,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: PT.grey,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(error!, style: PT.body(15, PT.error)),
                          const SizedBox(height: 16),
                          PrimaryButton('Thử lại', onTap: busy ? null : load),
                        ],
                      ),
                    ),
            )
          : ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              children: [
                if (error != null)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(error!, style: PT.body(14, PT.error)),
                    ),
                  ),
                ...widget.content(context, this),
              ],
            ),
    ),
  );
}

Widget flowCard(String title, List<Widget> children) => Container(
  padding: const EdgeInsets.all(12),
  margin: const EdgeInsets.only(bottom: 10),
  decoration: PT.card(),
  child: Material(
    color: Colors.transparent,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: PT.title(17)),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  ),
);

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String text,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: PT.title(20)),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Quay lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    ) ??
    false;

class DemoDocumentPreview extends StatelessWidget {
  final String side;
  const DemoDocumentPreview({super.key, required this.side});
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 96),
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: PT.card(color: PT.mint),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.badge_outlined, size: 30, color: PT.green),
        Text('$side • Tài liệu mẫu', style: PT.title(15)),
        const Text('DEMO — không chứa danh tính thật'),
      ],
    ),
  );
}
