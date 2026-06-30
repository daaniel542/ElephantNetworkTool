import 'package:flutter_test/flutter_test.dart';
import 'package:net_utility_toolkit/features/converter/converter_service.dart';
import 'package:net_utility_toolkit/features/converter/converter_controller.dart';

void main() {
  group('ConverterService', () {
    late ConverterService service;

    setUp(() => service = ConverterService());

    // -----------------------------------------------------------------------
    // Base64 encode / decode
    // -----------------------------------------------------------------------

    test('Base64 encode round-trips correctly', () {
      const input = 'Hello, World!';
      final encoded = service.execute(
        input: input,
        operation: ConverterOperation.base64Encode,
      );
      final decoded = service.execute(
        input: encoded,
        operation: ConverterOperation.base64Decode,
      );
      expect(decoded, input);
    });

    test('Base64 decode throws on invalid input', () {
      expect(
        () => service.execute(
          input: '!!!not_base64!!!',
          operation: ConverterOperation.base64Decode,
        ),
        throwsA(isA<ConverterServiceException>()),
      );
    });

    // -----------------------------------------------------------------------
    // Hex encode / decode
    // -----------------------------------------------------------------------

    test('Hex encode round-trips correctly', () {
      const input = 'flutter';
      final encoded = service.execute(
        input: input,
        operation: ConverterOperation.hexEncode,
      );
      final decoded = service.execute(
        input: encoded,
        operation: ConverterOperation.hexDecode,
      );
      expect(decoded, input);
    });

    test('Hex decode throws on invalid input', () {
      expect(
        () => service.execute(
          input: 'ZZZZZZ',
          operation: ConverterOperation.hexDecode,
        ),
        throwsA(isA<ConverterServiceException>()),
      );
    });

    // -----------------------------------------------------------------------
    // Hash test vectors (PRD section 18)
    // -----------------------------------------------------------------------

    test('MD5 of empty string matches known vector', () {
      // echo -n "" | md5sum → d41d8cd98f00b204e9800998ecf8427e
      final result = service.execute(
        input: '',
        operation: ConverterOperation.md5,
      );
      expect(result, 'd41d8cd98f00b204e9800998ecf8427e');
    });

    test('MD5 of "hello" matches known vector', () {
      // echo -n "hello" | md5sum → 5d41402abc4b2a76b9719d911017c592
      final result = service.execute(
        input: 'hello',
        operation: ConverterOperation.md5,
      );
      expect(result, '5d41402abc4b2a76b9719d911017c592');
    });

    test('SHA-1 of "hello" matches known vector', () {
      // echo -n "hello" | sha1sum → aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d
      final result = service.execute(
        input: 'hello',
        operation: ConverterOperation.sha1,
      );
      expect(result, 'aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d');
    });

    test('SHA-256 of "hello" matches known vector', () {
      // echo -n "hello" | sha256sum →
      // 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
      final result = service.execute(
        input: 'hello',
        operation: ConverterOperation.sha256,
      );
      expect(
        result,
        '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
      );
    });
  });
}
