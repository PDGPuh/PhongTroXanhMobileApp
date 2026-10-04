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
                  ? const CircularProgressIndicator()
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
              padding: const EdgeInsets.all(20),
              children: [
                if (error != null)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(error!, style: PT.body(15, PT.error)),
                    ),
                  ),
                ...widget.content(context, this),
              ],
            ),
    ),
  );
}

Widget flowCard(String title, List<Widget> children) => Container(
  padding: const EdgeInsets.all(16),
  margin: const EdgeInsets.only(bottom: 14),
  decoration: PT.card(),
  child: Material(
    color: Colors.transparent,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: PT.title(22)),
        const SizedBox(height: 12),
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
        title: Text(title, style: PT.title(23)),
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
    constraints: const BoxConstraints(minHeight: 140),
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: PT.card(color: PT.mint),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.badge_outlined, size: 40, color: PT.green),
        Text('$side • Tài liệu mẫu', style: PT.title(18)),
        const Text('DEMO — không chứa danh tính thật'),
      ],
    ),
  );
}
