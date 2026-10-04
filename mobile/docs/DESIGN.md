# Chuẩn thiết kế Phòng Trọ Xanh

Nguồn chuẩn: 10 ảnh người dùng cung cấp ngày 01/10/2026. Khuyến nghị của skill là tham khảo, không thay palette hoặc bố cục của ảnh.

- Xanh hành động #008568; chữ #073B3C; mô tả #586B7D; mint #EAF9F4; viền #E2EBEE.
- Theo yêu cầu cải thiện font ngày 03/10/2026, app dùng **Be Vietnam Pro**: regular 400 cho nội dung, medium 500 cho nhãn, semibold 600 cho tiêu đề/giá; bold 700 dành cho nhấn mạnh. Cả bốn weight là file TTF riêng, bundle offline, kèm giấy phép OFL từ Google Fonts.
- Chữ Lora chỉ giữ ở tên thương hiệu, weight 600, tracking -0.1. Tiêu đề giao diện không còn dùng serif nặng hoặc tracking -0.8.
- Nội dung chính 15–16 logical pixels, metadata 13–14, caption/nav tối thiểu 12; line height nội dung 1.5, tiêu đề 1.35. Tôn trọng text scaling; nhãn nav dành cùng chiều cao khi xuống hai dòng.
- Thống kê chủ trọ dùng hai cột ở khung mobile, bốn cột khi đủ rộng. Nút bộ lọc cố định bên cạnh hàng chip cuộn để chữ lớn không đẩy nút khỏi màn hình.
- Gutter 16 logical pixels, card radius 14, chip radius 30, CTA radius 15.
- Shadow mềm, icon Lucide đồng bộ. Nút icon mở rộng hit target tối thiểu 48.
- Nav 5 mục, màu xanh và gạch dưới cho mục chọn, dot đỏ cho tin chưa đọc.
- Chuyển tab (04/10/2026): fade + dịch ngang 14px theo hướng chọn, 260ms/easeOutCubic; vạch chọn trượt liên tục, icon/chữ đổi màu 180ms, phản hồi bấm Cupertino. Bấm lại mục hiện tại không chạy lại hiệu ứng. Bấm liên tục chuyển tiếp từ vị trí đang vẽ; không xếp hàng thao tác.
- Tab đã mở giữ trạng thái nhập và cuộn; tab chưa mở được dựng khi chọn lần đầu. Tab ẩn không nhận thao tác, focus hoặc semantics; tắt ticker ẩn. Giảm chuyển động bỏ hiệu ứng tab/icon/vạch chọn. Đổi mục giữa lúc vuốt thẻ hủy thao tác đang chờ, không trừ quota hay lưu thẻ ngoài màn hình.
- Không nhúng khung điện thoại/camera/status bar giả.
- Nội dung cuộn độc lập với nav/CTA; giữ SafeArea và keyboard inset.
- Danh sách (04/10/2026): ưu tiên nền mở, phân nhóm và khoảng trắng; tránh khung lồng khung hoặc đóng mỗi hàng thông tin trong một thẻ. Giữ thẻ cho nội dung cần gom rõ như phòng và thống kê.
- Hồ sơ: menu không có viền/bóng, cách nhau 12px, padding dọc 14px, tiêu đề và mô tả cách 5px; nhóm tài khoản, hoạt động, cài đặt/hỗ trợ cách 24px. Phần giới thiệu không bọc thẻ, bio trên hàng riêng.
- Thông báo: hàng riêng với padding dọc 16px, icon 40px, tiêu đề/nội dung cách 8px; trạng thái đã đọc/chưa đọc nằm dưới mô tả, phân cách nhẹ, không cắt nội dung hay thêm thời gian giả khi dữ liệu chưa có.
- Tin nhắn: hàng nền mở với separator nhẹ, padding dọc 16px, gutter 16px, mô tả 15px; giữ tìm kiếm và trạng thái tin chưa đọc.
- Trang chính (04/10/2026): nhãn ngân sách gọn, dấu phẩy thập phân tiếng Việt; thanh lượt vuốt mint nhẹ, toàn hàng có thể mở gói dịch vụ, thanh tiến trình 4px. Thẻ phòng/bạn ở dùng ảnh tỷ lệ 1.65, padding 16px và radius 18px; giá phòng 24px, tên phòng 20px. Tiêu đề trang cách nội dung 16px.
- Hàng thao tác vuốt giữ cố định trên thanh điều hướng, nội dung thẻ cuộn độc lập; nút lưu/thích lớn 60px, bỏ qua 56px, hoàn tác/chi tiết 48px để phân cấp rõ. Hết lượt hoặc hết kết quả thì ẩn hàng thao tác, hiển thị hành động phù hợp trong nội dung.
- Ở màn thấp hơn 820px, ảnh thẻ dùng tỷ lệ 1.85 để giá phòng vẫn nhìn thấy đầy đủ phía trên hàng nút; màn cao hơn giữ ảnh lớn 1.65.
- Chủ trọ: số liệu lớn 28px cạnh icon, nhãn có khoảng thở, bỏ chữ demo lặp lại và mức tăng giả; danh sách phòng tăng thumbnail/padding/chữ. Các lối tắt dùng menu nền mở. Nạp trước hai ảnh tham chiếu dùng cho tab bạn ở/hồ sơ để giảm khoảng trống ảnh khi chuyển mục lần đầu.
- Prototype dùng dữ liệu demo có thể lặp lại; phần tích hợp không trả kết quả thành công giả.

Chưa xác nhận giống từng pixel: cần tiếp tục so screenshot ở cùng tỷ lệ và cần asset gốc cho ảnh, logo, minh họa/font chính xác.
