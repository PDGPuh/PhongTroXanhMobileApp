# Handoff tích hợp — 03/10/2026

App hiện là Flutter UI dùng kho demo trong bộ nhớ. Web đối chiếu của dự án là nguồn nghiệp vụ; tài liệu cũ chỉ dùng tham khảo. Không cần nhúng HTML/web vào Flutter: các màn, navigation, form và card hiện là widget Flutter.

## Điểm thay adapter

| Domain | Điểm hiện tại | Yêu cầu khi nối backend |
|---|---|---|
| Auth | `<app>/lib/app/session.dart`, AuthRepository | Credential/token/refresh, role/userId từ response; reset OTP phía server |
| Phòng | `features/rooms/room_controller.dart`, RoomRepository | Feed/filter/pagination, owner/status, ảnh riêng, phí/tọa độ; không đưa tin private vào feed |
| Private/shared state | `app/app_state.dart`, `demo/demo_store.dart` | Hydrate theo userId, invalidation khi logout, đồng bộ sau mutation; kho demo không được dùng làm DB |
| KYC/review/report/swap | `demo/workflows.dart`, `demo/workflow_models.dart` | Chuyển operations async thành repository/API; giữ ID, eligibility, reason/history, kiểm tra quyền phía server |
| Thanh toán | checkout/paymentResult | Order từ backend; trạng thái lấy qua API đã xác minh webhook; bỏ nút mô phỏng; chống cấp quyền hai lần |
| Chat/notification | AppState, conversation/message models | Realtime/read receipts thực, cursor, upload attachment; target type+ID phải giữ nguyên |
| Support/delete | DemoWorkflows | Ticket service, xác thực lại, policy hợp đồng đang hoạt động; xóa thật theo chính sách backend |

`DemoWorkflows.run` hiện cung cấp loading, fault injection và chặn kết quả trả trễ sau logout/switch/dispose. Đây là guard client, quyền thật vẫn phải kiểm tra ở server. Tách repository theo domain trước khi nối để widget không trực tiếp sửa kho dữ liệu live.

## Các capability cần thiết bị/dịch vụ thật

- Picker/upload ảnh và CCCD: progress/retry, quyền thư viện/camera, storage URL và bảo vệ dữ liệu nhạy cảm. Preview hiện dùng ảnh mẫu có nhãn.
- QR nhận phòng: token do server phát, encode QR thật và camera decode; server quyết định expiry/đã dùng/rentalId. Bản demo có tạo/quét QR và kiểm tra mã đúng hợp đồng trong bộ nhớ; chưa có server xác thực token hoặc nghiệm thu camera trên thiết bị thật.
- Bản đồ/vị trí: provider, tọa độ từ API, quyền denied/restricted và mở điều hướng ngoài app. Hiện chưa định vị thật.
- OAuth, push/deep links và gọi điện: cấu hình Android/iOS, lifecycle và quyền. Không có callback live được xác nhận ở preview.
- Gói: backend quyết định entitlement, quota reset, expiry, Boost và Super Match; bản demo chỉ minh họa quyền thao tác/lịch sử.
- Swap: kết quả duyệt và accept proposal chưa đủ để tuyên bố chuyển phòng xong. Chờ backend tạo/xác nhận hợp đồng mới và trả completed.

## Nghiệm thu tích hợp

1. Chốt payload/endpoint với web đang chạy và backend hiện tại; không suy endpoint từ tên method demo.
2. Chạy lại tiêu chí trong `MOBILE_UI_ACCEPTANCE.md` với API, gồm quyền sở hữu, offline, timeout, token hết hạn, duplicate callback và request trả trễ.
3. Chạy trên Android/iOS: bàn phím, safe areas, text scale, camera/picker/location, background/relaunch và deep links.
4. Thay ảnh/logo/font bằng asset gốc rồi đối chiếu 10 visual ở viewport thống nhất. Chưa có xác nhận pixel-perfect.

Preview reload xóa toàn bộ dữ liệu demo và phiên; dữ liệu giữa các account chỉ được giữ khi đổi tài khoản trong cùng lần chạy.
