import 'package:flutter/foundation.dart';

enum ResourcePhase { idle, loading, ready, empty, error }

enum RepositoryFault { none, offline, server, denied, missing }

class RepositoryFailure implements Exception {
  final RepositoryFault kind;
  final String message;
  const RepositoryFailure(this.kind, this.message);
  @override
  String toString() => message;
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
          : const RepositoryFailure(
              RepositoryFault.server,
              'Không thể tải dữ liệu.',
            );
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
