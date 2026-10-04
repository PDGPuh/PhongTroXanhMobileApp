import 'package:flutter/foundation.dart';

enum ResourcePhase { idle, loading, ready, empty, error }

enum DemoFault { none, offline, server, denied, missing }

class RepositoryFailure implements Exception {
  final DemoFault kind;
  final String message;
  const RepositoryFailure(this.kind, this.message);
  @override
  String toString() => message;
}

/// Injected only in demo/test repositories. No fallback is applied after errors.
class DemoTransport {
  Duration delay;
  DemoFault fault;
  DemoTransport({
    this.delay = const Duration(milliseconds: 250),
    this.fault = DemoFault.none,
  });
  Future<T> run<T>(T Function() operation) async {
    await Future<void>.delayed(delay);
    switch (fault) {
      case DemoFault.offline:
        throw const RepositoryFailure(
          DemoFault.offline,
          'Không có kết nối. Kiểm tra mạng và thử lại.',
        );
      case DemoFault.server:
        throw const RepositoryFailure(
          DemoFault.server,
          'Không thể xử lý yêu cầu. Vui lòng thử lại.',
        );
      case DemoFault.denied:
        throw const RepositoryFailure(
          DemoFault.denied,
          'Bạn không có quyền thực hiện thao tác này.',
        );
      case DemoFault.missing:
        throw const RepositoryFailure(
          DemoFault.missing,
          'Không tìm thấy dữ liệu này.',
        );
      case DemoFault.none:
        return operation();
    }
  }
}

class AsyncResource<T> extends ChangeNotifier {
  ResourcePhase phase = ResourcePhase.idle;
  T? data;
  RepositoryFailure? error;
  int _revision = 0;
  bool _closed = false;

  Future<void> load(
    Future<T> Function() fetch, {
    bool Function(T)? isEmpty,
  }) async {
    if (_closed) return;
    final revision = ++_revision;
    phase = ResourcePhase.loading;
    error = null;
    notifyListeners();
    try {
      final result = await fetch();
      if (_closed || revision != _revision) return;
      data = result;
      phase = isEmpty?.call(result) == true
          ? ResourcePhase.empty
          : ResourcePhase.ready;
    } catch (e) {
      if (_closed || revision != _revision) return;
      // Hide stale content after an error; callers must explicitly retry.
      data = null;
      error = e is RepositoryFailure
          ? e
          : const RepositoryFailure(DemoFault.server, 'Không thể tải dữ liệu.');
      phase = ResourcePhase.error;
    }
    notifyListeners();
  }

  void clear() {
    if (_closed) return;
    _revision++;
    data = null;
    error = null;
    phase = ResourcePhase.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    _revision++;
    super.dispose();
  }
}
