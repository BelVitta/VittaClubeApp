import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/notification_item.dart';

/// Entidade local para representar uma notificação
class _NotificationData {
  final String id;
  final String title;
  final String subtitle;
  bool isUnread;

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
  final List<_NotificationData> _notifications = [
    _NotificationData(
      id: '1',
      title: 'Novo Sorteio Disponível',
      subtitle: 'Participe do novo sorteio e concorra a prêmios!',
      isUnread: true,
    ),
    _NotificationData(
      id: '2',
      title: 'Novo cupom ganho!',
      subtitle: 'Você ganhou um cupom de desconto. Confira!',
      isUnread: true,
    ),
    _NotificationData(
      id: '3',
      title: 'Consulta Amanhã',
      subtitle: 'Lembrete: sua consulta é amanhã às 10h.',
    ),
    _NotificationData(
      id: '4',
      title: 'Novo Sorteio Disponível',
      subtitle: 'Participe do novo sorteio e concorra a prêmios!',
    ),
    _NotificationData(
      id: '5',
      title: 'Novo cupom ganho!',
      subtitle: 'Você ganhou um cupom de desconto. Confira!',
    ),
    _NotificationData(
      id: '6',
      title: 'Consulta Amanhã',
      subtitle: 'Lembrete: sua consulta é amanhã às 10h.',
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n.isUnread = false;
      }
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
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

                        // Mark all as read button
                        if (_notifications.any((n) => n.isUnread))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: _markAllAsRead,
                              child: Container(
                                width: double.infinity,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppTheme.primaryColor,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Marcar todas como lida',
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

                        // Notification list
                        ..._notifications.map((notification) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: NotificationItem(
                                title: notification.title,
                                subtitle: notification.subtitle,
                                isUnread: notification.isUnread,
                                onDelete: () =>
                                    _deleteNotification(notification.id),
                              ),
                            )),

                        if (_notifications.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 48),
                            child: Center(
                              child: Text(
                                'Nenhuma notificação',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF6D7F95),
                                ),
                              ),
                            ),
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
}
