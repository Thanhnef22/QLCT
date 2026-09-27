import 'package:firebase_auth/firebase_auth.dart';

abstract final class AuthErrorMapper {
  static String message(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'Email không hợp lệ.',
        'weak-password' => 'Mật khẩu quá yếu.',
        'user-not-found' => 'Tài khoản không tồn tại.',
        'wrong-password' => 'Sai mật khẩu.',
        'invalid-credential' ||
        'invalid-login-credentials' => 'Email hoặc mật khẩu không đúng.',
        'email-already-in-use' => 'Email đã được sử dụng.',
        'network-request-failed' => 'Không có kết nối mạng. Vui lòng thử lại.',
        'too-many-requests' =>
          'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.',
        'user-disabled' => 'Tài khoản đã bị vô hiệu hóa.',
        'operation-not-allowed' =>
          'Đăng nhập bằng email chưa được bật trên Firebase.',
        _ => 'Thao tác thất bại. Vui lòng thử lại.',
      };
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'unavailable' ||
        'network-request-failed' => 'Không có kết nối mạng. Vui lòng thử lại.',
        'permission-denied' => 'Bạn không có quyền truy cập dữ liệu này.',
        _ => 'Không thể lưu dữ liệu. Vui lòng thử lại.',
      };
    }
    return 'Thao tác thất bại. Vui lòng thử lại.';
  }
}
