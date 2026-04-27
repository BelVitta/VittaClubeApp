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
  PlanEntity toPlanEntity() =>
      PlanEntity(type: subscriptionType, benefits: benefits);
}

/// Data source de leitura dos planos oferecidos (`plans` + `plan_benefits`).
class PlansSupabaseDataSource {
  final SupabaseClient _supabase;

  PlansSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  /// Busca todos os planos ativos e os benefícios associados em uma só chamada.
  /// Ordena por preço asc (mensal, semestral, anual).
  Future<List<RemotePlan>> getActivePlans() async {
    final rows = await _supabase
        .from('plans')
        .select('id, name, subscription_type, price, discount_label, is_active,'
            ' plan_benefits(title, description, sort_order)')
        .eq('is_active', true)
        .order('price', ascending: true);

    return rows.map<RemotePlan>((row) {
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
  }

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
