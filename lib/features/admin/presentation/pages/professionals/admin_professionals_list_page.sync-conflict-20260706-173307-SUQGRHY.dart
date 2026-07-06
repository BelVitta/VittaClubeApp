import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection_container.dart';
import '../../bloc/professional/professional_bloc.dart';
import '../../bloc/professional/professional_event.dart';
import '../../bloc/professional/professional_state.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_search_bar.dart';
import '../../widgets/admin_list_item.dart';
import '../../widgets/admin_status_badge.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_delete_dialog.dart';
import '../../widgets/admin_filter_chip.dart';
import 'admin_professional_form_page.dart';

class AdminProfessionalsListPage extends StatelessWidget {
  const AdminProfessionalsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfessionalBloc>()..add(LoadProfessionals()),
      child: const _ProfessionalsListView(),
    );
  }
}

class _ProfessionalsListView extends StatelessWidget {
  const _ProfessionalsListView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfessionalBloc, ProfessionalState>(
      listenWhen: (previous, current) =>
          current.status == ProfessionalStatus.saved ||
          current.status == ProfessionalStatus.deleted ||
          current.status == ProfessionalStatus.failure,
      listener: (context, state) {
        if (state.status == ProfessionalStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profissional salvo com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == ProfessionalStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profissional excluido com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == ProfessionalStatus.failure) {
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
          title: 'Profissionais',
          body: Column(
            children: [
              AdminSearchBar(
                onChanged: (query) {
                  context
                      .read<ProfessionalBloc>()
                      .add(SearchProfessionals(query));
                },
              ),
              const SizedBox(height: 12),
              // Filtros
              BlocBuilder<ProfessionalBloc, ProfessionalState>(
                buildWhen: (prev, curr) =>
                    prev.filterSpecialty != curr.filterSpecialty ||
                    prev.filterIsActive != curr.filterIsActive ||
                    prev.items != curr.items,
                builder: (context, state) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        AdminFilterChip(
                          icon: Icons.medical_services_outlined,
                          label: state.filterSpecialty ?? 'Especialidade',
                          isActive: state.filterSpecialty != null,
                          onTap: () {
                            AdminFilterChip.showFilterBottomSheet(
                              context,
                              title: 'Filtrar por Especialidade',
                              options: state.availableSpecialties,
                              current: state.filterSpecialty,
                              onSelected: (value) {
                                context
                                    .read<ProfessionalBloc>()
                                    .add(FilterProfessionalsBySpecialty(value));
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
                                  : (state.filterIsActive!
                                      ? 'ativo'
                                      : 'inativo'),
                              onSelected: (value) {
                                context.read<ProfessionalBloc>().add(
                                    FilterProfessionalsByStatus(value == null
                                        ? null
                                        : value == 'ativo'));
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
                                .read<ProfessionalBloc>()
                                .add(ClearProfessionalFilters()),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<ProfessionalBloc, ProfessionalState>(
                builder: (context, state) {
                  if (state.status == ProfessionalStatus.loading) {
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
                      state.status == ProfessionalStatus.loaded) {
                    return const AdminEmptyState(
                      icon: Icons.medical_services_outlined,
                      message: 'Nenhum profissional encontrado',
                      subtitle:
                          'Toque no botao + para cadastrar um novo profissional.',
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final professional = state.filteredItems[index];
                      return AdminListItem(
                        title: professional.name,
                        subtitle:
                            '${professional.specialtyName} - ${professional.availableDays}',
                        leading: AdminStatusBadge(
                          status: professional.isActive ? 'ativo' : 'inativo',
                        ),
                        onEdit: () {
                          final bloc = context.read<ProfessionalBloc>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: bloc,
                                child: AdminProfessionalFormPage(
                                  entity: professional,
                                ),
                              ),
                            ),
                          ).then((result) {
                            if (result == true) {
                              bloc.add(LoadProfessionals());
                            }
                          });
                        },
                        onDelete: () async {
                          final confirmed = await AdminDeleteDialog.show(
                            context,
                            professional.name,
                          );
                          if (confirmed == true && context.mounted) {
                            context.read<ProfessionalBloc>().add(
                                DeleteProfessionalRequested(professional.id));
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
            final bloc = context.read<ProfessionalBloc>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: const AdminProfessionalFormPage(),
                ),
              ),
            ).then((result) {
              if (result == true && context.mounted) {
                context.read<ProfessionalBloc>().add(LoadProfessionals());
              }
            });
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
