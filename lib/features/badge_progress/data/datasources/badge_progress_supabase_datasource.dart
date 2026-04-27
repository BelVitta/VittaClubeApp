import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/badge_progress_model.dart';

class BadgeProgressSupabaseDataSource {
  final SupabaseClient _supabase;

  BadgeProgressSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  Future<BadgeProgressModel> getProgress(String userId) async {
    try {
      final data = await _supabase
          .from('badge_progress')
          .select('user_id, current_badge_level, consultation_count, referral_count, plan_activation_date, has_annual_plan, profiles(member_since)')
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) {
        final profile = await _supabase
            .from('profiles')
            .select('member_since')
            .eq('id', userId)
            .single();
        return BadgeProgressModel(
          userId: userId,
          currentBadgeLevel: 'bronze',
          consultationCount: 0,
          referralCount: 0,
          memberSince: DateTime.parse(profile['member_since'] as String),
        );
      }
      return _fromRow(data);
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar progresso: $e');
    }
  }

  Future<BadgeProgressModel> checkAndUpgrade(String userId) async {
    try {
      final progress = await getProgress(userId);
      String newLevel = progress.currentBadgeLevel;
      if (progress.canUpgradeToDiamond) {
        newLevel = 'diamante';
      } else if (progress.canUpgradeToGold) {
        newLevel = 'ouro';
      } else if (progress.canUpgradeToSilver) {
        newLevel = 'prata';
      }
      if (newLevel != progress.currentBadgeLevel) {
        await _supabase
            .from('badge_progress')
            .update({
              'current_badge_level': newLevel,
              'last_upgrade_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
        await _supabase
            .from('subscriptions')
            .update({'badge_level': newLevel})
            .eq('user_id', userId)
            .eq('is_current', true);
      }
      return getProgress(userId);
    } catch (e) {
      throw ServerException(message: 'Erro ao verificar upgrade: $e');
    }
  }

  Future<BadgeProgressModel> updateProgress(BadgeProgressModel progress) async {
    try {
      await _supabase
          .from('badge_progress')
          .upsert({
            'user_id': progress.userId,
            'current_badge_level': progress.currentBadgeLevel,
            'consultation_count': progress.consultationCount,
            'referral_count': progress.referralCount,
            'plan_activation_date':
                progress.planActivationDate?.toIso8601String(),
            'has_annual_plan': progress.hasAnnualPlan,
          })
          .eq('user_id', progress.userId);
      return getProgress(progress.userId);
    } catch (e) {
      throw ServerException(message: 'Erro ao atualizar progresso: $e');
    }
  }

  BadgeProgressModel _fromRow(Map<String, dynamic> e) {
    final memberSince =
        (e['profiles'] as Map<String, dynamic>?)?['member_since'] as String? ??
            DateTime.now().toIso8601String();
    return BadgeProgressModel(
      userId: e['user_id'] as String,
      currentBadgeLevel: e['current_badge_level'] as String,
      consultationCount: e['consultation_count'] as int? ?? 0,
      referralCount: e['referral_count'] as int? ?? 0,
      memberSince: DateTime.parse(memberSince),
      planActivationDate: e['plan_activation_date'] != null
          ? DateTime.parse(e['plan_activation_date'] as String)
          : null,
      hasAnnualPlan: e['has_annual_plan'] as bool? ?? false,
    );
  }
}
