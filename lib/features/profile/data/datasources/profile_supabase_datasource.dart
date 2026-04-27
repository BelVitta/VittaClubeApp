import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

class ProfileSupabaseDataSource {
  final SupabaseClient _supabase;

  ProfileSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  /// Busca o perfil (`profiles`) do usuário logado. `null` se não autenticado.
  Future<ProfileModel?> getCurrent() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _supabase
        .from('profiles')
        .select('id, name, email, avatar_url, role, member_since')
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return null;
    return ProfileModel.fromJson(row);
  }
}
