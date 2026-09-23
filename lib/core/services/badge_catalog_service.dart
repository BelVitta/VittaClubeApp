import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuração comercial das patentes, publicada pelo financeiro.
/// O app não mantém uma tabela paralela de descontos ou limites.
class BadgeCatalogEntry {
  final String levelName;
  final double discountPercentage;
  final int maxConsultationsPerMonth;
  final int requiredMonths;
  final int annualDrawLimit;

  const BadgeCatalogEntry({
    required this.levelName,
    required this.discountPercentage,
    required this.maxConsultationsPerMonth,
    required this.requiredMonths,
    required this.annualDrawLimit,
  });
}

class BadgeCatalogService {
  static final Map<String, BadgeCatalogEntry> _entries = {};

  Future<void> load(SupabaseClient client) async {
    List<dynamic> rows;
    try {
      rows = await client
          .from('badges')
          .select('level_name, discount_percentage, '
              'max_consultations_per_month, required_months, annual_draw_limit')
          .order('sort_order', ascending: true);
    } catch (_) {
      // Compatibilidade durante a aplicação da migração do limite de sorteios.
      rows = await client
          .from('badges')
          .select('level_name, discount_percentage, '
              'max_consultations_per_month, required_months')
          .order('sort_order', ascending: true);
    }

    _entries
      ..clear()
      ..addEntries(rows.map((row) {
        final level = (row['level_name'] as String).toLowerCase();
        return MapEntry(
          level,
          BadgeCatalogEntry(
            levelName: level,
            discountPercentage:
                (row['discount_percentage'] as num?)?.toDouble() ?? 0,
            maxConsultationsPerMonth:
                row['max_consultations_per_month'] as int? ?? 0,
            requiredMonths: row['required_months'] as int? ?? 0,
            annualDrawLimit: row['annual_draw_limit'] as int? ?? 0,
          ),
        );
      }));
  }

  static BadgeCatalogEntry? forLevel(String level) {
    final normalized = switch (level.toLowerCase()) {
      'silver' => 'prata',
      'gold' => 'ouro',
      'diamond' => 'diamante',
      final value => value,
    };
    return _entries[normalized];
  }

  static double discountFor(String level) =>
      forLevel(level)?.discountPercentage ?? 0;

  static int consultationsLimitFor(String level) =>
      forLevel(level)?.maxConsultationsPerMonth ?? 0;
}
