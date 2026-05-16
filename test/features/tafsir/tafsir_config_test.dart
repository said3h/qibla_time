import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/tafsir/services/tafsir_config.dart';

void main() {
  group('TafsirConfig', () {
    test('does not create API client unless explicitly enabled', () {
      const config = TafsirConfig(
        enabled: false,
        baseUrl: 'https://api.example.test/api/v4',
        authToken: 'token',
        clientId: 'client',
        defaultResourceId: '169',
      );

      expect(config.canCreateApiClient, isFalse);
      expect(config.normalizedDefaultResourceId, '169');
    });

    test('requires auth token and client id before API client can be created',
        () {
      const config = TafsirConfig(
        enabled: true,
        baseUrl: 'https://api.example.test/api/v4',
      );

      expect(config.canCreateApiClient, isFalse);
      expect(config.normalizedAuthToken, isNull);
      expect(config.normalizedClientId, isNull);
    });

    test('allows QUL preview client without Quran Foundation auth headers', () {
      const config = TafsirConfig(
        enabled: true,
        provider: 'qul_preview',
        baseUrl: 'https://qul.tarteel.ai',
      );

      expect(config.canCreateApiClient, isTrue);
      expect(config.isQulPreview, isTrue);
      expect(config.normalizedDefaultResourceId, '268');
    });

    test('accepts complete explicit configuration', () {
      const config = TafsirConfig(
        enabled: true,
        baseUrl: ' https://api.example.test/api/v4 ',
        authToken: ' token ',
        clientId: ' client ',
        defaultResourceId: ' 169 ',
      );

      expect(config.canCreateApiClient, isTrue);
      expect(config.baseUri.toString(), 'https://api.example.test/api/v4');
      expect(config.normalizedAuthToken, 'token');
      expect(config.normalizedClientId, 'client');
      expect(config.normalizedDefaultResourceId, '169');
    });

    test('rejects invalid default resource id', () {
      const config = TafsirConfig(
        enabled: true,
        baseUrl: 'https://api.example.test/api/v4',
        authToken: 'token',
        clientId: 'client',
        defaultResourceId: 'spanish-abridged',
      );

      expect(config.canCreateApiClient, isTrue);
      expect(config.normalizedDefaultResourceId, isNull);
    });
  });
}
