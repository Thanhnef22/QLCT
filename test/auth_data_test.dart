import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qlct/auth/auth_error_mapper.dart';
import 'package:flutter_qlct/auth/default_categories.dart';

void main() {
  test('new users receive distinct income and expense categories', () {
    final categories = DefaultCategories.all;
    expect(categories.length, 13);
    expect(categories.where((item) => item.type == 'expense').length, 8);
    expect(categories.where((item) => item.type == 'income').length, 5);
    expect(categories.map((item) => item.id).toSet().length, 13);
    expect(
      categories.map((item) => item.name),
      containsAll(['Ăn uống', 'Lương']),
    );
    expect(
      categories.every((item) => item.icon.isNotEmpty && item.color.isNotEmpty),
      isTrue,
    );
  });

  test('Firebase errors are never shown as raw English messages', () {
    expect(
      AuthErrorMapper.message(
        FirebaseAuthException(code: 'email-already-in-use'),
      ),
      'Email đã được sử dụng.',
    );
    expect(
      AuthErrorMapper.message(FirebaseAuthException(code: 'wrong-password')),
      'Sai mật khẩu.',
    );
    expect(
      AuthErrorMapper.message(
        FirebaseAuthException(code: 'operation-not-allowed'),
      ),
      'Đăng nhập bằng email chưa được bật trên Firebase.',
    );
    expect(
      AuthErrorMapper.message(
        FirebaseAuthException(code: 'unknown', message: 'Internal error'),
      ),
      'Thao tác thất bại. Vui lòng thử lại.',
    );
  });
}
