import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../pages/notifications_page.dart';

/// Sino com badge de não lidas. Abre a caixa de entrada.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsBloc>()..add(const LoadUnreadCount()),
      child: const _BellView(),
    );
  }
}

class _BellView extends StatelessWidget {
  const _BellView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final count = state.unreadCount;
        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            );
            if (context.mounted) {
              context.read<NotificationsBloc>().add(const LoadUnreadCount());
            }
          },
          child: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 9 ? '9+' : '$count'),
            backgroundColor: AppTheme.errorColor,
            child: Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: const Color(0xFF01225B).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(19.5),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 20,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
