# Task 3: Trang chủ, báo cáo và trải nghiệm ứng dụng

## Mục tiêu và hiện trạng

Hoàn thiện trải nghiệm quản lý chi tiêu trên Android mà không thay Auth, cấu trúc Firestore riêng theo UID hay CRUD của Task 2. Trang chủ và Báo cáo phải phản ánh giao dịch/ngân sách thật của người đang đăng nhập; giao diện tiếng Việt, đọc được ở cả hai theme và không hiển thị con số mẫu như dữ liệu cá nhân.

Hiện tại Trang chủ đã nghe các stream Firestore nhưng hai số thu/chi là lũy kế, chỉ hiện ba giao dịch gần nhất và chưa có lời chào phụ. Báo cáo vẫn là mock cố định. Cài đặt chỉ bọc riêng màn Cài đặt bằng dark theme nên chuyển trang lại sáng. Project chưa có `fl_chart`, package PDF/Excel/chia sẻ, local notification hoặc local database riêng. Firestore trên Android có cache ngoại tuyến mặc định; stream hiện tại làm mất metadata cache khi map snapshot thành danh sách. Ba nút preview trong Cài đặt còn nhãn tiếng Anh. File `lib/data/demo_data.dart` không còn được luồng chính import.

## Phương án được chọn

Dùng một lớp tính toán thống kê thuần Dart nhận danh sách `FinanceTransaction`/`FinanceBudget` đã có; Home và Reports chỉ dựng dữ liệu đã tính. Giữ `FinanceRepository` và `StreamBuilder`, không thêm state-management framework. Vẽ donut phân bổ và đường xu hướng bằng `CustomPainter`/widget Flutter nhỏ, có nhãn và danh sách số liệu đi kèm để không phụ thuộc màu hoặc hình vẽ. Thanh so sánh thu/chi dùng widget gốc. Không thêm `fl_chart` chỉ cho hai màn này.

Một lựa chọn khác là đưa `fl_chart` cùng package xuất file/thông báo vào ngay: nhanh hơn để có nhiều kiểu biểu đồ nhưng tăng phụ thuộc và phạm vi build. Lựa chọn không làm biểu đồ vì chưa có package lại không đáp ứng mục tiêu Báo cáo. Hướng đã duyệt ưu tiên các biểu đồ đủ dùng từ Flutter sẵn có và chỉ thêm `shared_preferences` để lưu lựa chọn theme qua lần mở app.

## Quy tắc thống kê

Mọi phép tính dùng số nguyên VND từ giao dịch của UID hiện tại; ngày/tháng được xét theo giờ địa phương giống Task 2. Tổng thu/chi lũy kế gồm toàn bộ giao dịch; số dư = tổng thu trừ tổng chi, có thể âm. Thu và chi trên Trang chủ là **tháng lịch hiện tại**, không phải lũy kế. Giao dịch gần đây lấy năm phần tử mới nhất theo thứ tự repository đã sắp xếp.

Ngân sách Trang chủ chỉ gồm các ngân sách có `month == yyyy-MM` của tháng hiện tại. Tổng hạn mức là tổng `limitAmount`; số đã dùng chỉ cộng giao dịch chi tiêu có `categoryId` thuộc từng ngân sách và ngày nằm trong tháng đó. Tiến độ = đã dùng / hạn mức, thanh tiến độ chặn ở 100% nhưng số tiền và nhãn vẫn hiển thị phần vượt. Khi không có ngân sách, hiện lời mời tạo ngân sách, không chia cho 0 hoặc hiển thị phần trăm giả.

Báo cáo có bộ lọc Tuần / Tháng / Năm cho **khoảng hiện tại**: tuần từ thứ Hai đến trước thứ Hai tiếp theo; tháng và năm theo ranh giới lịch địa phương, đầu gồm/cuối không gồm. Trong khoảng đã chọn tính tổng thu, tổng chi, tiết kiệm (thu trừ chi, có thể âm), phân bổ chi tiêu theo `categoryId` và xu hướng. Phân bổ dùng tên/màu snapshot của giao dịch, gộp các giao dịch cùng ID; không sửa dữ liệu lịch sử khi đổi tên danh mục. Xu hướng nhóm theo ngày cho Tuần/Tháng, theo tháng cho Năm; các khoảng không có chi tiêu giữ giá trị 0 để trục thời gian không đứt đoạn. Donut chỉ vẽ khi tổng chi > 0, đường xu hướng chỉ vẽ khi có chi tiêu; nếu khoảng không có giao dịch thì hiện “Chưa đủ dữ liệu để tạo báo cáo”, không hiển thị biểu đồ rỗng. Nếu chỉ có thu nhập, thẻ tổng vẫn hiện đúng và vùng biểu đồ giải thích chưa có chi tiêu.

Thẻ so sánh tháng luôn so **tháng lịch hiện tại** với tháng liền trước, tách biệt bộ lọc của phần báo cáo. Nếu chi tháng trước > 0, phần trăm thay đổi = `(chi hiện tại - chi trước) / chi trước × 100`, làm tròn một chữ số thập phân và diễn đạt tăng/giảm/không đổi. Nếu tháng trước bằng 0, hiển thị “Chưa có dữ liệu tháng trước để so sánh” thay vì chia cho 0; khi cả hai bằng 0, hiển thị trạng thái chưa có chi tiêu.

## Màn hình và điều hướng

- **Trang chủ:** lời chào có tên nếu tồn tại, nếu không là “Xin chào!”; dòng phụ ngắn; số dư lũy kế; hai số thu/chi tháng này; tổng ngân sách, số đã dùng, phần trăm và còn/vượt; năm giao dịch gần đây. Thẻ và hành động giữ style mint/coral, spacing và typography sẵn có. Loading/error/trống được hiển thị rõ, có thử lại và hành động thêm giao dịch/ngân sách.
- **Báo cáo:** bỏ toàn bộ số liệu minh họa. SegmentedButton Tuần/Tháng/Năm đổi dữ liệu thật trên cùng screen; các thẻ tổng, donut kèm legend và số tiền, đường xu hướng kèm mốc thời gian, thẻ so sánh tháng và thanh thu/chi đều cùng nguồn giao dịch. Màn hình cuộn tốt ở điện thoại hẹp, biểu đồ có mô tả ngữ nghĩa và text thay thế.
- **Xuất báo cáo:** thêm hành động “Xuất báo cáo” dễ thấy trên Báo cáo. Vì project chưa có UI chọn khoảng ngày hoặc package xuất/chia sẻ file, bấm nút hiện đúng thông báo “Tính năng xuất báo cáo sẽ được hoàn thiện sau.” Không tạo PDF/XLSX giả hoặc nút không phản hồi.
- **Cài đặt/Dark Mode:** themeMode ở `QlctApp` điều khiển toàn app; switch Cài đặt cập nhật ngay và lưu trạng thái thiết bị bằng `shared_preferences` (không lưu theo UID). Hoàn thiện màu nền, chữ, thẻ, input, thanh điều hướng, màu thu/chi và biểu đồ ở dark mode. Không đổi thiết kế/màu nhận diện đã có. Preview trạng thái trong Cài đặt được giữ lại nhưng đổi Loading/Empty/Error sang tiếng Việt.
- **Trạng thái cache:** trên Android, dùng Firestore snapshot metadata để hiện nhãn trung thực khi dữ liệu đang đến từ cache, ví dụ “Đang hiển thị dữ liệu đã lưu; có thể chưa đồng bộ.” `isFromCache` không tự chứng minh thiết bị mất Internet nên không khẳng định “Bạn đang ngoại tuyến” chỉ dựa vào cờ này. Không thêm Drift hoặc bộ phát hiện mạng mới. Nếu không có dữ liệu cache và truy vấn lỗi, dùng error state với Thử lại.
- **Phản hồi thao tác:** giữ confirm trước xóa từ Task 2; sau lưu/xóa thành công hiện SnackBar tiếng Việt mà vẫn giữ cập nhật realtime. Các màn dữ liệu không để trắng khi user chưa đăng nhập, dữ liệu trống, `note` rỗng hoặc `receiptImageUrl` null.

`AppRoutes` và AuthGate hiện tại giữ nguyên; không thêm route giả. Mục Danh mục, Ngân sách và giao dịch tiếp tục điều hướng như Task 2. Chức năng hệ thống báo ngân sách không triển khai vì project chưa có package notification; các nhãn An toàn/Sắp vượt/Đã vượt trong app vẫn phản ánh dữ liệu thật.

## Ranh giới và khả năng tương thích

Không sửa Firestore rules thành public, không hardcode UID, không chuyển sang tiếng Anh, không migrate dữ liệu demo vào tài khoản thật. `lib/data/demo_data.dart` có thể xóa sau khi xác nhận không còn import; không xóa các màn preview của Cài đặt. Không đổi schema transaction/budget; các field `receiptImageUrl` nullable được bỏ qua an toàn. Báo cáo tính ở máy từ stream giao dịch người dùng, phù hợp quy mô app hiện tại; nếu dữ liệu tăng lớn thì phân trang/tổng hợp server là công việc khác, không được giả định đã có.

## Kiểm thử và điều kiện hoàn thành

- Unit test cho ranh giới tuần/tháng/năm, tháng 12 ↔ tháng 1, ngày địa phương, tổng thu/chi/số dư, tháng trước bằng 0, dữ liệu trống và nhóm danh mục/xu hướng.
- Widget test Trang chủ, Báo cáo và Dark Mode với dữ liệu giả **trong test**; kiểm tra nhãn tiền/ngày tiếng Việt, bộ lọc đổi nội dung, chart không vẽ khi trống, nút xuất có phản hồi, switch đổi theme toàn app.
- Android integration test qua Firebase Emulator cho luồng đăng nhập → thêm thu/chi → Home cập nhật → ngân sách cảnh báo → Báo cáo thay đổi → đăng xuất/đăng nhập lại; kiểm tra dữ liệu vẫn theo UID. Smoke test điện thoại hẹp và dark mode.
- Chạy `flutter pub get`, `flutter analyze`, `flutter test`, integration/rules test phù hợp và `flutter run`; xác nhận không có lỗi nghiêm trọng/overflow. Không chạm vào thay đổi Task 1/2 khác phạm vi đang nằm trong working tree.
