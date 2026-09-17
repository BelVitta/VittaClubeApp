import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/professional_model.dart';

class ProfessionalsSupabaseDataSource {
  final SupabaseClient _supabase;

  ProfessionalsSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  Future<List<ProfessionalModel>> getActiveProfessionals() async {
    final rows = await _supabase
        .from('professionals')
        .select('id, name, available_days, availability_note, avatar_url,'
            ' avatar_bg_color, specialties(name)')
        .eq('is_active', true)
        .order('name');

    return (rows as List)
        .map((row) => ProfessionalModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
