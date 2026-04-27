import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Acesso a `public.clinic_settings` (key/value).
/// Cache em memória: a primeira leitura bate no Supabase; as seguintes usam
/// o mapa local até alguém chamar [invalidate] ou [set].
class ClinicSettingsService {
  static const String kDefaultWhatsapp = 'default_whatsapp';

  final Map<String, String> _cache = {};
  bool _loaded = false;

  SupabaseClient get _client => SupabaseConfig.client;

  /// Lê um valor. Faz uma rodada de fetch na primeira chamada.
  Future<String?> get(String key) async {
    if (!_loaded) await _loadAll();
    return _cache[key];
  }

  /// Atualiza (upsert) e invalida o cache.
  Future<void> set(String key, String value) async {
    await _client.from('clinic_settings').upsert({
      'key': key,
      'value': value,
    });
    _cache[key] = value;
  }

  /// Força nova leitura da tabela na próxima chamada de [get].
  void invalidate() {
    _loaded = false;
    _cache.clear();
  }

  Future<void> _loadAll() async {
    final rows =
        await _client.from('clinic_settings').select('key, value') as List;
    _cache.clear();
    for (final row in rows) {
      _cache[row['key'] as String] = row['value'] as String;
    }
    _loaded = true;
  }
}
