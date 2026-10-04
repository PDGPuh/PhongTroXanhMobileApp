# Phòng Trọ Xanh — Flutter

| Thư mục | Nội dung |
|---|---|
| [`mobile-mock`](mobile-mock) | Demo giao diện/luồng hiện tại với dữ liệu mô phỏng trong bộ nhớ |
| [`mobile`](mobile) | Bản dành cho tích hợp, tách model khỏi fixture và gom adapter mô phỏng vào `lib/mock` |
| [`docs`](docs) | Chuẩn giao diện, tiêu chí nghiệm thu và hướng dẫn tích hợp |

Mỗi app có `pubspec.yaml` và có thể chạy riêng bằng `flutter pub get`, `flutter run`. Không cần Node.js hoặc `node_modules` để chạy Flutter. Mỗi bản hiện chưa có backend; thư mục `mobile` không được coi là bản phát hành live.

Source được kiểm tra trên Flutter 3.47.3 / Dart 3.13.3. Cache, file build, log, ảnh chụp QA, thiết lập IDE, đường dẫn SDK cá nhân và khóa ký bị loại khỏi Git.
