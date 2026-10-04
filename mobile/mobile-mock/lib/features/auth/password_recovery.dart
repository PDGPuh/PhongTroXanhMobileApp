import 'package:flutter/foundation.dart';

import '../../core/async_resource.dart';

abstract interface class PasswordRecoveryRepository {
  Future<void> sendOtp(String email);
  Future<String> verifyOtp(String email, String code);
  Future<void> resetPassword(String token, String password);
}

/// The UI follows the active web's four steps. The verified token stays in
/// memory and is invalidated on email changes, resend and completion.
class PasswordRecoveryController extends ChangeNotifier {
  final PasswordRecoveryRepository repository;
  final DateTime Function() now;
  int step = 0;
  String email = '';
  String? error, _token;
  DateTime? resendAt;
  bool busy = false, _closed = false;
  int _revision = 0;
  PasswordRecoveryController(this.repository, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  int get resendSeconds {
    final ms = resendAt?.difference(now()).inMilliseconds ?? 0;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  Future<bool> send(String address) async {
    if (busy || (step == 1 && resendSeconds > 0)) return false;
    final normalized = address.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
      error = 'Nhập email hợp lệ.';
      notifyListeners();
      return false;
    }
    return _run(() async {
      await repository.sendOtp(normalized);
      email = normalized;
      _token = null;
      resendAt = now().add(const Duration(seconds: 60));
      step = 1;
    });
  }

  Future<bool> verify(String code) => _run(() async {
    if (step != 1 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const RepositoryFailure(DemoFault.denied, 'Nhập đủ 6 chữ số OTP.');
    }
    final token = await repository.verifyOtp(email, code);
    _token = token;
    step = 2;
  });
  Future<bool> reset(String password, String confirmation) => _run(() async {
    if (step != 2 || _token == null) {
      throw const RepositoryFailure(
        DemoFault.denied,
        'Xác minh OTP trước khi đổi mật khẩu.',
      );
    }
    if (password.length < 6 || password != confirmation) {
      throw const RepositoryFailure(
        DemoFault.denied,
        'Kiểm tra mật khẩu mới và xác nhận.',
      );
    }
    await repository.resetPassword(_token!, password);
    _token = null;
    step = 3;
  });
  Future<bool> _run(Future<void> Function() action) async {
    if (_closed || busy) return false;
    busy = true;
    error = null;
    final revision = ++_revision;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      if (!_closed && revision == _revision) {
        error = e is RepositoryFailure
            ? e.message
            : 'Không thể kết nối. Vui lòng thử lại.';
      }
    }
    if (_closed || revision != _revision) return false;
    busy = false;
    notifyListeners();
    return error == null;
  }

  void changeEmail() {
    if (busy) return;
    _revision++;
    _token = null;
    step = 0;
    error = null;
    resendAt = null;
    notifyListeners();
  }

  void back() {
    if (busy) return;
    if (step == 2) {
      _token = null;
      step = 1;
      error = null;
      notifyListeners();
    } else if (step == 1) {
      changeEmail();
    }
  }

  @override
  void dispose() {
    _closed = true;
    _revision++;
    super.dispose();
  }
}
