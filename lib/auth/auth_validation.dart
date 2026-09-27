abstract final class AuthValidation {
  static String? name(String? value) =>
      value == null || value.trim().isEmpty ? 'Vui lòng nhập họ tên.' : null;

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vui lòng nhập email.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Email không hợp lệ.';
    }
    return null;
  }

  static String? registrationPassword(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu.';
    if (value.length < 6) return 'Mật khẩu cần ít nhất 6 ký tự.';
    return null;
  }

  static String? loginPassword(String? value) =>
      value == null || value.isEmpty ? 'Vui lòng nhập mật khẩu.' : null;

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu.';
    return value != password ? 'Mật khẩu xác nhận không khớp.' : null;
  }
}
