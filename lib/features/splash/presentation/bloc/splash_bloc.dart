import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../auth/data/services/auth_session_manager.dart';
import 'splash_event.dart';
import 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final SharedPreferences sharedPreferences;
  final AuthSessionManager authSessionManager;

  SplashBloc({
    required this.sharedPreferences,
    required this.authSessionManager,
  }) : super(SplashInitial()) {
    on<SplashStarted>(_onSplashStarted);
    on<NavigateToOnboarding>(_onNavigateToOnboarding);
  }

  Future<void> _onSplashStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    emit(SplashLoading());
    await Future.delayed(const Duration(seconds: 2));

    // 1. Verifica sessão real do Supabase (fonte de verdade em produção)
    if (SupabaseConfig.isInitialized) {
      final session = SupabaseConfig.client.auth.currentSession;
      final hasValidLocalSession =
          await authSessionManager.isSessionWindowValid();

      if (session != null &&
          hasValidLocalSession &&
          !_isSessionExpired(session)) {
        // Recovery: se handle_new_user falhou no signup, recria o perfil.
        try {
          await SupabaseConfig.client.rpc('ensure_own_profile');
        } catch (_) {}
        final role = await _fetchRole(session.user.id);
        if (!await _hasCompleteProfile(session.user.id)) {
          emit(SplashNavigateToCompleteProfile());
          return;
        }
        emit(_stateForRole(role));
        return;
      }

      if (session != null || hasValidLocalSession) {
        await authSessionManager.clearSession();
      }
    }

    // 2. Sem sessão ativa: decide entre onboarding e login
    final hasSeenOnboarding =
        sharedPreferences.getBool('HAS_SEEN_ONBOARDING') ?? false;
    if (hasSeenOnboarding) {
      emit(SplashNavigateToLogin());
    } else {
      emit(SplashNavigateToOnboarding());
    }
  }

  void _onNavigateToOnboarding(
    NavigateToOnboarding event,
    Emitter<SplashState> emit,
  ) {
    emit(SplashNavigateToOnboarding());
  }

  bool _isSessionExpired(Session session) {
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;
    return DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000)
        .isBefore(DateTime.now());
  }

  Future<String> _fetchRole(String userId) async {
    try {
      final data = await SupabaseConfig.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      return data?['role'] as String? ?? 'user';
    } catch (_) {
      return 'user';
    }
  }

  Future<bool> _hasCompleteProfile(String userId) async {
    try {
      final rows = await SupabaseConfig.client.rpc(
        'get_user_sensitive_profile',
        params: {'p_user_id': userId},
      ) as List;
      if (rows.isEmpty) return false;
      final row = Map<String, dynamic>.from(rows.first as Map);
      final cpf = row['cpf'] as String? ?? '';
      final phone = row['phone'] as String? ?? '';
      return cpf.isNotEmpty && phone.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  SplashState _stateForRole(String role) {
    switch (role) {
      case 'admin':
        return SplashNavigateToAdmin();
      case 'financeiro':
        return SplashNavigateToFinanceiro();
      case 'parceiro':
        return SplashNavigateToPartner();
      default:
        return SplashNavigateToHome();
    }
  }
}
