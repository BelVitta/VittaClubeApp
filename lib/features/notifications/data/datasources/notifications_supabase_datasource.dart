import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/notification_preferences_entity.dart';
import '../models/notification_model.dart';

class NotificationsSupabaseDataSource {
  final SupabaseClient _supabase;

  NotificationsSupabaseDataSource({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  String? get _uid => _supabase.auth.currentUser?.id;

  Future<List<NotificationModel>> getForCurrentUser() async {
    final userId = _uid;
    if (userId == null) return const [];

    try {
      final rows = await _supabase
          .from('notifications')
          .select(
            'id, title, body, type, is_read, read_at, data, created_at',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return (rows as List)
          .map((row) => NotificationModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar notificações: $e');
    }
  }

  Future<int> unreadCount() async {
    final userId = _uid;
    if (userId == null) return 0;

    try {
      final rows = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      return (rows as List).length;
    } catch (e) {
      throw ServerException(message: 'Erro ao contar notificações: $e');
    }
  }

  Future<void> markRead(String id) async {
    final userId = _uid;
    if (userId == null) {
      throw const ServerException(message: 'Usuário não autenticado.');
    }

    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .eq('user_id', userId);
    } catch (e) {
      throw ServerException(message: 'Erro ao marcar notificação: $e');
    }
  }

  Future<void> markAllRead() async {
    final userId = _uid;
    if (userId == null) {
      throw const ServerException(message: 'Usuário não autenticado.');
    }

    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw ServerException(message: 'Erro ao marcar notificações: $e');
    }
  }

  Future<NotificationPreferencesEntity> getPreferences() async {
    final userId = _uid;
    if (userId == null) {
      return const NotificationPreferencesEntity();
    }

    try {
      final row = await _supabase
          .from('notification_preferences')
          .select('sorteios, rankings, pagamentos, novidades')
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) return const NotificationPreferencesEntity();

      return NotificationPreferencesEntity(
        sorteios: row['sorteios'] as bool? ?? true,
        rankings: row['rankings'] as bool? ?? true,
        pagamentos: row['pagamentos'] as bool? ?? true,
        novidades: row['novidades'] as bool? ?? true,
      );
    } catch (e) {
      throw ServerException(message: 'Erro ao buscar preferências: $e');
    }
  }

  Future<NotificationPreferencesEntity> updatePreferences(
    NotificationPreferencesEntity preferences,
  ) async {
    final userId = _uid;
    if (userId == null) {
      throw const ServerException(message: 'Usuário não autenticado.');
    }

    try {
      await _supabase.from('notification_preferences').upsert({
        'user_id': userId,
        'sorteios': preferences.sorteios,
        'rankings': preferences.rankings,
        'pagamentos': preferences.pagamentos,
        'novidades': preferences.novidades,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      return preferences;
    } catch (e) {
      throw ServerException(message: 'Erro ao salvar preferências: $e');
    }
  }
}
