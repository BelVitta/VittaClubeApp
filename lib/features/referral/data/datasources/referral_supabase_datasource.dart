import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/error/exceptions.dart';
import '../models/referral_model.dart';
import '../../domain/entities/referral_entity.dart';

class ReferralSupabaseDataSource {
  final SupabaseClient _supabase;

  ReferralSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  Future<List<ReferralModel>> getReferralsByUser(String userId) async {
    try {
      final data = await _supabase
          .from('referrals')
          .select('id, referrer_id, referred_id, referral_code, status, referred_completed_consultation, activated_at, reward_claimed_at, created_at, referrer:profiles!referrer_id(name), referred:profiles!referred_id(name)')
          .eq('referrer_id', userId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => _fromRow(e)).toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar indicações: $e');
    }
  }

  Future<ReferralModel> createReferral(String userId) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('name')
          .eq('id', userId)
          .single();
      final code = _generateCode();
      final data = await _supabase
          .from('referrals')
          .insert({
            'referrer_id': userId,
            'referral_code': code,
            'status': 'pending',
          })
          .select('id')
          .single();
      return ReferralModel(
        id: data['id'] as String,
        referrerId: userId,
        referrerName: profile['name'] as String,
        referralCode: code,
        status: ReferralStatus.pending,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw ServerException(message: 'Erro ao criar indicação: $e');
    }
  }

  Future<ReferralModel> validateReferralCode(
      String code, String referredUserId) async {
    try {
      final data = await _supabase
          .from('referrals')
          .select('id, status, referrer_id')
          .eq('referral_code', code)
          .maybeSingle();
      if (data == null) {
        throw const AuthException(message: 'Código de indicação inválido.');
      }
      if (data['status'] != 'pending') {
        throw const AuthException(message: 'Esta indicação já foi utilizada.');
      }
      await _supabase
          .from('referrals')
          .update({'status': 'active', 'referred_id': referredUserId, 'activated_at': DateTime.now().toIso8601String()})
          .eq('id', data['id'] as String);
      final updated = await _supabase
          .from('referrals')
          .select('id, referrer_id, referred_id, referral_code, status, referred_completed_consultation, activated_at, reward_claimed_at, created_at, referrer:profiles!referrer_id(name), referred:profiles!referred_id(name)')
          .eq('id', data['id'] as String)
          .single();
      return _fromRow(updated);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(message: 'Erro ao validar indicação: $e');
    }
  }

  Future<ReferralModel> claimReward(String referralId) async {
    try {
      await _supabase
          .from('referrals')
          .update({'status': 'rewarded', 'reward_claimed_at': DateTime.now().toIso8601String()})
          .eq('id', referralId);
      final data = await _supabase
          .from('referrals')
          .select('id, referrer_id, referred_id, referral_code, status, referred_completed_consultation, activated_at, reward_claimed_at, created_at, referrer:profiles!referrer_id(name), referred:profiles!referred_id(name)')
          .eq('id', referralId)
          .single();
      return _fromRow(data);
    } catch (e) {
      throw ServerException(message: 'Erro ao resgatar recompensa: $e');
    }
  }

  Future<int> getReferralCountThisMonth(String userId) async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1).toIso8601String();
      final data = await _supabase
          .from('referrals')
          .select('id')
          .eq('referrer_id', userId)
          .gte('created_at', start);
      return (data as List).length;
    } catch (e) {
      throw ServerException(message: 'Erro ao contar indicações: $e');
    }
  }

  Future<ReferralModel> getReferralByCode(String code) async {
    try {
      final data = await _supabase
          .from('referrals')
          .select('id, referrer_id, referred_id, referral_code, status, referred_completed_consultation, activated_at, reward_claimed_at, created_at, referrer:profiles!referrer_id(name), referred:profiles!referred_id(name)')
          .eq('referral_code', code)
          .single();
      return _fromRow(data);
    } catch (e) {
      throw ServerException(message: 'Código não encontrado: $e');
    }
  }

  ReferralModel _fromRow(Map<String, dynamic> e) {
    final referrerName =
        (e['referrer'] as Map<String, dynamic>?)?['name'] as String? ?? '';
    final referredName =
        (e['referred'] as Map<String, dynamic>?)?['name'] as String?;
    return ReferralModel(
      id: e['id'] as String,
      referrerId: e['referrer_id'] as String,
      referrerName: referrerName,
      referredId: e['referred_id'] as String?,
      referredName: referredName,
      referralCode: e['referral_code'] as String,
      status: ReferralStatus.values.firstWhere(
        (s) => s.name == e['status'],
        orElse: () => ReferralStatus.pending,
      ),
      createdAt: DateTime.parse(e['created_at'] as String),
      activatedAt: e['activated_at'] != null
          ? DateTime.parse(e['activated_at'] as String)
          : null,
      rewardClaimedAt: e['reward_claimed_at'] != null
          ? DateTime.parse(e['reward_claimed_at'] as String)
          : null,
      referredCompletedConsultation:
          e['referred_completed_consultation'] as bool? ?? false,
    );
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return 'VITA${String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))))}';
  }
}
