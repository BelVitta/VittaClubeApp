import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection_container.dart';
import '../../bloc/notification_template/notification_template_bloc.dart';
import '../../bloc/notification_template/notification_template_event.dart';
import '../../bloc/notification_template/notification_template_state.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_search_bar.dart';
import '../../widgets/admin_list_item.dart';
import '../../widgets/admin_status_badge.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_delete_dialog.dart';
import '../../widgets/admin_filter_chip.dart';
import 'admin_notification_form_page.dart';

class AdminNotificationsListPage extends StatelessWidget {
  const AdminNotificationsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationTemplateBloc>()..add(LoadNotificationTemplates()),
      child: const _NotificationsListView(),
    );
  }
}

class _NotificationsListView extends StatelessWidget {
  const _NotificationsListView();

  static const _typeOptions = ['sorteio', 'cupom', 'consulta', 'geral'];

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationTemplateBloc, NotificationTemplateState>(
      listenWhen: (previous, current) =>
          current.status == NotificationTemplateStatus.saved ||
          current.status == NotificationTemplateStatus.deleted ||
          current.status == NotificationTemplateStatus.failure,
      listener: (context, state) {
        if (state.status == NotificationTemplateStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Notificacao salva com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == NotificationTemplateStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Notificacao excluida com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == NotificationTemplateStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage ?? 'Erro ao processar operacao.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: AdminPageScaffold(
          title: 'Notificacoes',
          body: Column(
            children: [
              AdminSearchBar(
                onChanged: (query) {
                  context.read<NotificationTemplateBloc>().add(SearchNotificationTemplates(query));
                },
              ),
              const SizedBox(height: 12),
              // Filtros
              BlocBuilder<NotificationTemplateBloc, NotificationTemplateState>(
                buildWhen: (prev, curr) =>
                    prev.filterType != curr.filterType ||
                    prev.filterIsActive != curr.filterIsActive,
                builder: (context, state) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        AdminFilterChip(
                          icon: Icons.category_outlined,
                          label: state.filterType != null
                              ? state.filterType![0].toUpperCase() + state.filterType!.substring(1)
                              : 'Tipo',
                          isActive: state.filterType != null,
                          onTap: () {
                            AdminFilterChip.showFilterBottomSheet(
                              context,
                              title: 'Filtrar por Tipo',
                              options: _typeOptions,
                              current: state.filterType,
                              onSelected: (value) {
                                context.read<NotificationTemplateBloc>().add(
                                    FilterNotificationsByType(value));
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        AdminFilterChip(
                          icon: Icons.toggle_on_outlined,
                          label: state.filterIsActive == null
                              ? 'Status'
                              : (state.filterIsActive! ? 'Ativo' : 'Inativo'),
                          isActive: state.filterIsActive != null,
                          onTap: () {
                            AdminFilterChip.showFilterBottomSheet(
                              context,
                              title: 'Filtrar por Status',
                              options: ['ativo', 'inativo'],
                              current: state.filterIsActive == null
                                  ? null
                                  : (state.filterIsActive! ? 'ativo' : 'inativo'),
                              onSelected: (value) {
                                context.read<NotificationTemplateBloc>().add(
                                    FilterNotificationsByStatus(
                                        value == null ? null : value == 'ativo'));
                              },
                            );
                          },
                        ),
                        if (state.hasActiveFilters) ...[
                          const SizedBox(width: 8),
                          AdminFilterChip(
                            icon: Icons.clear,
                            label: 'Limpar',
                            isActive: false,
                            onTap: () => context
                                .read<NotificationTemplateBloc>()
                                .add(ClearNotificationFilters()),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<NotificationTemplateBloc, NotificationTemplateState>(
                builder: (context, state) {
                  if (state.status == NotificationTemplateStatus.loading) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    );
                  }

                  if (state.filteredItems.isEmpty &&
                      state.status == NotificationTemplateStatus.loaded) {
                    return const AdminEmptyState(
                      icon: Icons.notifications_outlined,
                      message: 'Nenhuma notificacao encontrada',
                      subtitle:
                          'Toque no botao + para cadastrar uma nova notificacao.',
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final notification = state.filteredItems[index];
                      return AdminListItem(
                        title: notification.title,
                        subtitle:
                            '${notification.type} - ${notification.triggerEvent}',
                        leading: AdminStatusBadge(
                          status: notification.isActive ? 'ativo' : 'inativo',
                        ),
                        onEdit: () {
                          final bloc = context.read<NotificationTemplateBloc>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: bloc,
                                child: AdminNotificationFormPage(
                                  entity: notification,
                                ),
                              ),
                            ),
                          ).then((result) {
                            if (result == true) {
                              context
                                  .read<NotificationTemplateBloc>()
                                  .add(LoadNotificationTemplates());
                            }
                          });
                        },
                        onDelete: () async {
                          final confirmed = await AdminDeleteDialog.show(
                            context,
                            notification.title,
                          );
                          if (confirmed == true && context.mounted) {
                            context
                                .read<NotificationTemplateBloc>()
                                .add(DeleteNotificationTemplateRequested(notification.id));
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.primaryColor,
          onPressed: () {
            final bloc = context.read<NotificationTemplateBloc>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: const AdminNotificationFormPage(),
                ),
              ),
            ).then((result) {
              if (result == true && context.mounted) {
                context.read<NotificationTemplateBloc>().add(LoadNotificationTemplates());
              }
            });
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
