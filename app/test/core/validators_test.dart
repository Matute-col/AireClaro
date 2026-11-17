import 'package:aireclaro/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('no-es-correo'), isNotNull);
      expect(Validators.email('persona@ejemplo.test'), isNull);
    });

    test('password needs 8 to 72 characters', () {
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password('12345678'), isNull);
      expect(Validators.password('a' * 73), isNotNull);
    });

    test('confirmPassword must match', () {
      expect(Validators.confirmPassword('abcdefgh', 'abcdefgi'), 'Las contraseñas no coinciden.');
      expect(Validators.confirmPassword('abcdefgh', 'abcdefgh'), isNull);
    });

    test('docNumber follows the API rule', () {
      expect(Validators.docNumber('123'), isNotNull);
      expect(Validators.docNumber('1.234.567'), isNotNull);
      expect(Validators.docNumber('ab12345'), isNull); // uppercased like the API
    });

    test('phone is optional and ignores spaces and dashes', () {
      expect(Validators.phone(''), isNull);
      expect(Validators.phone('300 000-0000'), isNull);
      expect(Validators.phone('12345'), isNotNull);
    });

    test('fullName', () {
      expect(Validators.fullName(' '), isNotNull);
      expect(Validators.fullName('Ana Prueba'), isNull);
    });
  });
}
