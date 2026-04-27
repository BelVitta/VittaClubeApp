import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection_container.dart';
import '../../bloc/user_admin/user_admin_bloc.dart';
import '../../bloc/user_admin/user_admin_event.dart';
import '../../bloc/user_admin/user_admin_state.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_search_bar.dart';
import '../../widgets/admin_list_item.dart';
import '../../widgets/admin_status_badge.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_delete_dialog.dart';
import '../../widgets/admin_filter_chip.dart';
import 'admin_user_form_page.dart';

class AdminUsersListPage extends StatelessWidget {
  const AdminUsersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UserAdminBloc>()..add(LoadUsers()),
      child: const _UsersListView(),
    );
  }
}

class _UsersListView extends StatelessWidget {
  const _UsersListView();

  static const _statusOptions = ['ativo', 'inativo', 'inadimplente', 'cancelado'];
  static const _levelOptions = ['Bronze', 'Prata', 'Ouro', 'Diamante', 'Sem plano'];

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserAdminBloc, UserAdminState>(
      listenWhen: (previous, current) =>
          current.status == UserAdminStatus.saved ||
          current.status == UserAdminStatus.deleted ||
          current.status == UserAdminStatus.failure,
      listener: (context, state) {
        if (state.status == UserAdminStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Usuario salvo com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == UserAdminStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Usuario excluido com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == UserAdminStatus.failure) {
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
          title: 'Usuarios',
          body: Column(
            children: [
              AdminSearchBar(
                onChanged: (query) {
                  context.read<UserAdminBloc>().add(SearchUsers(query));
                },
              ),
              const SizedBox(height: 12),
              // Filtros
              BlocBuilder<UserAdminBloc, UserAdminState>(
                buildWhen: (prev, curr) =>
                    prev.filterStatus != curr.filterStatus ||
                    prev.filterLevel != curr.filterLevel,
                builder: (context, state) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        AdminFilterChip(
                          icon: Icons.toggle_on_outlined,
                          label: state.filterStatus != null
                              ? state.filterStatus![0].toUpperCase() + state.filterStatus!.substring(1)
                              : 'Status',
                          isActive: state.filterStatus != null,
                          onTap: () {
                            AdminFilterChip.showFilterBottomSheet(
                              context,
                              title: 'Filtrar por Status',
                              options: _statusOptions,
                              current: state.filterStatus,
                              onSelected: (value) {
                                context.read<UserAdminBloc>().add(
                                    FilterUsersByStatus(value));
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        AdminFilterChip(
                          icon: Icons.workspace_premium_outlined,
                          label: state.filterLevel ?? 'Nivel',
                          isActive: state.filterLevel != null,
                          onTap: () {
                            AdminFilterChip.showFilterBottomSheet(
                              context,
                              title: 'Filtrar por Nivel',
                              options: _levelOptions,
                              current: state.filterLevel,
                              onSelected: (value) {
                                context.read<UserAdminBloc>().add(
                                    FilterUsersByLevel(value));
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
                                .read<UserAdminBloc>()
                                .add(ClearUserFilters()),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<UserAdminBloc, UserAdminState>(
                builder: (context, state) {
                  if (state.status == UserAdminStatus.loading) {
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
                      state.status == UserAdminStatus.loaded) {
                    return const AdminEmptyState(
                      icon: Icons.people_outlined,
                      message: 'Nenhum usuario encontrado',
                      subtitle:
                          'Toque no botao + para cadastrar um novo usuario.',
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = state.filteredItems[index];
                      return AdminListItem(
                        title: user.name,
                        subtitle:
                            '${user.email} - ${user.planLevelName}',
                        leading: AdminStatusBadge(
                          status: user.status,
                        ),
                        onEdit: () {
                          final bloc = context.read<UserAdminBloc>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: bloc,
                                child: AdminUserFormPage(
                                  entity: user,
                                ),
                              ),
                            ),
                          ).then((result) {
                            if (result == true) {
                              context
                                  .read<UserAdminBloc>()
                                  .add(LoadUsers());
                            }
                          });
                        },
                        onDelete: () async {
                          final confirmed = await AdminDeleteDialog.show(
                            context,
                            user.name,
                          );
                          if (confirmed == true && context.mounted) {
                            context
                                .read<UserAdminBloc>()
                                .add(DeleteUserRequested(user.id));
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
            final bloc = context.read<UserAdminBloc>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: const AdminUserFormPage(),
                ),
              ),
            ).then((result) {
              if (result == true && context.mounted) {
                context.read<UserAdminBloc>().add(LoadUsers());
              }
            });
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
