# Firebase setup cho QLCT

Project đã được FlutterFire liên kết với Firebase project `qlct-125e8` trên Android, Web và Windows qua `lib/firebase_options.dart`. File cấu hình chỉ chứa định danh ứng dụng; quyền truy cập dữ liệu được quyết định bởi Authentication và Security Rules.

## 1. Authentication

1. Mở [Firebase Console](https://console.firebase.google.com/) và chọn project `qlct-125e8`.
2. Vào **Authentication → Sign-in method**.
3. Bật **Email/Password** rồi lưu.
4. Trong **Authentication → Settings → Authorized domains**, kiểm tra domain Web nếu chạy trên Web.

Ứng dụng hiện dùng Email/Password. Nút Google demo cũ đã được bỏ vì chưa có Google Sign-In thật. Khi thêm Google sau này, bật provider Google, cấu hình SHA-1/SHA-256 cho Android và chạy lại `flutterfire configure`.

## 2. Cloud Firestore

1. Project `qlct-125e8` đã có Firestore database mặc định. Với project Firebase khác, vào **Firestore Database → Create database**.
2. Khi tạo database mới, chọn location gần người dùng; location của database đã tạo không thể đổi.
3. Dùng chế độ rules bảo vệ, không để rules public.
4. File `firestore.rules` trong repo cho phép mỗi UID chỉ truy cập `users/{uid}` và các collection con `categories`, `transactions`, `budgets` của chính UID đó.
5. Kiểm tra file, rồi triển khai rules bằng `firebase deploy --only firestore:rules --project qlct-125e8` hoặc dán nội dung vào tab **Rules** của Firestore và bấm **Publish**.

Rules trong repo **không tự áp dụng lên Firebase**. Bản `firestore.rules` này đã được triển khai lên project `qlct-125e8` trong Task 1. Khi sửa rules hoặc chuyển sang project khác, phải triển khai lại trước khi thử đăng ký; nếu chưa publish, việc tạo hồ sơ có thể bị `permission-denied`.

### Cấu trúc dữ liệu

```text
users/{uid}
  fullName: string
  email: string
  createdAt: timestamp
  updatedAt: timestamp
  categories/{categoryId}
    name, icon, color, type (income | expense), createdAt, updatedAt
  transactions/{transactionId}
    amount, categoryId, categoryName, categoryIcon, categoryColor,
    type (income | expense), note, date, receiptImageUrl, createdAt, updatedAt
  budgets/{budgetId}
    categoryId, categoryName, limitAmount, month, createdAt, updatedAt
```

Task 1 chỉ ghi hồ sơ và 13 danh mục mặc định; giao dịch và ngân sách vẫn hiển thị dữ liệu demo. Các danh mục có ID cố định như `expense-food` và `income-salary` để không tạo trùng khi cần khôi phục hồ sơ.

## 3. Cloud Storage

Ứng dụng hiện chưa upload ảnh hóa đơn. File `storage.rules` đã chuẩn bị quyền sở hữu tại `receipts/{uid}/{transactionId}/{fileName}`. Khi bổ sung upload:

1. Bật **Storage** trong Firebase Console, chọn location và hoàn tất thiết lập bucket. Console có thể yêu cầu gói Blaze.
2. Triển khai bằng `firebase deploy --only storage --project qlct-125e8` hoặc publish trong tab **Rules** của Storage.
3. Thêm package `firebase_storage` và chạy lại `flutterfire configure` nếu bucket hoặc nền tảng thay đổi.

## 4. Chạy ứng dụng

Trong thư mục project:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Nếu thêm hoặc đổi Firebase project / nền tảng / sản phẩm, chạy `flutterfire configure --project=qlct-125e8`, kiểm tra lại `lib/firebase_options.dart` và `android/app/google-services.json`, rồi build lại ứng dụng.

## 5. Kiểm tra dữ liệu và quyền

1. Đăng ký email mới bằng app. Trong **Authentication → Users**, xác nhận tài khoản có UID mới.
2. Trong Firestore, kiểm tra `users/{uid}` có `fullName`, `email`, `createdAt`, `updatedAt` và `categories` có 13 document (8 chi tiêu, 5 thu nhập).
3. Đăng xuất, đăng nhập lại, đóng rồi mở app: phiên đăng nhập phải được khôi phục.
4. Ở màn hình Đăng nhập, bấm **Quên mật khẩu?** và kiểm tra email đặt lại mật khẩu. Kiểm tra cả thư mục spam.
5. Chạy rules test ở dưới: người chưa đăng nhập và User B không đọc/ghi dữ liệu của User A.

Kiểm thử Firestore rules cục bộ yêu cầu Node.js và Java 21+:

```bash
npm install --prefix rules_test
firebase emulators:exec --only firestore,storage "npm --prefix rules_test test" --project demo-qlct-rules
```

Kiểm thử tích hợp Auth + tạo hồ sơ trên Android emulator (không tạo tài khoản thật trên Firebase):

```bash
firebase emulators:start --only auth,firestore --project demo-qlct-rules
# Ở terminal khác, sau khi emulator Android đã chạy:
flutter test integration_test/auth_flow_test.dart -d emulator-5554
```

`10.0.2.2` trong bài test là địa chỉ máy host nhìn từ Android emulator; không dùng test này trên thiết bị Android thật nếu chưa chỉnh địa chỉ host.
Manifest Android bản debug cho phép HTTP tới emulator; bản release không bật quyền này.

## 6. Lỗi thường gặp

| Hiện tượng | Cách xử lý |
|---|---|
| `operation-not-allowed` | Bật Email/Password trong Authentication. |
| `permission-denied` khi đăng ký | Tạo Firestore database và publish `firestore.rules` cho đúng project. |
| `email-already-in-use` | Dùng email khác hoặc đăng nhập. Nếu lần đăng ký trước tạo Auth nhưng ghi Firestore thất bại, đăng nhập lại để app tạo hồ sơ còn thiếu. |
| `network-request-failed` | Kiểm tra mạng của thiết bị/emulator. |
| Web báo `unauthorized-domain` | Thêm domain trong Authentication → Authorized domains. |
| Không thấy email reset | Kiểm tra email, spam và template email của Authentication. |
| Firebase app không khởi động | Kiểm tra project ID, package name và chạy lại `flutterfire configure`. |
| Rules test không chạy | Cài Java 21+, Node.js, Firebase CLI và bảo đảm cổng 8080 còn trống. |
| Kotlin báo `this and base files have different roots` | Project ở ổ D: còn Pub cache ở ổ C:. `android/gradle.properties` đã tắt Kotlin incremental để tránh lỗi cache chéo ổ đĩa. |

Tham khảo tài liệu chính thức: [FlutterFire setup](https://firebase.google.com/docs/flutter/setup), [Email/Password Auth](https://firebase.google.com/docs/auth/flutter/password-auth), [Firestore rules](https://firebase.google.com/docs/firestore/security/rules-conditions), [triển khai rules](https://firebase.google.com/docs/rules/manage-deploy), [Storage Flutter](https://firebase.google.com/docs/storage/flutter/start).
