# Phòng Trọ Xanh — mobile-mock

Bản Flutter demo giữ giao diện và các luồng hiện tại. Dữ liệu, tài khoản, OTP và kết quả thanh toán đều là mô phỏng trong bộ nhớ, được khởi tạo lại khi khởi động app. Chưa kết nối backend.

## Chạy và kiểm tra

Yêu cầu Flutter hỗ trợ Dart 3.13.3 trở lên (theo `pubspec.yaml`). Từ thư mục này:

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

Để xem trên trình duyệt: `flutter run -d chrome`. Có thể chọn màn bằng query `?screen=welcome`, `login`, `discover`, `roommate`, `messages`, `profile`, `landlord`, `admin`. Màn riêng vẫn yêu cầu đăng nhập đúng vai trò.

Tài khoản **chỉ dành cho demo**: `tenant@demo.vn`, `tenant2@demo.vn`, `landlord@demo.vn`, `landlord2@demo.vn`, `admin@demo.vn`; mật khẩu chung `demo123`. Không dùng các tài khoản này làm xác thực production.

## Phạm vi

- Khám phá/lọc/vuốt/lưu/so sánh phòng; xem ảnh, chi tiết và chỉ đường khi có tọa độ.
- Ghép bạn, lời thích/match hai chiều và chat có trạng thái gửi/lỗi/thử lại.
- Hồ sơ, thông báo, xác minh, hỗ trợ, đổi phòng và gói dịch vụ.
- Chủ trọ quản lý/đăng phòng, hợp đồng/người thuê, QR nhận phòng và đánh giá.
- Quản trị duyệt tin/CCCD, xử lý báo cáo và quản lý tài khoản.
- Có bộ chọn ảnh thiết bị và tạo/quét QR; quyền camera/picker cần nghiệm thu trên thiết bị thật.

Ảnh mẫu trong `assets/references` được dùng để lấy vùng phòng/avatar/logo cho widget Flutter. Font Be Vietnam Pro và Lora đi kèm giấy phép OFL. Không phải app nhúng ảnh screenshot thay toàn bộ giao diện.

Tài liệu chung nằm ở [`../docs`](../docs). Không đưa cache, dependencies, file build, log hoặc thiết lập máy phát triển lên Git.
