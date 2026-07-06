import '_secrets.dart';

enum Environment { dev, staging, prod }

class AppConfig {
  final Environment environment;
  final String appName;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool useMockData;

  AppConfig._({
    required this.environment,
    required this.appName,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
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
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    _instance = AppConfig._(
      environment: Environment.dev,
      appName: 'Vita Clube Dev',
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      useMockData: supabaseUrl.isEmpty || supabaseAnonKey.isEmpty,
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
      useMockData: false,
    );
  }

  bool get isDev => environment == Environment.dev;
  bool get isStaging => environment == Environment.staging;
  bool get isProd => environment == Environment.prod;
  String get qrSecret => _env(
        'QR_SECRET',
        fallback: 'local-dev-qr-secret',
      );

  /// InfiniteTag sem o $ inicial. Passe via --dart-define=INFINITY_PAY_HANDLE=...
  String get infinityPayHandle => _env(
        'INFINITY_PAY_HANDLE',
        fallback: kInfinityPayHandleDefault,
      );

  /// Se deve conectar ao Supabase (staging e prod)
  bool get useSupabase => !useMockData && supabaseUrl.isNotEmpty;

  static String _env(String key, {required String fallback}) {
    switch (key) {
      case 'QR_SECRET':
        return const String.fromEnvironment(
          'QR_SECRET',
          defaultValue: 'local-dev-qr-secret',
        );
      case 'INFINITY_PAY_HANDLE':
        return const String.fromEnvironment(
          'INFINITY_PAY_HANDLE',
          defaultValue: kInfinityPayHandleDefault,
        );
      default:
        return fallback;
    }
  }
}
