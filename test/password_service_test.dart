import 'package:flutter_test/flutter_test.dart';
import 'package:net_utility_toolkit/features/password/password_service.dart';

void main() {
  group('PasswordService', () {
    late PasswordService service;

    setUp(() => service = PasswordService());

    // -----------------------------------------------------------------------
    // Length boundary tests (PRD section 18)
    // -----------------------------------------------------------------------

    test('throws when length < 4', () {
      expect(
        () => service.generate(
          length: 3,
          useUppercase: true,
          useLowercase: true,
          useDigits: true,
          useSymbols: false,
          excludedChars: '',
        ),
        throwsA(isA<PasswordServiceException>()),
      );
    });

    test('throws when length > 128', () {
      expect(
        () => service.generate(
          length: 129,
          useUppercase: true,
          useLowercase: true,
          useDigits: true,
          useSymbols: false,
          excludedChars: '',
        ),
        throwsA(isA<PasswordServiceException>()),
      );
    });

    test('generates password of exact requested length', () {
      for (final len in [4, 16, 64, 128]) {
        final pw = service.generate(
          length: len,
          useUppercase: true,
          useLowercase: true,
          useDigits: true,
          useSymbols: false,
          excludedChars: '',
        );
        expect(pw.length, len, reason: 'Expected length $len');
      }
    });

    // -----------------------------------------------------------------------
    // Character exclusion tests (PRD section 18)
    // -----------------------------------------------------------------------

    test('excluded characters are absent from output (statistical check)', () {
      const excluded = 'lIO0';
      final excludedSet = excluded.split('').toSet();

      for (int i = 0; i < 200; i++) {
        final pw = service.generate(
          length: 32,
          useUppercase: true,
          useLowercase: true,
          useDigits: true,
          useSymbols: false,
          excludedChars: excluded,
        );
        for (final char in pw.split('')) {
          expect(
            excludedSet.contains(char),
            isFalse,
            reason: 'Found excluded char "$char" in password "$pw"',
          );
        }
      }
    });

    test('throws when all characters are excluded', () {
      // Only digits selected, all digits excluded.
      expect(
        () => service.generate(
          length: 8,
          useUppercase: false,
          useLowercase: false,
          useDigits: true,
          useSymbols: false,
          excludedChars: '0123456789',
        ),
        throwsA(isA<PasswordServiceException>()),
      );
    });

    test('throws when no character types are selected', () {
      expect(
        () => service.generate(
          length: 8,
          useUppercase: false,
          useLowercase: false,
          useDigits: false,
          useSymbols: false,
          excludedChars: '',
        ),
        throwsA(isA<PasswordServiceException>()),
      );
    });

    test('duplicate excluded characters are handled idempotently', () {
      final pw = service.generate(
        length: 24,
        useUppercase: false,
        useLowercase: false,
        useDigits: true,
        useSymbols: false,
        excludedChars: '001122334455',
      );

      for (final char in pw.split('')) {
        expect('012345'.contains(char), isFalse);
      }
    });

    test('unicode exclusions do not corrupt the ASCII generation pool', () {
      final pw = service.generate(
        length: 32,
        useUppercase: true,
        useLowercase: true,
        useDigits: true,
        useSymbols: true,
        excludedChars: '你好🙂',
      );

      expect(pw.length, 32);
    });

    test('enabled character classes are sampled from the remaining pool', () {
      final pw = service.generate(
        length: 16,
        useUppercase: true,
        useLowercase: false,
        useDigits: true,
        useSymbols: false,
        excludedChars: '0123456789',
      );

      expect(pw, matches(RegExp(r'^[A-Z]+$')));
    });

    // -----------------------------------------------------------------------
    // Symbols flag
    // -----------------------------------------------------------------------

    test('symbols are absent when useSymbols is false', () {
      const symbolChars = r'!@#$%^&*()-_=+[]{}|;:,.<>?';
      final symbolSet = symbolChars.split('').toSet();

      for (int i = 0; i < 100; i++) {
        final pw = service.generate(
          length: 32,
          useUppercase: false,
          useLowercase: true,
          useDigits: true,
          useSymbols: false,
          excludedChars: '',
        );
        for (final char in pw.split('')) {
          expect(symbolSet.contains(char), isFalse);
        }
      }
    });
  });
}
