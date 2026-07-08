import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Acesso a `public.clinic_settings` (key/value).
/// Cache em memória: a primeira leitura bate no Supabase; as seguintes usam
/// o mapa local até alguém chamar [invalidate] ou [set].
class ClinicSettingsService {
  static const String kDefaultWhatsapp = 'default_whatsapp';
  static const String kMaxDependentsPerHolder = 'max_dependents_per_holder';
  static const String kMonthlyUsesPerDependent = 'monthly_uses_per_dependent';

  static const int defaultMaxDependentsPerHolder = 2;
  static const int defaultMonthlyUsesPerDependent = 3;

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

  /// Máximo de dependentes por titular.
  Future<int> getMaxDependentsPerHolder() async {
    final value = await get(kMaxDependentsPerHolder);
    return int.tryParse(value ?? '') ?? defaultMaxDependentsPerHolder;
  }

  /// Usos mensais por dependente.
  Future<int> getMonthlyUsesPerDependent() async {
    final value = await get(kMonthlyUsesPerDependent);
    return int.tryParse(value ?? '') ?? defaultMonthlyUsesPerDependent;
  }

  /// Salva o máximo de dependentes por titular.
  Future<void> setMaxDependentsPerHolder(int max) =>
      set(kMaxDependentsPerHolder, max.toString());

  /// Salva os usos mensais por dependente.
  Future<void> setMonthlyUsesPerDependent(int uses) =>
      set(kMonthlyUsesPerDependent, uses.toString());

  /// Pré-popula o cache em memória sem bater no Supabase. Usado em testes.
  void seedCacheForTesting(Map<String, String> values) {
    _cache
      ..clear()
      ..addAll(values);
    _loaded = true;
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
