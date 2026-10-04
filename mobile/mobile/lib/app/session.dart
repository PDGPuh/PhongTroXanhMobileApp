import 'package:flutter/foundation.dart';

import '../core/async_resource.dart';
import '../domain/models.dart';

class SessionUser {
  final String id, email, name, phone;
  final UserRole role;
  const SessionUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone = '',
  });
}

abstract interface class AuthRepository {
  Future<SessionUser> signIn(String login, String password);
  Future<SessionUser> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  });
}

/// Preview-only capability, implemented by the mock adapter.
abstract interface class DemoSessionProvider {
  SessionUser userForRole(UserRole role);
}

class SessionController extends ChangeNotifier {
  final AuthRepository repository;
  SessionUser? user;
  bool busy = false;
  String? error;
  int _revision = 0;
  bool _closed = false;
  SessionController(this.repository);
  bool get authenticated => user != null;
  int get revision => _revision;
  Future<bool> signIn(String login, String password) =>
      _request(() => repository.signIn(login, password));
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) => _request(
    () => repository.register(
      email: email,
      password: password,
      name: name,
      phone: phone,
    ),
  );
  Future<bool> _request(Future<SessionUser> Function() operation) async {
    if (_closed || busy) return false;
    final revision = ++_revision;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = await operation();
      if (_closed || revision != _revision) return false;
      user = result;
    } catch (e) {
      if (_closed || revision != _revision) return false;
      error = e is RepositoryFailure
          ? e.message
          : 'Không thể đăng nhập. Thử lại sau.';
    }
    busy = false;
    notifyListeners();
    return error == null;
  }

  void startDemo(UserRole role) {
    _revision++;
    final provider = repository;
    if (provider is! DemoSessionProvider) {
      throw StateError('This auth repository does not support demo sessions.');
    }
    user = (provider as DemoSessionProvider).userForRole(role);
    busy = false;
    error = null;
    notifyListeners();
  }

  void logout() {
    _revision++;
    user = null;
    busy = false;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    _revision++;
    super.dispose();
  }
}
