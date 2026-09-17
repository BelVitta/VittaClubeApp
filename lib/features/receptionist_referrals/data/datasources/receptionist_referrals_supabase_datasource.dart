import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/receptionist_referral_entity.dart';
import '../models/receptionist_ranking_entry_model.dart';
import '../models/receptionist_referral_model.dart';

const _referralSelect = 'id, receptionist_id, referral_code, referred_user_id, '
    'status, converted_at, plan_id_at_conversion, plan_price_at_conversion, '
    'month_reference, created_at, '
    'receptionist:profiles!receptionist_id(name), '
    'referred:profiles!referred_user_id(name,email,member_since), '
    'plan:plans!plan_id_at_conversion(name)';

class ReceptionistReferralsSupabaseDataSource {
  final SupabaseClient _supabase;

  ReceptionistReferralsSupabaseDataSource(
      {required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  Future<List<ReceptionistRankingEntryModel>> getMonthlyRanking(
    String monthReference,
  ) async {
    try {
      final data = await _supabase.rpc(
        'get_receptionist_monthly_ranking',
        params: {'p_month_reference': monthReference},
      );
      final rows = (data as List).cast<Map<String, dynamic>>();
      return [
        for (var i = 0; i < rows.length; i++)
          ReceptionistRankingEntryModel.fromRow(rows[i], position: i + 1),
      ];
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar ranking: $e');
    }
  }

  /// Busca por nome do indicado é feita client-side (bloc), seguindo o
  /// mesmo padrão do restante do painel admin.
  Future<List<ReceptionistReferralModel>> getReferrals({
    String? monthReference,
    String? receptionistId,
    ReceptionistReferralStatus? status,
  }) async {
    try {
      var query =
          _supabase.from('receptionist_referrals').select(_referralSelect);

      if (monthReference != null) {
        final start = DateTime.parse('$monthReference-01');
        final end = DateTime(start.year, start.month + 1, 1);
        query = query
            .gte('created_at', start.toIso8601String())
            .lt('created_at', end.toIso8601String());
      }
      if (receptionistId != null) {
        query = query.eq('receptionist_id', receptionistId);
      }
      if (status != null) {
        query = query.eq('status', status.name);
      }

      final data = await query.order('created_at', ascending: false);
      return (data as List)
          .map((e) =>
              ReceptionistReferralModel.fromRow(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar indicações: $e');
    }
  }

  Future<void> correctAttribution({
    required String referralId,
    required String newReceptionistId,
    required String reason,
  }) async {
    try {
      await _supabase.rpc('correct_receptionist_referral', params: {
        'p_referral_id': referralId,
        'p_new_receptionist_id': newReceptionistId,
        'p_reason': reason,
      });
    } catch (e) {
      throw ServerException(message: 'Erro ao corrigir atribuição: $e');
    }
  }
}
