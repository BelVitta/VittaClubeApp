import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/plan_entity.dart';
import '../../domain/entities/subscription_type.dart';

/// Representa um plano exatamente como vem do Supabase, com o `id` real
/// (UUID) necessário para criar linhas em `payments` e `subscriptions`.
class RemotePlan {
  final String id;
  final String name;
  final SubscriptionType subscriptionType;
  final double price;
  final String? discountLabel;
  final List<PlanBenefit> benefits;

  const RemotePlan({
    required this.id,
    required this.name,
    required this.subscriptionType,
    required this.price,
    this.discountLabel,
    required this.benefits,
  });

  /// Converte para a entidade de UI. Preserva a lista real de benefícios do
  /// banco; o restante usa o enum para nomes e prices exibidos na interface.
  PlanEntity toPlanEntity() => PlanEntity(
        type: subscriptionType,
        name: name,
        price: price,
        discountLabel: discountLabel,
        benefits: benefits,
      );
}

class RemoteBadge {
  final String levelName;
  final String displayName;
  final int requiredMonths;
  final double discountPercentage;
  final int annualDrawLimit;
  final int sortOrder;

  const RemoteBadge({
    required this.levelName,
    required this.displayName,
    required this.requiredMonths,
    required this.discountPercentage,
    required this.annualDrawLimit,
    required this.sortOrder,
  });

  bool get allDraws => annualDrawLimit == -1;

  String get drawLabel {
    if (allDraws) return 'Todos os sorteios do ano';
    if (annualDrawLimit == 0) return 'Sem sorteios';
    return 'Até $annualDrawLimit sorteio${annualDrawLimit == 1 ? '' : 's'} por ano';
  }
}

class PlansCatalog {
  final List<RemotePlan> plans;
  final List<RemoteBadge> badges;

  const PlansCatalog({required this.plans, required this.badges});
}

/// Data source de leitura dos planos oferecidos (`plans` + `plan_benefits`).
class PlansSupabaseDataSource {
  final SupabaseClient _supabase;

  PlansSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  /// Busca todos os planos ativos e os benefícios associados em uma só chamada.
  /// Ordena por preço asc (mensal, semestral, anual).
  Future<PlansCatalog> getCatalog() async {
    final rows = await _supabase
        .from('plans')
        .select('id, name, subscription_type, price, discount_label, is_active,'
            ' plan_benefits(title, description, sort_order)')
        .eq('is_active', true)
        .eq('subscription_type', 'mensal')
        .order('price', ascending: true);

    final plans = rows.map<RemotePlan>((row) {
      final benefits = (row['plan_benefits'] as List<dynamic>? ?? [])
          .map((b) => PlanBenefit(
                title: b['title'] as String,
                description: b['description'] as String,
              ))
          .toList();

      return RemotePlan(
        id: row['id'] as String,
        name: row['name'] as String,
        subscriptionType:
            _subscriptionTypeFromDb(row['subscription_type'] as String),
        price: (row['price'] as num).toDouble(),
        discountLabel: row['discount_label'] as String?,
        benefits: benefits,
      );
    }).toList();

    List<dynamic> badgeRows;
    try {
      badgeRows = await _supabase
          .from('badges')
          .select('level_name, display_name, required_months, '
              'discount_percentage, annual_draw_limit, sort_order')
          .order('sort_order', ascending: true);
    } catch (_) {
      // Permite que uma versão já publicada continue exibindo o plano
      // enquanto a migração do novo campo comercial é aplicada.
      badgeRows = await _supabase
          .from('badges')
          .select('level_name, display_name, required_months, '
              'discount_percentage, sort_order')
          .order('sort_order', ascending: true);
    }
    final badges = badgeRows.map<RemoteBadge>((row) {
      return RemoteBadge(
        levelName: row['level_name'] as String,
        displayName: row['display_name'] as String,
        requiredMonths: row['required_months'] as int? ?? 0,
        discountPercentage:
            (row['discount_percentage'] as num?)?.toDouble() ?? 0,
        annualDrawLimit: row['annual_draw_limit'] as int? ?? 0,
        sortOrder: row['sort_order'] as int? ?? 0,
      );
    }).toList();
    return PlansCatalog(plans: plans, badges: badges);
  }

  Future<List<RemotePlan>> getActivePlans() async => (await getCatalog()).plans;

  SubscriptionType _subscriptionTypeFromDb(String raw) {
    switch (raw) {
      case 'mensal':
        return SubscriptionType.monthly;
      case 'semestral':
        return SubscriptionType.semiannual;
      case 'anual':
        return SubscriptionType.annual;
      default:
        return SubscriptionType.monthly;
    }
  }
}
