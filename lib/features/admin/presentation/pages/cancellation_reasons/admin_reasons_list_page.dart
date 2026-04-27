import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection_container.dart';
import '../../bloc/cancellation_reason/cancellation_reason_bloc.dart';
import '../../bloc/cancellation_reason/cancellation_reason_event.dart';
import '../../bloc/cancellation_reason/cancellation_reason_state.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_search_bar.dart';
import '../../widgets/admin_list_item.dart';
import '../../widgets/admin_status_badge.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_delete_dialog.dart';

class AdminReasonsListPage extends StatelessWidget {
  const AdminReasonsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CancellationReasonBloc>()..add(LoadCancellationReasons()),
      child: const _ReasonsListView(),
    );
  }
}

class _ReasonsListView extends StatelessWidget {
  const _ReasonsListView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CancellationReasonBloc, CancellationReasonState>(
      listenWhen: (previous, current) =>
          current.status == CancellationReasonStatus.saved ||
          current.status == CancellationReasonStatus.deleted ||
          current.status == CancellationReasonStatus.failure,
      listener: (context, state) {
        if (state.status == CancellationReasonStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Motivo de cancelamento salvo com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == CancellationReasonStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Motivo de cancelamento excluido com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == CancellationReasonStatus.failure) {
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
          title: 'Motivos de Cancelamento',
          body: Column(
            children: [
              AdminSearchBar(
                onChanged: (query) {
                  context.read<CancellationReasonBloc>().add(SearchCancellationReasons(query));
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<CancellationReasonBloc, CancellationReasonState>(
                builder: (context, state) {
                  if (state.status == CancellationReasonStatus.loading) {
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
                      state.status == CancellationReasonStatus.loaded) {
                    return const AdminEmptyState(
                      icon: Icons.cancel_outlined,
                      message: 'Nenhum motivo de cancelamento encontrado',
                      subtitle:
                          'Os motivos sao gerados automaticamente pelo fluxo de cancelamento.',
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final reason = state.filteredItems[index];
                      return AdminListItem(
                        title: reason.text,
                        subtitle: 'Uso: ${reason.usageCount} vezes',
                        leading: AdminStatusBadge(
                          status: reason.isActive ? 'ativo' : 'inativo',
                        ),
                        onDelete: () async {
                          final confirmed = await AdminDeleteDialog.show(
                            context,
                            reason.text,
                          );
                          if (confirmed == true && context.mounted) {
                            context
                                .read<CancellationReasonBloc>()
                                .add(DeleteCancellationReasonRequested(reason.id));
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
      ),
    );
  }
}
