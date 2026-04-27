import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

/// Gerencia a janela local de sessão do app.
/// A autenticação real continua no Supabase, mas o app aplica um TTL fixo
/// de 24h para decidir se o login ainda deve persistir.
class AuthSessionManager {
  static const cachedUserKey = 'CACHED_USER';
  static const sessionLoggedInAtKey = 'SESSION_LOGGED_IN_AT';
  static const sessionExpiresAtKey = 'SESSION_EXPIRES_AT';

  final SharedPreferences sharedPreferences;
  final GoTrueClient? authClient;
  final Duration sessionTtl;

  AuthSessionManager({
    required this.sharedPreferences,
    required this.authClient,
    this.sessionTtl = const Duration(hours: 24),
  });

  Future<void> saveSession(
    UserModel user, {
    DateTime? now,
  }) async {
    final loginAt = now ?? DateTime.now();
    final expiresAt = loginAt.add(sessionTtl);

    await sharedPreferences.setString(
      cachedUserKey,
      json.encode(user.toJson()),
    );
    await sharedPreferences.setString(
      sessionLoggedInAtKey,
      loginAt.toIso8601String(),
    );
    await sharedPreferences.setString(
      sessionExpiresAtKey,
      expiresAt.toIso8601String(),
    );
  }

  Future<UserModel?> getCachedUser() async {
    final jsonString = sharedPreferences.getString(cachedUserKey);
    if (jsonString == null) return null;

    return UserModel.fromJson(json.decode(jsonString) as Map<String, dynamic>);
  }

  Future<bool> isSessionWindowValid({DateTime? now}) async {
    final expiresAtRaw = sharedPreferences.getString(sessionExpiresAtKey);
    if (expiresAtRaw == null) return false;

    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (expiresAt == null) {
      await clearLocalSession();
      return false;
    }

    final referenceTime = now ?? DateTime.now();
    final isValid = !referenceTime.isAfter(expiresAt);
    if (!isValid) {
      await clearLocalSession();
    }

    return isValid;
  }

  Future<void> clearLocalSession() async {
    await sharedPreferences.remove(cachedUserKey);
    await sharedPreferences.remove(sessionLoggedInAtKey);
    await sharedPreferences.remove(sessionExpiresAtKey);
  }

  Future<void> clearSession() async {
    await clearLocalSession();

    try {
      await authClient?.signOut();
    } catch (_) {
      // A limpeza local é obrigatória; falha no signOut remoto não deve travar.
    }
  }
}
