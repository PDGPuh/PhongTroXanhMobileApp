# Phòng Trọ Xanh — bản dành cho tích hợp

Bản Flutter dùng để tiếp tục phát triển và tích hợp backend. **Chưa phải bản phát hành production hoàn chỉnh**: hiện chưa có backend, token thật, OTP email, push hay thanh toán thật.

## Cấu trúc

- `lib/domain/`: model và kiểu dữ liệu dùng chung.
- `lib/core/`: theme, widget, animation, media và trạng thái tải/lỗi.
- `lib/features/`: giao diện theo nghiệp vụ.
- `lib/app/`: navigation, session/controller và điểm lắp các dependency.
- `lib/mock/`: fixture phòng/người/chat, tài khoản demo, kho dữ liệu trong bộ nhớ, adapter auth/phòng, transport mô phỏng và các workflow demo.

Giao diện, animation và các luồng được giữ giống `../mobile-mock`. Việc tách thư mục không đồng nghĩa đã kết nối API: `AppState` và một số controller vẫn sử dụng mock adapter. Mock được bật mặc định để app chạy được khi chưa có backend. Dữ liệu mô phỏng nằm trong `lib/mock/`; thay adapter và các dependency trước khi xóa thư mục này.

## Chạy và kiểm tra

Yêu cầu Flutter hỗ trợ Dart 3.13.3 trở lên, theo `pubspec.yaml`.

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

## Thay mock bằng backend

1. Chốt hợp đồng API và quyền truy cập với backend; không suy đoán endpoint.
2. Viết adapter auth/phòng theo `AuthRepository` và `RoomRepository`, đồng thời repository riêng cho các workflow còn đang dùng kho trong bộ nhớ.
3. Thay dependency tại `AppState`; chuyển dữ liệu theo user ID và xử lý kết quả trả muộn sau logout/switch account.
4. Loại các tính năng tài khoản mẫu/OTP minh họa/thanh toán mô phỏng; lấy quota, entitlement và quyết định nghiệp vụ từ server.
5. Chạy lại test bằng adapter mới trước khi xóa `lib/mock/`. Không chỉ xóa thư mục khi các import và dependency chưa được thay.

Xem [tài liệu chung](../docs). Không có credential, khóa ký ứng dụng hay cấu hình môi trường thật trong source này.
