import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/logging/app_logger.dart';
import '../models/consultation_model.dart';

class ConsultationSupabaseDataSource {
  final SupabaseClient _supabase;

  ConsultationSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  Future<List<ConsultationModel>> getForCurrentUser() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const [];

    try {
      return await _fetchForUser(
        userId: userId,
        select: 'id, title, subtitle, scheduled_date, status, professional_id, '
            'original_value, discount_percentage, discount_amount, final_value',
      );
    } on PostgrestException catch (e) {
      AppLogger.warning(
        'Falha ao buscar consultas com campos de desconto. Tentando fallback.',
        name: 'ConsultationSupabaseDataSource',
        error: e,
        context: {
          'code': e.code,
          'message': e.message,
          'details': e.details,
          'hint': e.hint,
        },
      );

      return await _fetchForUser(
        userId: userId,
        select: 'id, title, subtitle, scheduled_date, status, professional_id',
      );
    }
  }

  Future<List<ConsultationModel>> _fetchForUser({
    required String userId,
    required String select,
  }) async {
    final rows = await _supabase
        .from('consultations')
        .select(select)
        .eq('user_id', userId)
        .order('scheduled_date', ascending: false)
        .limit(20);

    return (rows as List)
        .map((row) => ConsultationModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<ConsultationModel> recordConsultation({
    required String userId,
    required String validatedBy,
    required double originalValue,
    required double discountPercentage,
    required double discountAmount,
    required double finalValue,
  }) async {
    final now = DateTime.now();
    final row = await _supabase
        .from('consultations')
        .insert({
          'user_id': userId,
          'validated_by': validatedBy,
          'title': 'Consulta',
          'scheduled_date': now.toIso8601String(),
          'status': 'realizada',
          'original_value': originalValue,
          'discount_percentage': discountPercentage,
          'discount_amount': discountAmount,
          'final_value': finalValue,
        })
        .select('id, title, subtitle, scheduled_date, status, professional_id,'
            ' original_value, discount_percentage, discount_amount, final_value')
        .single();

    return ConsultationModel.fromJson(row);
  }
}
