import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';

/// Inicializa e fornece acesso ao Supabase client.
/// Só inicializa em staging/prod (onde useSupabase == true).
class SupabaseConfig {
  static SupabaseClient? _client;

  /// Inicializa o Supabase. Deve ser chamado no main() após AppConfig.
  static Future<void> initialize() async {
    final config = AppConfig.instance;
    if (!config.useSupabase) return;
    _validateConfig(config);

    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  /// Retorna o client do Supabase.
  /// Lança erro se chamado em modo dev (mock).
  static SupabaseClient get client {
    if (_client == null) {
      throw StateError(
        'SupabaseClient não inicializado. '
        'Verifique se está em ambiente staging/prod.',
      );
    }
    return _client!;
  }

  /// Atalho para auth do Supabase.
  static GoTrueClient get auth => client.auth;

  /// Verifica se está inicializado.
  static bool get isInitialized => _client != null;

  static void _validateConfig(AppConfig config) {
    final isPlaceholder = config.supabaseUrl.contains('YOUR-PROJECT') ||
        config.supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY');
    final hasValidUrl = RegExp(r'^https://[a-z0-9]{20}\.supabase\.co/?$')
        .hasMatch(config.supabaseUrl);
    final hasAnonKey = config.supabaseAnonKey.startsWith('eyJ');

    if (isPlaceholder || !hasValidUrl || !hasAnonKey) {
      throw StateError(
        'Configuração Supabase inválida para ${config.environment.name}. '
        'Passe SUPABASE_URL e SUPABASE_ANON_KEY via --dart-define.',
      );
    }
  }
}
