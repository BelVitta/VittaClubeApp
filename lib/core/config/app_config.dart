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
    _instance = AppConfig._(
      environment: Environment.dev,
      appName: 'Vita Clube Dev',
      supabaseUrl: '',
      supabaseAnonKey: '',
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

  /// Se deve conectar ao Supabase (staging e prod)
  bool get useSupabase => !useMockData && supabaseUrl.isNotEmpty;
}
