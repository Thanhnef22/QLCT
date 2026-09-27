# Task 2: giao dịch, danh mục và ngân sách

## Mục tiêu và phạm vi

Thay dữ liệu mẫu trên Trang chủ, danh sách/chi tiết giao dịch và ngân sách bằng dữ liệu Firestore của người đang đăng nhập. Người dùng có thể thêm, xem, sửa, xóa giao dịch; quản lý danh mục; và quản lý ngân sách theo tháng. Giữ nguyên Auth, điều hướng và ngôn ngữ tiếng Việt từ Task 1. Không triển khai báo cáo nâng cao, biểu đồ, xuất file hay thiết kế lại toàn app.

Project hiện chỉ có `DemoTransaction` và `demo_data.dart`; chưa có model hoặc repository cho ba thực thể. Form thêm giao dịch, chi tiết giao dịch, danh sách và ngân sách đều là UI giả. Mục Danh mục trong Cài đặt chưa có màn hình đích. `AuthService` và Firestore rules theo `users/{uid}` đã có và được tái sử dụng.

## Hướng tiếp cận

Chọn model có kiểu rõ ràng và một lớp `FinanceRepository` mỏng để gom đường dẫn Firestore, chuyển đổi document và thao tác CRUD. UI dùng `StreamBuilder` cho dữ liệu thay đổi theo thời gian và `setState` cho trạng thái form/bộ lọc. Không thêm Provider/Riverpod hoặc package định dạng chỉ cho Task 2.

Hai cách khác đã cân nhắc: gọi Firestore trực tiếp trong từng màn hình ít file hơn nhưng lặp logic UID/schema và khó kiểm thử; thêm một hệ state management mới giúp mở rộng về sau nhưng tăng độ phức tạp không cần thiết cho ba luồng hiện tại.

## Dữ liệu và bất biến

Tất cả document nằm dưới `users/{uid}`; repository lấy UID từ `FirebaseAuth.currentUser`, không nhận UID tự do từ màn hình và từ chối thao tác khi chưa đăng nhập. Giữ Firestore rules riêng tư hiện có.

| Collection | Trường và quy ước |
|---|---|
| `categories/{id}` | `name`, `icon`, `color`, `type` (`income`/`expense`), `createdAt`, `updatedAt`. Đọc được 13 danh mục mặc định của Task 1. |
| `transactions/{id}` | `amount` là số nguyên VND dương; `categoryId`, `categoryName`, `categoryIcon`, `categoryColor` là snapshot lúc lưu; `type`, `note`, `date` là Firestore timestamp, `receiptImageUrl` nullable, `createdAt`, `updatedAt`. |
| `budgets/{id}` | `categoryId`, `categoryName`, `limitAmount` là số nguyên VND dương, `month` theo `yyyy-MM`, `createdAt`, `updatedAt`. ID document cố định từ cặp `(month, categoryId)` để một danh mục chỉ có một ngân sách trong tháng. Chỉ dùng danh mục chi tiêu. |

Sửa tên/icon/màu danh mục không viết lại giao dịch lịch sử; chúng giữ snapshot đã ghi. Ngân sách hiển thị tên danh mục hiện tại theo `categoryId`, dùng `categoryName` đã lưu khi danh mục không còn tải được. Không cho đổi `type` hoặc xóa danh mục đang được giao dịch/ngân sách tham chiếu; UI giải thích bằng tiếng Việt. Kiểm tra tham chiếu diễn ra trong repository trước khi xóa. Đây là bảo vệ ở mức ứng dụng, không phải ràng buộc giao dịch xuyên collection ở server.

Không ghi giao dịch hoặc ngân sách nếu danh mục đã chọn không tồn tại hoặc sai loại. Khi sửa giao dịch, giữ `createdAt`, cập nhật `updatedAt`; khi đổi danh mục, ghi lại snapshot mới. Khi sửa ngân sách, giữ cặp tháng/danh mục; muốn chuyển sang cặp khác thì xóa và tạo lại, tránh trùng ID.

## Luồng màn hình

1. **Trang chủ:** lấy giao dịch thật để tính tổng thu, tổng chi và số dư lũy kế (tổng thu trừ tổng chi của toàn bộ giao dịch), cùng ba giao dịch gần nhất; lấy ngân sách tháng hiện tại để hiển thị tóm tắt. Bỏ ngày/tỷ lệ/số tiền cố định và banner “dữ liệu mẫu” ở các vùng này. Không có dữ liệu thì hiển thị số 0 và hướng dẫn thêm giao dịch.
2. **Danh sách giao dịch:** stream giao dịch của UID hiện tại, sắp xếp theo `date` mới nhất rồi `createdAt` khi trùng ngày; hiển thị dấu `+`/`-`, tiền theo `1.250.000 ₫`, màu thu/chi, ngày Việt Nam. Tìm trong ghi chú/tên danh mục/số tiền. Chips lọc loại và bottom sheet lọc khoảng ngày, danh mục, khoảng tiền; có Đặt lại/Áp dụng. Lọc tại máy để không cần composite index, phù hợp quy mô dữ liệu của app này.
3. **Thêm/sửa giao dịch:** dùng chung một form. Chọn loại, nhập tiền VND, chọn danh mục tương ứng, chọn ngày bằng date picker gốc, ghi chú tùy chọn. Lưu bằng repository, khóa nút khi đang lưu, hiện lỗi tiếng Việt và trở về khi thành công.
4. **Chi tiết giao dịch:** tải document theo ID; hiển thị dữ liệu thật, nút sửa và xóa. Xóa cần xác nhận. Nếu document đã bị xóa từ nơi khác, hiện trạng thái không tìm thấy và cho quay lại.
5. **Danh mục:** thêm màn hình từ Cài đặt, tab Chi tiêu/Thu nhập, danh sách theo UID, form thêm/sửa tên, icon, màu, loại; giá trị icon/màu mặc định nếu bỏ trống. Xóa có xác nhận và chặn khi đang được sử dụng.
6. **Ngân sách:** lọc theo tháng, thêm/sửa/xóa ngân sách theo danh mục chi tiêu. Tính `spent` từ giao dịch chi tiêu cùng `categoryId` và tháng theo ngày trên thiết bị. `ratio = spent / limitAmount`; dưới 80% là An toàn, từ 80% đến dưới 100% là Sắp vượt, từ 100% là Đã vượt. Hiển thị số đã dùng, hạn mức, phần trăm và số còn/đã vượt. Giao dịch mới/sửa/xóa làm kết quả cập nhật theo stream.

Điều hướng tiếp tục qua `AppRoutes`; route chi tiết/sửa nhận transaction ID thay vì tiêu đề demo. Màn Báo cáo nâng cao giữ nguyên ngoài phạm vi Task 2 và phải được ghi rõ là demo nếu vẫn hiển thị số liệu mẫu.

## Validation, định dạng và trạng thái

Form kiểm tra tiền không rỗng và lớn hơn 0; loại, danh mục, ngày bắt buộc; ghi chú có thể rỗng. Danh mục cần tên không rỗng và loại hợp lệ. Ngân sách cần danh mục chi tiêu, tháng và hạn mức dương. Chuyển lỗi Firestore/Auth sang thông báo tiếng Việt, không đưa thông báo SDK thô lên UI.

Dùng formatter nhỏ cho VND, ngày `dd/MM/yyyy`, tháng `Tháng M, yyyy`; form chỉ chấp nhận số VND nguyên. Dùng theme mint/coral, khoảng cách và widget hiện có. Mỗi màn dữ liệu có trạng thái đang tải, lỗi kèm thử lại, và trống kèm hành động phù hợp; không để màn trắng.

## Ảnh hóa đơn

UI hiện không có chọn/chụp ảnh, project không có `image_picker` hoặc `firebase_storage`. Task 2 không thêm luồng upload mới. Giữ `receiptImageUrl` nullable trong model và ghi rõ việc thêm upload về sau; không thêm nút giả. `storage.rules` của Task 1 vẫn được giữ nguyên.

## Kiểm thử và điều kiện hoàn thành

- Unit test cho parse/format tiền, ngày/tháng, validation và ba ngưỡng ngân sách.
- Kiểm thử repository với Firebase Emulator: CRUD cả ba collection, ràng buộc ngân sách duy nhất, chặn xóa danh mục đang dùng, dữ liệu tách theo UID, cập nhật chi tiêu khi thêm/sửa/xóa giao dịch.
- Widget/integration test cho form, empty/error/loading và điều hướng sửa/xóa trọng yếu; kiểm thử thủ công trên Android emulator cho luồng chính.
- Chạy `flutter pub get`, `flutter analyze`, `flutter test`, rules test và `flutter run`. Không sửa rules thành public. Kiểm tra dữ liệu còn sau đăng xuất/đăng nhập và User B không thấy dữ liệu User A.

Không yêu cầu migrate dữ liệu demo cũ vào Firestore: chúng chưa từng là dữ liệu người dùng. Giữ nguyên các thay đổi Task 1 đang có trong working tree.
