# Scenario nghiệm thu giao diện mobile

Ngày lập: 02/10/2026; cập nhật 03/10/2026. Theo kế hoạch `MOBILE_UI_COMPLETION_PLAN.md`. Bảng 40 dòng giữ nguyên tiêu chí; bằng chứng dưới đây ghi phạm vi đã kiểm tra. Không mặc định cả 40 dòng PASS từ tổng số bài test.

## Bằng chứng hiện tại

Unit/widget tests được giữ trong `mobile-mock/test` và `mobile/test`. Log, ảnh chụp QA và script chạy riêng trên máy phát triển không được đưa vào repo.

| Tiêu chí | Phạm vi đã xác nhận | Phần chưa xác nhận |
|---|---|---|
| A01–A08 | Guard/account isolation/return context/missing, async lỗi và request trả trễ, validation auth, reset OTP demo | Auth/backend/email live |
| A09–A11 | Draft hồ sơ, layout tenant/owner onboarding, tenant hoàn tất bằng browser; KYC validation/remove/retry, rejected/resubmit/approved theo ID | Onboarding owner toàn chuỗi trên thiết bị; picker/upload giấy tờ thật; public profile khác account qua API |
| A12–A16 | Filter cancel/apply/min-max, room status visibility, undo từng deck, quota/paid expiry, gallery theo count, compare đúng ID, map r4/missing-coordinates | Swipe API lỗi/rollback, vị trí/permissions và marker của provider thật |
| A17–A21 | Like không tự match, mutual/unmatch/contact đúng ID, chat failed/retry/draft/dedup và shared room card | Match/chat realtime, attachment native; payload chưa hỗ trợ có trạng thái unavailable |
| A22–A28 | Room editor draft giữ floor/images/fees/location; owner scope/tenant list; mã đúng rental/expiry/refresh; review eligibility/target/dedup và history chung | QR encode/camera thật; full editor submit với upload live; điểm uy tín từ backend |
| A29–A33 | Swap needs/proposal/ownership/accept/cancel; không tự completed; KYC/report quyết định và history, khóa/mở user và stale pending guard | Chuyển hợp đồng mới; API moderation, delivery cảnh cáo |
| A34–A37 | Typed notification, settings/logout; checkout terminal/idempotency/rights; delete sai mật khẩu/offline không xóa | Push thật, webhook live; chính sách xóa account có hợp đồng đang hoạt động |
| A38–A40 | 10 màn chính và các màn bổ sung qua widget tests cỡ chữ lớn; analyze/test/web build đã được kiểm tra trong quá trình phát triển | Toàn bộ screens trên Android/iOS, mọi quyền/native lifecycle, so sánh từng pixel với asset gốc |

Các phạm vi trên là **PASS_DEMO cho những hành vi được test**, còn từng scenario có phần API/native vẫn **PARTIAL/NOT_RUN**. Không coi lưu ảnh mẫu, icon QR hay gateway mô phỏng là capability thật.

## Dữ liệu kiểm thử

Repository demo cần tối thiểu: guest, 2 tenant, 2 landlord, 1 admin; phòng khả dụng/chờ duyệt/ẩn/đã thuê; mỗi chủ có phòng riêng; hai tenant có nhiều rental; rental chưa/đã check-in/hết hạn; like một chiều và match hai chiều; nhiều conversation/notification gắn ID khác nhau; KYC pending/rejected/approved; swap đang matching/chờ landlord/được duyệt/chưa hoàn tất/hoàn tất; payment pending/success/failure.

Các account fixture có role từ session response, không từ tiền tố email. Cho phép chuyển tài khoản để kiểm thử hai phía qua thao tác đăng xuất/đăng nhập. Fault controls dành cho phát triển phải tạo được delay/error/offline/403/404/token expired/upload failed; không đưa nút điều khiển test vào trải nghiệm người dùng.

| ID | Đợt | Thao tác kiểm tra | Kết quả cần đạt |
|---|---|---|---|
| A01 | D1 | Tenant mở entry admin; landlord mở phòng của chủ khác | Bị chặn theo quyền; không có dữ liệu hoặc nút sửa trái quyền |
| A02 | D1 | Lưu/chat dưới tenant A → logout → tenant B | Private data không lẫn; back không mở lại màn đã đăng xuất |
| A03 | D1 | Guest thực hiện action yêu cầu login → login → back | Quay về đúng ngữ cảnh nếu được phép; không gửi action hai lần |
| A04 | D1 | Open link sai ID hoặc resource vừa bị xóa | Not-found/denied đúng tình huống; back/retry dùng được |
| A05 | D1 | Tải chậm/lỗi/offline ở list/detail/form | Loading rồi content/error; không thay bằng seed giả; draft còn khi retry |
| A06 | D2 | Register thiếu trường/sai phone/pass ngắn/confirm khác | Lỗi cạnh trường; không submit; hợp lệ mới tạo tài khoản |
| A07 | D2 | Login credential sai; login đúng ba role | Lỗi rõ; shell đúng role response; không cấp admin từ email |
| A08 | D2 | Forgot password: email → OTP sai/hết hạn/resend → new password | Cooldown đúng; bước sau chỉ mở khi verify thành công; reset thành công mới kết thúc |
| A09 | D2 | Tenant/landlord onboarding next/back/thoát/mở lại | Draft giữ được; finish lưu dữ liệu; role thực chỉ đổi khi session xác nhận |
| A10 | D2 | Edit profile/avatar/habits/budget rồi hủy hoặc lưu | Hủy không ghi; lưu đồng bộ profile/public roommate và đúng user |
| A11 | D2/D6 | KYC thiếu một mặt/upload lỗi → gửi → admin từ chối → gửi lại | Validation/preview/retry; pending/reason/approved đồng bộ; không mất submission ID |
| A12 | D3 | Filter min/max giá/type/amenities/search/sort/clear | Danh sách/card/map cùng bộ lọc; invalid range được chặn; giữ filter khi back |
| A13 | D3 | Pending/hidden/rented room tồn tại trong seed | Không vào deck khả dụng; chủ đúng owner vẫn thấy trong quản lý theo status |
| A14 | D3 | Swipe/like/undo; đổi sang deck roommate; hết quota; API lỗi | Lịch sử riêng; trừ lượt một lần; refund theo policy; không tự reset quota; lỗi rollback |
| A15 | D3 | Mở ảnh thứ N của phòng B → save → Saved → Compare → detail | Counter theo ảnh thật; roomId đúng ở mọi màn; save đồng bộ; empty/limit theo web |
| A16 | D3 | Chọn marker phòng B; từ chối vị trí; phòng thiếu tọa độ | Marker/detail đúng phòng; không crash; có trạng thái thiếu quyền/tọa độ |
| A17 | D4 | LIKE profile score cao nhưng chưa mutual | Chỉ hiển thị lời thích; không tự thêm Matches hoặc tuyên bố ghép thành công |
| A18 | D4 | Repository trả mutual match → mở chat → unmatch | matchId/conversationId đúng; list cập nhật; xử lý quyền chat theo phản hồi |
| A19 | D4 | Contact phòng B/chủ B; contact profile C; mở lại | Đúng participant/context; tránh conversation trùng; header/avatar đúng người |
| A20 | D4 | Gửi tin lỗi → retry; double tap send; rời chat/quay lại | Nội dung/draft còn; failed/sent rõ; không duplicate; unread/preview/time đồng bộ |
| A21 | D4 | Shared card phòng B và ảnh; ảnh/payload không được hỗ trợ live | Card mở B; preview/upload/retry nếu có capability; nếu thiếu hiển thị unavailable |
| A22 | D5 | Landlord đăng/sửa phòng, next/back/preview/submit lỗi | Không mất ảnh/area/floor/fees/location; lỗi giữ form; submit đúng owner và trạng thái |
| A23 | D5 | Hai landlord xem Overview/Rooms/Tenants | Dữ liệu phân chủ; số liệu từ nguồn chung; số 0 không bị thay bằng fixture |
| A24 | D5 | Tenant có nhiều rental chọn rental B để nhận phòng | Không dùng rental/phòng đầu tiên; landlord/tenant/detail cùng rentalId |
| A25 | D5 | QR/mã sai/hết hạn/đã dùng/tenant khác; rồi mã hợp lệ | Chặn sai; hợp lệ mới checkedIn; hai phía đồng bộ; không double-submit |
| A26 | D5 | Landlord đổi rental khi mở QR; copy mã; làm mới | QR/mã của rental mới; không giữ token cũ; expiry và quyền refresh rõ |
| A27 | D5 | Review rental chưa đủ/đủ điều kiện; đổi target; gửi lỗi | Không mở review trái eligibility; đúng room/user/rental; lỗi giữ form; không gửi trùng |
| A28 | D5 | Review thành công → lịch sử/detail/trustscore | Chỉ phần dữ liệu nguồn xác nhận được cập nhật; không tự bịa điểm uy tín mới |
| A29 | D6 | Swap explore/filter/detail → chọn phòng hiện tại → tạo needs | Đúng roomId và field đã chọn; matching/pending_landlord theo flow/adapter |
| A30 | D6 | Gửi đề xuất swap lỗi rồi thử lại; landlord duyệt/từ chối | Không báo thành công khi lỗi; đúng swapId; trạng thái/reason đồng bộ hai phía |
| A31 | D6 | Swap được duyệt nhưng server chưa trả completed | Hiển thị đã duyệt/chờ bước tiếp theo; không tuyên bố hoàn tất hoặc ký hợp đồng |
| A32 | D6 | Admin KYC/report action rồi rời màn/mở lại/filter | Quyết định giữ; queue/count/hồ sơ cập nhật; không lẫn đối tượng hoặc quyết định |
| A33 | D6 | Admin user detail/khóa/mở khi capability có; request bị từ chối | Đúng user và reason; lỗi không thay trạng thái; không có action chưa được hỗ trợ |
| A34 | D7 | Notification chỉ đến room/match/chat/rental khác nhau | Mỗi notification mở đúng type+ID; read/unread/count đồng bộ; missing/403 xử lý |
| A35 | D7 | Đổi settings → đóng màn/mở lại; logout mọi shell | Settings lưu theo user; logout thực sự dọn session, không chỉ pop Profile |
| A36 | D7 | Gói → checkout → cancel/failed/pending/success; callback lặp | Kết quả có xác minh repository; chỉ success cấp quyền lợi; không cấp hai lần; history nhất quán |
| A37 | D7 | Xóa demo account: hủy/confirm/request lỗi/có rental cản | Hủy không xóa; lỗi còn account; success mới logout; không xóa dữ liệu thật khi thử UI |
| A38 | D8 | Chạy toàn bộ screens với keyboard/long text/font scale/back | Không overflow/nút bị che; form và chat cuộn; back an toàn; touch/semantics dùng được |
| A39 | D8 | 10 màn tham chiếu cùng viewport/nội dung so sánh cạnh nhau | Màu/type/card/spacing/icon/nav theo ảnh; sai khác asset/font được ghi; không dùng screenshot nguyên màn |
| A40 | D8 | Analyze/test/build và chạy nền tảng thực tế | Không lỗi nghiêm trọng; ghi lệnh/ngày/thiết bị/kết quả; platform chưa chạy không được đánh dấu qua |

## Cách ghi kết quả

Mỗi lần nghiệm thu ghi: ID, PASS/FAIL/BLOCKED/NOT RUN, fixture/account, nền tảng và viewport, bước tái hiện, kết quả thực, ảnh/log khi cần, commit hoặc snapshot đang kiểm tra. Không đánh dấu PASS bằng việc chỉ đọc implementation.

Unit/state test ưu tiên những quy tắc dễ sai: quyền và account separation, target ID, match/quota, rental QR, eligibility, swap mapping, retry/idempotency và payment callback. Widget/integration test ưu tiên chuỗi chuyển màn và form; kiểm tra visual theo ảnh/screenshot, không dùng test lặp lại mọi chi tiết render.

Mốc UI dùng FakeRepository để kiểm tra đủ trạng thái. Mốc tích hợp chạy lại cùng scenario với API/native service thực; scenario không có capability thực phải được ghi BLOCKED hoặc NOT RUN cùng lý do, không coi demo PASS là live PASS.
