import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/consultation_model.dart';

class ConsultationSupabaseDataSource {
  final SupabaseClient _supabase;

  ConsultationSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  Future<List<ConsultationModel>> getForCurrentUser() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const [];

    final rows = await _supabase
        .from('consultations')
        .select('id, title, subtitle, scheduled_date, status, professional_id,'
            ' professionals(name, specialty_id, specialties(name))')
        .eq('user_id', userId)
        .order('scheduled_date', ascending: false)
        .limit(20);

    return (rows as List)
        .map((row) => ConsultationModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
