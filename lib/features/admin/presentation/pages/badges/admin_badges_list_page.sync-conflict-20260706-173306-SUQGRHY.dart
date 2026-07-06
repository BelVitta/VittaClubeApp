import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection_container.dart';
import '../../bloc/badge/badge_bloc.dart';
import '../../bloc/badge/badge_event.dart';
import '../../bloc/badge/badge_state.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_search_bar.dart';
import '../../widgets/admin_list_item.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_delete_dialog.dart';
import 'admin_badge_form_page.dart';

/// Página de listagem de badges/níveis no módulo admin.
/// Exibe lista filtrada com busca, ações de editar/excluir e FAB para criar.
class AdminBadgesListPage extends StatelessWidget {
  const AdminBadgesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BadgeBloc>()..add(LoadBadges()),
      child: const _BadgesListView(),
    );
  }
}

class _BadgesListView extends StatelessWidget {
  const _BadgesListView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<BadgeBloc, BadgeState>(
      listenWhen: (previous, current) =>
          current.status == BadgeStatus.saved ||
          current.status == BadgeStatus.deleted ||
          current.status == BadgeStatus.failure,
      listener: (context, state) {
        if (state.status == BadgeStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Badge salvo com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == BadgeStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Badge excluído com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == BadgeStatus.failure) {
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
          title: 'Badges / Níveis',
          body: Column(
            children: [
              // Barra de pesquisa
              AdminSearchBar(
                onChanged: (query) {
                  context.read<BadgeBloc>().add(SearchBadges(query));
                },
              ),
              const SizedBox(height: 16),
              // Lista de badges
              BlocBuilder<BadgeBloc, BadgeState>(
                builder: (context, state) {
                  if (state.status == BadgeStatus.loading) {
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
                      state.status == BadgeStatus.loaded) {
                    return const AdminEmptyState(
                      icon: Icons.military_tech_outlined,
                      message: 'Nenhum badge encontrado',
                      subtitle:
                          'Toque no botão + para cadastrar um novo badge.',
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final badge = state.filteredItems[index];
                      return AdminListItem(
                        title: badge.displayName,
                        subtitle:
                            '${badge.discountPercentage.toStringAsFixed(0)}% desconto - ${badge.maxConsultationsPerMonth} consultas/mes',
                        onEdit: () {
                          final bloc = context.read<BadgeBloc>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: bloc,
                                child: AdminBadgeFormPage(
                                  entity: badge,
                                ),
                              ),
                            ),
                          ).then((result) {
                            if (result == true) {
                              bloc.add(LoadBadges());
                            }
                          });
                        },
                        onDelete: () async {
                          final confirmed = await AdminDeleteDialog.show(
                            context,
                            badge.displayName,
                          );
                          if (confirmed == true && context.mounted) {
                            context
                                .read<BadgeBloc>()
                                .add(DeleteBadgeRequested(badge.id));
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
            final bloc = context.read<BadgeBloc>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: const AdminBadgeFormPage(),
                ),
              ),
            ).then((result) {
              if (result == true && context.mounted) {
                bloc.add(LoadBadges());
              }
            });
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
