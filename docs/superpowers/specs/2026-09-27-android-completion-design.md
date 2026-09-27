# Hoàn thiện QLCT trên Android

## Mục tiêu và quyết định đã chốt

Hoàn thiện các mục còn bỏ dở của ứng dụng quản lý chi tiêu hiện có, không viết lại Auth/CRUD, không kết nối ngân hàng hoặc ví điện tử và không thêm dịch vụ có nguy cơ phát sinh phí lưu ảnh. Nền tảng đích là Android; Web/Windows đang có trong repo không phải mục tiêu tính năng mới, nhưng mã dùng chung không được cố ý làm hỏng. Dữ liệu vẫn thuộc `users/{uid}` trong Firestore. Giao diện tiếng Việt, dùng Material/theme mint–coral sáng/tối hiện tại; biểu đồ, số tiền và trạng thái tiếp tục dễ đọc trên máy 320 px.

Người dùng đã duyệt ví thủ công có số dư ban đầu và chuyển tiền nội bộ; giao dịch cũ phải giữ nguyên. Người dùng đã duyệt PDF/XLSX, đổi tên hồ sơ, cảnh báo ngân sách trên Android, cache ngoại tuyến, onboarding lần đầu và loại bỏ các nút demo. **Không triển khai ảnh hóa đơn dưới bất kỳ hình thức nào**: không picker, upload Storage hay lưu ảnh riêng trên máy. Trường nullable `receiptImageUrl`/rules Storage đang tồn tại được để yên cho tương thích dữ liệu và thay đổi Task 1/2; không tạo tính năng hay dependency dựa vào chúng.

## Phương án và thứ tự

Phương án chọn: mở rộng repository/Firestore hiện có cho ví và chuyển tiền; dùng cache Firestore sẵn có và các package Android nhỏ, chuyên dụng cho PDF/XLSX, chia sẻ file và local notification. Không thêm local database hay backend mới. Hai phương án không chọn là (a) thêm SQLite và tầng đồng bộ riêng, tăng nguy cơ lệch dữ liệu, và (b) Cloud Functions/FCM/Storage cho thông báo và file, tăng cấu hình cloud/chi phí. Công việc triển khai theo ba lát kiểm thử độc lập: mô hình ví + hồ sơ; export Android; thông báo + offline/onboarding/hoàn thiện UI.

## Ví và chuyển tiền

Thêm `users/{uid}/wallets/{walletId}` với tên, loại hiển thị (tiền mặt/ngân hàng/ví điện tử/khác), `openingBalance` số nguyên VND và thời điểm tạo/cập nhật. Loại chỉ là nhãn thủ công, không chứa số tài khoản hoặc kết nối bên ngoài. Ví mặc định có ID xác định `cash`, tên “Tiền mặt”, số dư ban đầu 0. Tài khoản mới được tạo ví mặc định cùng hồ sơ/danh mục. Tài khoản cũ thiếu ví mặc định vẫn có ví mặc định ảo khi đọc; tạo document khi người dùng sửa ví hoặc thao tác cần ghi. Không chuyển đổi hàng loạt giao dịch cũ.

Giao dịch mới có `walletId` bắt buộc; giao dịch cũ không có trường này được tính vào `cash`. Form thêm/sửa giao dịch chọn ví hiện có; khi sửa giao dịch cũ, mặc định chọn `cash`. `FinanceTransaction` vẫn đọc được tài liệu cũ. Ví mặc định không được xóa; ví khác chỉ được xóa khi không có giao dịch hoặc chuyển tiền tham chiếu. Đổi tên và số dư ban đầu được phép. Không lưu số dư phát sinh trong document ví để tránh hai nguồn sự thật.

Thêm `users/{uid}/transfers/{transferId}` với `fromWalletId`, `toWalletId`, `amount > 0`, ngày, ghi chú và thời điểm tạo/cập nhật. Không cho chuyển cùng ví. Danh sách ví có lịch sử chuyển; người dùng tạo hoặc xóa một khoản chuyển (xóa cần xác nhận), không sửa trực tiếp, có thể xóa và tạo lại. Số dư ví = số dư ban đầu + thu − chi + chuyển vào − chuyển ra. Số dư toàn app = tổng số dư ví; chuyển nội bộ triệt tiêu trong tổng. Báo cáo thu/chi, biểu đồ, ngân sách **không** tính số dư ban đầu hoặc chuyển ví. Số dư ví âm được hiển thị rõ, không âm thầm từ chối ghi do trạng thái offline/cạnh tranh thiết bị. Thu/chi lịch sử vẫn theo UID và category như hiện tại.

Firestore rules tiếp tục chặn UID khác; bổ sung match riêng cho `wallets` và `transfers`, kiểm tra amount hợp lệ và hai ví khác nhau, không nới quyền public. Thử nghiệm emulator xác nhận khác UID không đọc/ghi được các collection mới. Không xóa các file/cấu hình Task 1/2 đang có trong working tree.

## Hồ sơ, điều hướng và màn hình

Nút sửa ở Cài đặt mở form đổi tên có validation, lưu `users/{uid}.fullName` trước rồi đồng bộ `FirebaseAuth.displayName`; Firestore là nguồn tên hiển thị ở Cài đặt và Trang chủ. Nếu bước Auth thất bại sau khi Firestore đã lưu, báo rõ trạng thái đồng bộ và thử lại khi đăng nhập sau; không tuyên bố toàn bộ thao tác thất bại. Email chỉ xem, không thêm luồng đổi email cần xác thực lại. Cài đặt đọc hồ sơ thật và có loading/error state. Mục “Tài khoản & ví” mở danh sách ví; thẻ ví hiện số dư, loại, hành động sửa/xóa và chuyển tiền. Form giao dịch hiển thị lựa chọn ví một cách ngắn gọn, không làm mất phần category/ngày/ghi chú. Trang chủ hiển thị số dư đã bao gồm opening balance, nhưng thu/chi tháng vẫn là số tiền giao dịch. Thêm route tên rõ ràng, giữ AuthGate bảo vệ.

Onboarding hiện một lần trên Android khi chưa đăng nhập và chưa đánh dấu hoàn tất bằng `shared_preferences`; “Bỏ qua”/“Bắt đầu” đánh dấu xong rồi vào AuthGate. Người đã đăng nhập hoặc đã xem không thấy onboarding lại khi mở app/đăng xuất. Ba nút demo “Đang tải/Trống/Lỗi” được bỏ khỏi Cài đặt sản phẩm; `StatePanel` vẫn dùng ở màn thực tế. Giữ typography, màu semantic, khoảng cách và điều hướng nhất quán với theme hiện tại; không thiết kế lại màn cũ ngoài những chỗ cần cho tính năng.

## Xuất PDF/XLSX

Nút “Xuất báo cáo” mở sheet chọn khoảng ngày (mặc định tháng hiện tại, cho chọn ngày bắt đầu/kết thúc) và định dạng PDF/XLSX. Nguồn là giao dịch hiện có của UID đang đăng nhập, lọc bằng ngày địa phương; tính tổng thu, tổng chi, số dư thu−chi trong khoảng và chi theo danh mục từ cùng hàm thống kê thuần Dart. PDF/XLSX chứa danh sách giao dịch (ngày, loại, danh mục, ví, số tiền, ghi chú), các tổng và phân bổ; số và ngày theo định dạng Việt Nam. Lịch sử chuyển ví trong khoảng xuất thành phần riêng và không cộng vào tổng thu/chi. Tên file có khoảng ngày và đuôi đúng. Tạo file tạm trong bộ nhớ riêng app, gọi Android share/save chooser; không upload, không yêu cầu quyền đọc/ghi toàn bộ bộ nhớ. Trạng thái không dữ liệu vẫn xuất báo cáo 0 đồng nhất, lỗi tạo/chia sẻ có thông báo và cho thử lại. Dọn file tạm cũ ở lần khởi động/xuất tiếp theo, không xóa trước khi ứng dụng nhận file hoàn tất. Không giả vờ xuất thành công bằng SnackBar.

## Cảnh báo và ngoại tuyến

Ngân sách dùng tỷ lệ chính xác, không so sánh qua phần trăm đã làm tròn: dưới 80% “An toàn”, từ 80% đến dưới 100% “Sắp vượt”, đúng 100% “Đã dùng hết”, lớn hơn 100% “Đã vượt”. Home và trang Ngân sách cùng quy tắc; số còn/vượt không mâu thuẫn. Cài đặt có công tắc cảnh báo. Khi bật, Android xin quyền thông báo khi hệ điều hành yêu cầu. Khi app đang chạy và dữ liệu tháng hiện tại chạm mốc 80/100/vượt 100, gửi local notification có danh mục, tỷ lệ hoặc số vượt; lưu dấu theo UID + ngân sách + tháng + mốc để không gửi lặp. Xóa/sửa giao dịch làm giảm rồi tăng lại không spam cảnh báo cũ. Không tuyên bố có push khi app đã tắt hoặc giao dịch được thêm từ thiết bị khác trong lúc app không chạy; không dùng FCM/backend.

Trên Android giữ Firestore offline persistence mặc định. Stream phản ánh dữ liệu cache và metadata `hasPendingWrites`; UI phân biệt “dữ liệu đã lưu, có thể chưa đồng bộ” với “thay đổi đang chờ đồng bộ”, bỏ banner khi máy chủ đã xác nhận. Các thao tác với dữ liệu đã được cache có thể sử dụng khi mất mạng; lần đăng nhập đầu tiên, danh mục chưa cache hoặc dữ liệu chưa tải vẫn cần mạng và phải có lỗi/Thử lại rõ ràng. Không thêm SQLite/Drift hay tuyên bố offline hoàn toàn. Thao tác ghi cần tránh chặn không cần thiết vì một `get()` mặc định khi không có mạng; kiểm thử emulator mô phỏng cache, pending write và reconnect. Không có banner “Bạn đang ngoại tuyến” nếu chỉ biết `isFromCache`.

## Kiểm thử và giới hạn hoàn thành

TDD cho phép tính số dư từng ví/tổng, chuyển không ảnh hưởng thu-chi/ngân sách, giao dịch cũ không có `walletId`, dấu mốc ngân sách 80/100/>100 và lọc khoảng xuất. Widget test các form, loading/empty/error, dark mode và 320 px. Android integration dùng Firebase Auth/Firestore Emulator cho tài khoản mới/cũ, tạo ví, chuyển tiền, sửa tên, xuất file và logout/relogin; rules test UID isolation. Kiểm tra thông báo Android bằng test lớp quyết định mốc và smoke trên thiết bị; kiểm tra file PDF/XLSX thật có nội dung/định dạng hợp lệ, không chỉ kiểm tra nút. Chạy `flutter pub get`, `dart format` các file sửa, `flutter analyze`, `flutter test`, emulator tests, `flutter run`.

Không kích hoạt billing, Firebase Storage, tích hợp ngân hàng, tự đồng bộ ảnh, FCM, đổi email, hoặc local DB trong phạm vi này. Nếu Android từ chối quyền thông báo, app vẫn dùng bình thường và trạng thái ngân sách trong app vẫn chính xác. Nếu plugin xuất/chia sẻ không hỗ trợ Web/Windows, tách code theo nền tảng hoặc disable rõ tính năng để không gây lỗi phân tích/build chung. Các thay đổi Task 1/2 đang uncommitted của người dùng được giữ nguyên; chỉ commit tài liệu thiết kế riêng ở giai đoạn này.
