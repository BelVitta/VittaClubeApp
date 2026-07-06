import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection_container.dart';
import '../../bloc/plan_admin/plan_admin_bloc.dart';
import '../../bloc/plan_admin/plan_admin_event.dart';
import '../../bloc/plan_admin/plan_admin_state.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_search_bar.dart';
import '../../widgets/admin_list_item.dart';
import '../../widgets/admin_status_badge.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_delete_dialog.dart';
import 'admin_plan_form_page.dart';

/// Página de listagem de planos no módulo admin.
/// Exibe lista filtrada com busca, ações de editar/excluir e FAB para criar.
class AdminPlansListPage extends StatelessWidget {
  const AdminPlansListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PlanAdminBloc>()..add(LoadPlans()),
      child: const _PlansListView(),
    );
  }
}

class _PlansListView extends StatelessWidget {
  const _PlansListView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlanAdminBloc, PlanAdminState>(
      listenWhen: (previous, current) =>
          current.status == PlanAdminStatus.saved ||
          current.status == PlanAdminStatus.deleted ||
          current.status == PlanAdminStatus.failure,
      listener: (context, state) {
        if (state.status == PlanAdminStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Plano salvo com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == PlanAdminStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Plano excluído com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == PlanAdminStatus.failure) {
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
      child: Scaffold(
        backgroundColor: Colors.white,
        body: AdminPageScaffold(
          title: 'Planos',
          body: Column(
            children: [
              // Barra de pesquisa
              AdminSearchBar(
                onChanged: (query) {
                  context.read<PlanAdminBloc>().add(SearchPlans(query));
                },
              ),
              const SizedBox(height: 16),
              // Lista de planos
              BlocBuilder<PlanAdminBloc, PlanAdminState>(
                builder: (context, state) {
                  if (state.status == PlanAdminStatus.loading) {
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
                      state.status == PlanAdminStatus.loaded) {
                    return const AdminEmptyState(
                      icon: Icons.card_membership_outlined,
                      message: 'Nenhum plano encontrado',
                      subtitle:
                          'Toque no botão + para cadastrar um novo plano.',
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final plan = state.filteredItems[index];
                      return AdminListItem(
                        title: plan.name,
                        subtitle:
                            '${plan.subscriptionType} - R\$ ${plan.price.toStringAsFixed(2)}',
                        leading: AdminStatusBadge(
                          status: plan.isActive ? 'ativo' : 'inativo',
                        ),
                        onEdit: () {
                          final bloc = context.read<PlanAdminBloc>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: bloc,
                                child: AdminPlanFormPage(
                                  entity: plan,
                                ),
                              ),
                            ),
                          ).then((result) {
                            if (result == true) {
                              bloc.add(LoadPlans());
                            }
                          });
                        },
                        onDelete: () async {
                          final confirmed = await AdminDeleteDialog.show(
                            context,
                            plan.name,
                          );
                          if (confirmed == true && context.mounted) {
                            context
                                .read<PlanAdminBloc>()
                                .add(DeletePlanRequested(plan.id));
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
            final bloc = context.read<PlanAdminBloc>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: const AdminPlanFormPage(),
                ),
              ),
            ).then((result) {
              if (result == true && context.mounted) {
                context.read<PlanAdminBloc>().add(LoadPlans());
              }
            });
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
