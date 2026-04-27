import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/subscription_model.dart';

class SubscriptionSupabaseDataSource {
  final SupabaseClient _supabase;

  SubscriptionSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  /// Retorna a assinatura ativa (`is_current = true`) do usuário logado.
  /// `null` se o usuário ainda não tem plano.
  Future<SubscriptionModel?> getCurrent() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _supabase
        .from('subscriptions')
        .select()
        .eq('user_id', userId)
        .eq('is_current', true)
        .maybeSingle();

    if (row == null) return null;
    return SubscriptionModel.fromJson(row);
  }

  /// Cria uma nova subscription marcando-a como a ativa do usuário. Antes,
  /// marca qualquer subscription anterior como `is_current = false` para não
  /// violar o índice único parcial.
  Future<SubscriptionModel> activate({
    required String planId,
    required String planLevelDb,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Nenhum usuário autenticado para ativar assinatura.');
    }

    // Desativa subscription anterior (se houver) para respeitar o UNIQUE parcial.
    await _supabase
        .from('subscriptions')
        .update({'is_current': false})
        .eq('user_id', userId)
        .eq('is_current', true);

    final inserted = await _supabase
        .from('subscriptions')
        .insert({
          'user_id': userId,
          'plan_id': planId,
          'badge_level': _badgeFromLevel(planLevelDb),
          'plan_level_status': planLevelDb,
          'is_current': true,
        })
        .select()
        .single();

    return SubscriptionModel.fromJson(inserted);
  }

  /// `plan_level_status` aceita 'inadimplente'/'cancelado' também, mas o enum
  /// `badge_level` só tem os 4 níveis reais. Mapeia com fallback seguro.
  String _badgeFromLevel(String level) {
    const validBadges = {'bronze', 'prata', 'ouro', 'diamante'};
    return validBadges.contains(level) ? level : 'bronze';
  }
}
