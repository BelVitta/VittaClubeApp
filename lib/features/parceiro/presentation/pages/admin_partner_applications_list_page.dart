import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/widgets/admin_empty_state.dart';
import '../../../admin/presentation/widgets/admin_filter_chip.dart';
import '../../../admin/presentation/widgets/admin_list_item.dart';
import '../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../../admin/presentation/widgets/admin_search_bar.dart';
import '../../../admin/presentation/widgets/admin_status_badge.dart';
import '../../domain/entities/partner_application_entity.dart';
import '../bloc/partner_application/partner_application_bloc.dart';
import '../bloc/partner_application/partner_application_event.dart';
import '../bloc/partner_application/partner_application_state.dart';

const _statusLabels = {
  'pending': 'Pendente',
  'approved': 'Aprovada',
  'rejected': 'Rejeitada',
};

const _categoryLabels = {
  'laboratorio': 'Laboratório',
  'clinica': 'Clínica',
  'farmacia': 'Farmácia',
  'otica': 'Ótica',
  'outro': 'Outro',
};

/// Tela de admin pra revisar candidaturas de "Seja Parceiro"
/// (aprovar cria o parceiro de verdade; rejeitar pede motivo).
class AdminPartnerApplicationsListPage extends StatelessWidget {
  const AdminPartnerApplicationsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<PartnerApplicationBloc>()..add(LoadPartnerApplications()),
      child: const _AdminPartnerApplicationsListView(),
    );
  }
}

class _AdminPartnerApplicationsListView extends StatelessWidget {
  const _AdminPartnerApplicationsListView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<PartnerApplicationBloc, PartnerApplicationState>(
      listenWhen: (previous, current) =>
          current.status == PartnerApplicationStatus.approved ||
          current.status == PartnerApplicationStatus.rejected ||
          current.status == PartnerApplicationStatus.failure,
      listener: (context, state) {
        if (state.status == PartnerApplicationStatus.approved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Candidatura aprovada!',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13)),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == PartnerApplicationStatus.rejected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Candidatura rejeitada.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13)),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == PartnerApplicationStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Erro ao processar operação.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13)),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      child: AdminPageScaffold(
        title: 'Candidaturas de Parceiro',
        subtitle: 'Revise e aprove estabelecimentos candidatos',
        body: Column(
          children: [
            AdminSearchBar(
              hintText: 'Buscar por nome ou e-mail...',
              onChanged: (query) => context
                  .read<PartnerApplicationBloc>()
                  .add(SearchPartnerApplications(query)),
            ),
            const SizedBox(height: 12),
            BlocBuilder<PartnerApplicationBloc, PartnerApplicationState>(
              buildWhen: (prev, curr) =>
                  prev.filterStatus != curr.filterStatus ||
                  prev.filterCategory != curr.filterCategory,
              builder: (context, state) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      AdminFilterChip(
                        icon: Icons.toggle_on_outlined,
                        label: state.filterStatus != null
                            ? (_statusLabels[state.filterStatus!] ?? '')
                            : 'Situação',
                        isActive: state.filterStatus != null,
                        onTap: () {
                          AdminFilterChip.showFilterBottomSheet(
                            context,
                            title: 'Filtrar por situação',
                            options: _statusLabels.keys.toList(),
                            current: state.filterStatus,
                            displayNames: _statusLabels,
                            onSelected: (value) => context
                                .read<PartnerApplicationBloc>()
                                .add(FilterApplicationsByStatus(value)),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      AdminFilterChip(
                        icon: Icons.category_outlined,
                        label: state.filterCategory != null
                            ? (_categoryLabels[state.filterCategory!] ?? '')
                            : 'Categoria',
                        isActive: state.filterCategory != null,
                        onTap: () {
                          AdminFilterChip.showFilterBottomSheet(
                            context,
                            title: 'Filtrar por categoria',
                            options: _categoryLabels.keys.toList(),
                            current: state.filterCategory,
                            displayNames: _categoryLabels,
                            onSelected: (value) => context
                                .read<PartnerApplicationBloc>()
                                .add(FilterApplicationsByCategory(value)),
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
                              .read<PartnerApplicationBloc>()
                              .add(ClearApplicationFilters()),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            BlocBuilder<PartnerApplicationBloc, PartnerApplicationState>(
              builder: (context, state) {
                if (state.status == PartnerApplicationStatus.loading) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor),
                    ),
                  );
                }
                if (state.filteredItems.isEmpty &&
                    state.status == PartnerApplicationStatus.loaded) {
                  return const AdminEmptyState(
                    icon: Icons.handshake_outlined,
                    message: 'Nenhuma candidatura encontrada',
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.filteredItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final application = state.filteredItems[index];
                    return _ApplicationItem(application: application);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationItem extends StatelessWidget {
  final PartnerApplicationEntity application;

  const _ApplicationItem({required this.application});

  Future<void> _approve(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aprovar candidatura'),
        content: Text(
          application.userId != null
              ? 'Isso vai transformar "${application.name}" em parceiro '
                  'ativo e gerar um código de resgate.'
              : 'Essa candidatura não tem uma conta vinculada — vai ficar '
                  'marcada como aprovada, mas o cadastro do parceiro '
                  'precisa ser feito manualmente (crie o usuário e depois '
                  'vincule).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: AppTheme.primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aprovar',
                style: TextStyle(color: AppTheme.successColor)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context
          .read<PartnerApplicationBloc>()
          .add(ApprovePartnerApplicationRequested(application.id));
    }
  }

  Future<void> _reject(BuildContext context) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeitar candidatura'),
        content: TextField(
          controller: reasonController,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Motivo da rejeição'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: AppTheme.primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rejeitar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<PartnerApplicationBloc>().add(
            RejectPartnerApplicationRequested(
              id: application.id,
              reason: reasonController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final subtitleParts = <String>[
      application.email,
      _categoryLabels[application.category] ?? application.category,
      'Recebida em ${dateFormat.format(application.createdAt)}',
    ];

    return AdminListItem(
      title: application.name,
      subtitle: subtitleParts.join(' · '),
      leading: AdminStatusBadge(
        status: switch (application.status) {
          'approved' => 'ativo',
          'rejected' => 'cancelado',
          _ => 'pendente',
        },
      ),
      trailing: application.status == 'pending'
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Aprovar',
                  icon: const Icon(Icons.check_circle_outline,
                      color: AppTheme.successColor, size: 20),
                  onPressed: () => _approve(context),
                ),
                IconButton(
                  tooltip: 'Rejeitar',
                  icon: const Icon(Icons.cancel_outlined,
                      color: Colors.red, size: 20),
                  onPressed: () => _reject(context),
                ),
              ],
            )
          : null,
    );
  }
}
