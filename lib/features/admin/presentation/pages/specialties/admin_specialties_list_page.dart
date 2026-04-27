import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection_container.dart';
import '../../bloc/specialty/specialty_bloc.dart';
import '../../bloc/specialty/specialty_event.dart';
import '../../bloc/specialty/specialty_state.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_search_bar.dart';
import '../../widgets/admin_list_item.dart';
import '../../widgets/admin_status_badge.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_delete_dialog.dart';
import 'admin_specialty_form_page.dart';

/// Página de listagem de especialidades no módulo admin.
/// Exibe lista filtrada com busca, ações de editar/excluir e FAB para criar.
class AdminSpecialtiesListPage extends StatelessWidget {
  const AdminSpecialtiesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SpecialtyBloc>()..add(LoadSpecialties()),
      child: const _SpecialtiesListView(),
    );
  }
}

class _SpecialtiesListView extends StatelessWidget {
  const _SpecialtiesListView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SpecialtyBloc, SpecialtyState>(
      listenWhen: (previous, current) =>
          current.status == SpecialtyStatus.saved ||
          current.status == SpecialtyStatus.deleted ||
          current.status == SpecialtyStatus.failure,
      listener: (context, state) {
        if (state.status == SpecialtyStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Especialidade salva com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == SpecialtyStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Especialidade excluída com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == SpecialtyStatus.failure) {
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
          title: 'Especialidades',
          body: Column(
            children: [
              // Barra de pesquisa
              AdminSearchBar(
                onChanged: (query) {
                  context.read<SpecialtyBloc>().add(SearchSpecialties(query));
                },
              ),
              const SizedBox(height: 16),
              // Lista de especialidades
              BlocBuilder<SpecialtyBloc, SpecialtyState>(
                builder: (context, state) {
                  if (state.status == SpecialtyStatus.loading) {
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
                      state.status == SpecialtyStatus.loaded) {
                    return const AdminEmptyState(
                      icon: Icons.category_outlined,
                      message: 'Nenhuma especialidade encontrada',
                      subtitle:
                          'Toque no botão + para cadastrar uma nova especialidade.',
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final specialty = state.filteredItems[index];
                      return AdminListItem(
                        title: specialty.name,
                        subtitle: specialty.isActive ? 'Ativo' : 'Inativo',
                        leading: AdminStatusBadge(
                          status: specialty.isActive ? 'ativo' : 'inativo',
                        ),
                        onEdit: () {
                          final bloc = context.read<SpecialtyBloc>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: bloc,
                                child: AdminSpecialtyFormPage(
                                  entity: specialty,
                                ),
                              ),
                            ),
                          ).then((result) {
                            if (result == true) {
                              context
                                  .read<SpecialtyBloc>()
                                  .add(LoadSpecialties());
                            }
                          });
                        },
                        onDelete: () async {
                          final confirmed = await AdminDeleteDialog.show(
                            context,
                            specialty.name,
                          );
                          if (confirmed == true && context.mounted) {
                            context
                                .read<SpecialtyBloc>()
                                .add(DeleteSpecialtyRequested(specialty.id));
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
            final bloc = context.read<SpecialtyBloc>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: const AdminSpecialtyFormPage(),
                ),
              ),
            ).then((result) {
              if (result == true && context.mounted) {
                context.read<SpecialtyBloc>().add(LoadSpecialties());
              }
            });
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
