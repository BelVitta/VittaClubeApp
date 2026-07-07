import '_secrets.dart';

enum Environment { dev, staging, prod }

class AppConfig {
  final Environment environment;
  final String appName;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String infinityPayHandle;
  final String infinityPayRedirectUrl;
  final String infinityPayWebhookUrl;
  final bool useMockData;

  AppConfig._({
    required this.environment,
    required this.appName,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.infinityPayHandle,
    required this.infinityPayRedirectUrl,
    required this.infinityPayWebhookUrl,
    required this.useMockData,
  });

  static AppConfig? _instance;

  static AppConfig get instance {
    if (_instance == null) {
      throw StateError(
        'AppConfig não foi inicializado. '
        'Chame AppConfig.initDev(), initStaging() ou initProd() no entry point.',
      );
    }
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  /// Dev: dados mock, sem Supabase
  static void initDev() {
    _instance = AppConfig._(
      environment: Environment.dev,
      appName: 'Vita Clube Dev',
      supabaseUrl: '',
      supabaseAnonKey: '',
      infinityPayHandle: const String.fromEnvironment(
        'INFINITYPAY_HANDLE',
        defaultValue: 'vinicius-belchior-car',
      ),
      infinityPayRedirectUrl: const String.fromEnvironment(
        'INFINITYPAY_REDIRECT_URL',
        defaultValue: 'vittaclube://payment/infinitypay/return',
      ),
      infinityPayWebhookUrl: const String.fromEnvironment(
        'INFINITYPAY_WEBHOOK_URL',
        defaultValue: '',
      ),
      useMockData: true,
    );
  }

  /// Staging: por enquanto aponta para o MESMO projeto de produção.
  /// Quando o projeto `vita-clube-dev` for criado, trocar as credenciais aqui.
  /// Ver SETUP_DEV_PROD.md na raiz do repo.
  static void initStaging() {
    _instance = AppConfig._(
      environment: Environment.staging,
      appName: 'Vita Clube Staging',
      supabaseUrl: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: kSupabaseUrlDefault,
      ),
      supabaseAnonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: kSupabaseAnonKeyDefault,
      ),
      infinityPayHandle: const String.fromEnvironment(
        'INFINITYPAY_HANDLE',
        defaultValue: 'vinicius-belchior-car',
      ),
      infinityPayRedirectUrl: const String.fromEnvironment(
        'INFINITYPAY_REDIRECT_URL',
        defaultValue: 'vittaclube://payment/infinitypay/return',
      ),
      infinityPayWebhookUrl: const String.fromEnvironment(
        'INFINITYPAY_WEBHOOK_URL',
        defaultValue: '',
      ),
      useMockData: false,
    );
  }

  /// Prod: Supabase real (projeto de produção)
  static void initProd() {
    _instance = AppConfig._(
      environment: Environment.prod,
      appName: 'Vita Clube',
      supabaseUrl: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: kSupabaseUrlDefault,
      ),
      supabaseAnonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: kSupabaseAnonKeyDefault,
      ),
      infinityPayHandle: const String.fromEnvironment(
        'INFINITYPAY_HANDLE',
        defaultValue: 'vinicius-belchior-car',
      ),
      infinityPayRedirectUrl: const String.fromEnvironment(
        'INFINITYPAY_REDIRECT_URL',
        defaultValue: 'vittaclube://payment/infinitypay/return',
      ),
      infinityPayWebhookUrl: const String.fromEnvironment(
        'INFINITYPAY_WEBHOOK_URL',
        defaultValue: '',
      ),
      useMockData: false,
    );
  }

  bool get isDev => environment == Environment.dev;
  bool get isStaging => environment == Environment.staging;
  bool get isProd => environment == Environment.prod;

  /// Se deve conectar ao Supabase (staging e prod)
  bool get useSupabase => !useMockData && supabaseUrl.isNotEmpty;

  String get resolvedInfinityPayWebhookUrl {
    if (infinityPayWebhookUrl.isNotEmpty) return infinityPayWebhookUrl;
    if (supabaseUrl.isEmpty) return '';
    return '$supabaseUrl/functions/v1/infinitypay-webhook';
  }
}
