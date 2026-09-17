import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

class ProfileSupabaseDataSource {
  final SupabaseClient _supabase;

  ProfileSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  /// Busca o perfil (`profiles`) do usuário logado. `null` se não autenticado.
  Future<ProfileModel?> getCurrent() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    // Recovery: cria linha em profiles se o trigger de signup falhou.
    try {
      await _supabase.rpc('ensure_own_profile');
    } catch (_) {}

    // Garante member_code em contas antigas / recovery.
    try {
      await _supabase.rpc('assign_member_code_if_missing', params: {
        'p_user_id': user.id,
      });
    } catch (_) {}

    var row = await _supabase
        .from('profiles')
        .select(
            'id, name, email, avatar_url, role, member_since, member_code, receptionist_code')
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) return null;

    // Contas Google antigas às vezes ficam com name vazio: completa a partir
    // do metadata do auth e persiste só o nome (email é imutável via trigger).
    final storedName = (row['name'] as String?)?.trim() ?? '';
    if (storedName.isEmpty) {
      final fallback = _resolveDisplayName(user);
      if (fallback.isNotEmpty) {
        try {
          await _supabase
              .from('profiles')
              .update({'name': fallback}).eq('id', user.id);
        } catch (_) {
          // Ainda exibe o nome na sessão atual se o UPDATE falhar.
        }
        row = Map<String, dynamic>.from(row)..['name'] = fallback;
      }
    }

    return ProfileModel.fromJson(row);
  }

  /// Nome de exibição a partir do metadata do Supabase Auth / Google.
  String _resolveDisplayName(User user) {
    final meta = user.userMetadata ?? const <String, dynamic>{};
    for (final key in ['full_name', 'name', 'given_name']) {
      final value = meta[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    final email = (user.email ?? '').trim();
    if (email.contains('@')) {
      return email.split('@').first;
    }
    return '';
  }
}
