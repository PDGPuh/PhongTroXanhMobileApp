import 'package:flutter/foundation.dart';

import '../core/async_resource.dart';
import '../demo/models.dart';
import '../features/auth/password_recovery.dart';

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

class DemoAuthRepository implements AuthRepository, PasswordRecoveryRepository {
  final Set<String> unavailable;
  final bool Function(String)? isUnavailable;
  final DemoTransport transport;
  final Map<String, ({SessionUser user, String password})> _accounts = {};
  final Map<String, ({String code, DateTime expiry, DateTime resendAt})> _otp =
      {};
  final Map<String, ({String email, DateTime expiry})> _resetTokens = {};
  final DateTime Function() now;
  int _otpSequence = 0;
  static const accounts = [
    SessionUser(
      id: 'tenant-a',
      email: 'tenant@demo.vn',
      name: 'Nguyễn Hoài An',
      role: UserRole.tenant,
      phone: '0901000001',
    ),
    SessionUser(
      id: 'tenant-b',
      email: 'tenant2@demo.vn',
      name: 'Lê Thu Hà',
      role: UserRole.tenant,
      phone: '0901000002',
    ),
    SessionUser(
      id: 'owner-a',
      email: 'landlord@demo.vn',
      name: 'Cô Hồng',
      role: UserRole.landlord,
      phone: '0902000001',
    ),
    SessionUser(
      id: 'owner-b',
      email: 'landlord2@demo.vn',
      name: 'Nguyễn Văn Hùng',
      role: UserRole.landlord,
      phone: '0902000002',
    ),
    SessionUser(
      id: 'admin-a',
      email: 'admin@demo.vn',
      name: 'Quản trị viên',
      role: UserRole.admin,
    ),
  ];
  DemoAuthRepository({
    DemoTransport? transport,
    DateTime Function()? now,
    Set<String>? unavailable,
    this.isUnavailable,
  }) : transport = transport ?? DemoTransport(),
       unavailable = unavailable ?? {},
       now = now ?? DateTime.now {
    for (final user in accounts) {
      _accounts[user.email] = (user: user, password: 'demo123');
    }
  }
  // Deliberately exposed only by the demo adapter; no email is sent.
  String? demoOtp(String email) => _otp[email.trim().toLowerCase()]?.code;
  @override
  Future<void> sendOtp(String email) => transport.run(() {
    final normalized = email.trim().toLowerCase();
    if (!_accounts.containsKey(normalized)) {
      throw const RepositoryFailure(
        DemoFault.missing,
        'Email chưa có tài khoản demo.',
      );
    }
    if (_otp[normalized]?.resendAt.isAfter(now()) ?? false) {
      throw const RepositoryFailure(
        DemoFault.denied,
        'Chờ 60 giây trước khi gửi lại mã.',
      );
    }
    _resetTokens.removeWhere((_, t) => t.email == normalized);
    _otp[normalized] = (
      code: (123456 + _otpSequence++).toString().padLeft(6, '0'),
      expiry: now().add(const Duration(minutes: 5)),
      resendAt: now().add(const Duration(seconds: 60)),
    );
  });
  @override
  Future<String> verifyOtp(String email, String code) => transport.run(() {
    final record = _otp[email];
    if (record == null ||
        record.code != code ||
        !record.expiry.isAfter(now())) {
      throw const RepositoryFailure(
        DemoFault.denied,
        'Mã OTP không chính xác hoặc đã hết hạn.',
      );
    }
    // A newly verified code replaces earlier reset authorization.
    _resetTokens.removeWhere((_, t) => t.email == email);
    final token = 'reset-${_otpSequence++}';
    _resetTokens[token] = (email: email, expiry: record.expiry);
    return token;
  });
  @override
  Future<void> resetPassword(String token, String password) =>
      transport.run(() {
        final record = _resetTokens[token];
        if (record == null || !record.expiry.isAfter(now())) {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Phiên xác minh đã hết hạn. Vui lòng gửi lại OTP.',
          );
        }
        if (password.length < 6) {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Mật khẩu cần ít nhất 6 ký tự.',
          );
        }
        final account = _accounts[record.email]!;
        _accounts[record.email] = (user: account.user, password: password);
        _otp.remove(record.email);
        _resetTokens.removeWhere((_, t) => t.email == record.email);
      });
  @override
  Future<SessionUser> signIn(String login, String password) =>
      transport.run(() {
        final normalized = login.trim().toLowerCase();
        final account =
            _accounts[normalized] ??
            _accounts.values
                .where(
                  (a) => a.user.phone.isNotEmpty && a.user.phone == normalized,
                )
                .firstOrNull;
        if (account == null || account.password != password) {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Email/số điện thoại hoặc mật khẩu không đúng.',
          );
        }
        if (unavailable.contains(account.user.id) ||
            (isUnavailable?.call(account.user.id) ?? false)) {
          throw const RepositoryFailure(
            DemoFault.denied,
            'Tài khoản đã bị khóa hoặc đã xóa.',
          );
        }
        return account.user;
      });
  @override
  Future<SessionUser> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) => transport.run(() {
    final normalized = email.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized) ||
        !RegExp(r'^\d{9,11}$').hasMatch(phone) ||
        name.trim().isEmpty ||
        password.length < 6) {
      throw const RepositoryFailure(
        DemoFault.server,
        'Kiểm tra thông tin đăng ký.',
      );
    }
    if (_accounts.containsKey(normalized) ||
        _accounts.values.any((a) => a.user.phone == phone)) {
      throw const RepositoryFailure(
        DemoFault.server,
        'Email hoặc số điện thoại đã được đăng ký.',
      );
    }
    // Matches the current web registration: TENANT, never a self-issued ADMIN.
    final user = SessionUser(
      id: 'user-${_accounts.length + 1}',
      email: normalized,
      name: name.trim(),
      phone: phone,
      role: UserRole.tenant,
    );
    _accounts[normalized] = (user: user, password: password);
    return user;
  });
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
    user = DemoAuthRepository.accounts.firstWhere((u) => u.role == role);
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
