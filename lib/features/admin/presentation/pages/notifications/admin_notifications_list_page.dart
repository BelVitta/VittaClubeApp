import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection_container.dart';
import '../../bloc/notification_template/notification_template_bloc.dart';
import '../../bloc/notification_template/notification_template_event.dart';
import '../../bloc/notification_template/notification_template_state.dart';
import '../../bloc/notification_campaign/notification_campaign_bloc.dart';
import '../../bloc/notification_campaign/notification_campaign_event.dart';
import '../../bloc/notification_campaign/notification_campaign_state.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_search_bar.dart';
import '../../widgets/admin_list_item.dart';
import '../../widgets/admin_status_badge.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_delete_dialog.dart';
import '../../widgets/admin_filter_chip.dart';
import 'admin_campaign_form_page.dart';
import 'admin_notification_form_page.dart';

class AdminNotificationsListPage extends StatefulWidget {
  const AdminNotificationsListPage({super.key});

  @override
  State<AdminNotificationsListPage> createState() =>
      _AdminNotificationsListPageState();
}

class _AdminNotificationsListPageState
    extends State<AdminNotificationsListPage> {
  bool _showCampaigns = true;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<NotificationCampaignBloc>()..add(LoadNotificationCampaigns()),
        ),
        BlocProvider(
          create: (_) =>
              sl<NotificationTemplateBloc>()..add(LoadNotificationTemplates()),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        body: AdminPageScaffold(
          title: 'Notificações',
          body: Column(
            children: [
              Row(
                children: [
                  AdminFilterChip(
                    icon: Icons.campaign_outlined,
                    label: 'Campanhas',
                    isActive: _showCampaigns,
                    onTap: () => setState(() => _showCampaigns = true),
                  ),
                  const SizedBox(width: 8),
                  AdminFilterChip(
                    icon: Icons.description_outlined,
                    label: 'Templates',
                    isActive: !_showCampaigns,
                    onTap: () => setState(() => _showCampaigns = false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _showCampaigns ? const _CampaignsList() : const _TemplatesList(),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              backgroundColor: AppTheme.primaryColor,
              onPressed: () {
                if (_showCampaigns) {
                  final bloc = context.read<NotificationCampaignBloc>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: bloc,
                        child: const AdminCampaignFormPage(),
                      ),
                    ),
                  );
                } else {
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
                      context
                          .read<NotificationTemplateBloc>()
                          .add(LoadNotificationTemplates());
                    }
                  });
                }
              },
              child: Icon(
                _showCampaigns ? Icons.send_outlined : Icons.add,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CampaignsList extends StatelessWidget {
  const _CampaignsList();

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return BlocBuilder<NotificationCampaignBloc, NotificationCampaignState>(
      builder: (context, state) {
        if (state.status == NotificationCampaignStatus.loading) {
          return const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        if (state.items.isEmpty &&
            state.status == NotificationCampaignStatus.loaded) {
          return const AdminEmptyState(
            icon: Icons.campaign_outlined,
            message: 'Nenhuma campanha enviada',
            subtitle:
                'Toque no botão para divulgar uma novidade ou especialista.',
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final campaign = state.items[index];
            final audienceLabel =
                campaign.audience == 'all_users' ? 'Todos' : '1 membro';
            return AdminListItem(
              title: campaign.title,
              subtitle:
                  '${campaign.type} · $audienceLabel · ${campaign.recipientCount} envio(s) · ${dateFormat.format(campaign.createdAt.toLocal())}',
              leading: AdminStatusBadge(status: campaign.type),
            );
          },
        );
      },
    );
  }
}

class _TemplatesList extends StatelessWidget {
  const _TemplatesList();

  static const _typeOptions = [
    'sorteio',
    'cupom',
    'consulta',
    'sistema',
    'badge',
    'divulgacao',
    'profissional',
  ];

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
                'Template salvo com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == NotificationTemplateStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Template excluído com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == NotificationTemplateStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage ?? 'Erro ao processar operação.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      child: Column(
        children: [
          AdminSearchBar(
            onChanged: (query) {
              context
                  .read<NotificationTemplateBloc>()
                  .add(SearchNotificationTemplates(query));
            },
          ),
          const SizedBox(height: 12),
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
                          ? state.filterType![0].toUpperCase() +
                              state.filterType!.substring(1)
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
                                  FilterNotificationsByType(value),
                                );
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
                                    value == null ? null : value == 'ativo',
                                  ),
                                );
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
                  message: 'Nenhum template encontrado',
                  subtitle: 'Toque no botão + para cadastrar um template.',
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
                        if (result == true && context.mounted) {
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
                        context.read<NotificationTemplateBloc>().add(
                              DeleteNotificationTemplateRequested(
                                notification.id,
                              ),
                            );
                      }
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
