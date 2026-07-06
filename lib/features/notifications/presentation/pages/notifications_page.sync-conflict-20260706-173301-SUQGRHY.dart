import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/notification_item.dart';

/// Entidade local para representar uma notificação
class _NotificationData {
  final String id;
  final String title;
  final String subtitle;
  final bool isUnread;

  _NotificationData({
    required this.id,
    required this.title,
    required this.subtitle,
    this.isUnread = false,
  });
}

/// Página de feed de Notificações
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<_NotificationData>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  Future<List<_NotificationData>> _loadNotifications() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return const [];
    final rows = await SupabaseConfig.client
        .from('notifications')
        .select('id, title, body, is_read')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>).map((raw) {
      final row = raw as Map<String, dynamic>;
      return _NotificationData(
        id: row['id'] as String,
        title: row['title'] as String? ?? '',
        subtitle: row['body'] as String? ?? '',
        isUnread: !(row['is_read'] as bool? ?? false),
      );
    }).toList();
  }

  Future<void> _markAllAsRead() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseConfig.client
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('is_read', false);
    if (!mounted) return;
    setState(() => _notificationsFuture = _loadNotifications());
  }

  Future<void> _markAsRead(String id) async {
    await SupabaseConfig.client.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
    if (!mounted) return;
    setState(() => _notificationsFuture = _loadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient circle
            Positioned(
              top: -16,
              right: -180,
              child: Container(
                width: 503.5,
                height: 283.06,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.gradientLight.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 1],
                  ),
                ),
              ),
            ),

            Column(
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 39,
                          height: 39,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF01225B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(19.5),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Notificações',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.12,
                          ),
                        ),
                        const SizedBox(height: 12),

                        FutureBuilder<List<_NotificationData>>(
                          future: _notificationsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 48),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            if (snapshot.hasError) {
                              return _buildMessage(
                                'Não foi possível carregar notificações.',
                              );
                            }
                            final notifications = snapshot.data ?? const [];
                            return Column(
                              children: [
                                if (notifications.any((n) => n.isUnread))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: GestureDetector(
                                      onTap: _markAllAsRead,
                                      child: Container(
                                        width: double.infinity,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          border: Border.all(
                                            color: AppTheme.primaryColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Marcar todas como lidas',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ...notifications.map(
                                  (notification) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: NotificationItem(
                                      title: notification.title,
                                      subtitle: notification.subtitle,
                                      isUnread: notification.isUnread,
                                      onTap: notification.isUnread
                                          ? () => _markAsRead(notification.id)
                                          : null,
                                    ),
                                  ),
                                ),
                                if (notifications.isEmpty)
                                  _buildMessage('Nenhuma notificação'),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D7F95),
          ),
        ),
      ),
    );
  }
}
