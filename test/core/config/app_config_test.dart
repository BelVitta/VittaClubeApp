import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/core/config/app_config.dart';

void main() {
  // Reset singleton entre testes
  // AppConfig usa singleton, precisamos testar cada init separadamente

  group('AppConfig', () {
    test('initDev configura mock data e ambiente dev', () {
      AppConfig.initDev();
      final config = AppConfig.instance;

      expect(config.isDev, isTrue);
      expect(config.isStaging, isFalse);
      expect(config.isProd, isFalse);
      expect(config.useMockData, isTrue);
      expect(config.useSupabase, isFalse);
      expect(config.appName, 'Vita Clube Dev');
    });

    test('initStaging configura Supabase staging', () {
      AppConfig.initStaging();
      final config = AppConfig.instance;

      expect(config.isStaging, isTrue);
      expect(config.useMockData, isFalse);
      expect(config.appName, 'Vita Clube Staging');
    });

    test('initProd configura Supabase prod', () {
      AppConfig.initProd();
      final config = AppConfig.instance;

      expect(config.isProd, isTrue);
      expect(config.useMockData, isFalse);
      expect(config.appName, 'Vita Clube');
    });

    test('isInitialized retorna true após init', () {
      AppConfig.initDev();
      expect(AppConfig.isInitialized, isTrue);
    });
  });
}
