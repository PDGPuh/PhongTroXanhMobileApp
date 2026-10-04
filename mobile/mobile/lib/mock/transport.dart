import '../core/async_resource.dart';

/// Injected only in demo/test repositories. No fallback is applied after errors.
class DemoTransport {
  Duration delay;
  RepositoryFault fault;
  DemoTransport({
    this.delay = const Duration(milliseconds: 250),
    this.fault = RepositoryFault.none,
  });
  Future<T> run<T>(T Function() operation) async {
    await Future<void>.delayed(delay);
    switch (fault) {
      case RepositoryFault.offline:
        throw const RepositoryFailure(
          RepositoryFault.offline,
          'Không có kết nối. Kiểm tra mạng và thử lại.',
        );
      case RepositoryFault.server:
        throw const RepositoryFailure(
          RepositoryFault.server,
          'Không thể xử lý yêu cầu. Vui lòng thử lại.',
        );
      case RepositoryFault.denied:
        throw const RepositoryFailure(
          RepositoryFault.denied,
          'Bạn không có quyền thực hiện thao tác này.',
        );
      case RepositoryFault.missing:
        throw const RepositoryFailure(
          RepositoryFault.missing,
          'Không tìm thấy dữ liệu này.',
        );
      case RepositoryFault.none:
        return operation();
    }
  }
}
