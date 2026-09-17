import 'package:flutter/material.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../consultation/presentation/pages/consultation_schedule_page.dart';
import '../../parceiro/presentation/pages/user/partners_list_page.dart';
import '../../plans/presentation/pages/plans_page.dart';
import '../../professionals/presentation/pages/professionals_page.dart';
import '../domain/entities/notification_entity.dart';

/// Navega a partir do payload de uma notificação in-app ou FCM.
class NotificationRouter {
  NotificationRouter._();

  static void open(
    NotificationAction action, {
    String? professionalName,
    BuildContext? context,
  }) {
    final navContext = context ?? AppNavigator.context;
    if (navContext == null) return;

    final holderUserId = SupabaseConfig.isInitialized
        ? SupabaseConfig.client.auth.currentUser?.id
        : null;

    switch (action) {
      case NotificationAction.professional:
        if (holderUserId == null) return;
        Navigator.push(
          navContext,
          MaterialPageRoute(
            builder: (_) => ConsultationSchedulePage(
              holderUserId: holderUserId,
              professionalName: professionalName ?? 'Profissional',
            ),
          ),
        );
        return;
      case NotificationAction.professionals:
        Navigator.push(
          navContext,
          MaterialPageRoute(builder: (_) => const ProfessionalsPage()),
        );
        return;
      case NotificationAction.plans:
        Navigator.push(
          navContext,
          MaterialPageRoute(builder: (_) => const PlansPage()),
        );
        return;
      case NotificationAction.partners:
        Navigator.push(
          navContext,
          MaterialPageRoute(builder: (_) => const PartnersListPage()),
        );
        return;
      case NotificationAction.none:
        return;
    }
  }

  static void openFromData(Map<String, dynamic> data, {BuildContext? context}) {
    open(
      notificationActionFromString(data['action'] as String?),
      professionalName: data['professional_name'] as String?,
      context: context,
    );
  }
}
