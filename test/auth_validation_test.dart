import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qlct/auth/auth_validation.dart';

void main() {
  test('registration rejects blank name and mismatched password', () {
    expect(AuthValidation.name('  '), isNotNull);
    expect(AuthValidation.confirmPassword('abcdef', 'abcdeg'), isNotNull);
    expect(AuthValidation.name('Minh Anh'), isNull);
    expect(AuthValidation.confirmPassword('abcdef', 'abcdef'), isNull);
  });

  test('email and password enforce registration boundaries', () {
    expect(AuthValidation.email(' '), isNotNull);
    expect(AuthValidation.email('wrong@'), isNotNull);
    expect(AuthValidation.email('minh@example.com'), isNull);
    expect(AuthValidation.registrationPassword('12345'), isNotNull);
    expect(AuthValidation.registrationPassword('123456'), isNull);
    expect(AuthValidation.loginPassword(''), isNotNull);
  });
}
