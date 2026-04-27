import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection_container.dart';
import '../../bloc/draw/draw_bloc.dart';
import '../../bloc/draw/draw_event.dart';
import '../../bloc/draw/draw_state.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_search_bar.dart';
import '../../widgets/admin_list_item.dart';
import '../../widgets/admin_status_badge.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_delete_dialog.dart';
import '../../widgets/admin_filter_chip.dart';
import '../../../domain/entities/draw_entity.dart';
import 'admin_draw_form_page.dart';

class AdminDrawsListPage extends StatelessWidget {
  const AdminDrawsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DrawBloc>()..add(LoadDraws()),
      child: const _DrawsListView(),
    );
  }
}

class _DrawsListView extends StatelessWidget {
  const _DrawsListView();

  static const _statusDisplayMap = {
    'agendado': 'Agendado',
    'inscricoes_abertas': 'Inscricoes Abertas',
    'inscricoes_encerradas': 'Inscricoes Encerradas',
    'realizado': 'Realizado',
    'cancelado': 'Cancelado',
  };

  String _mapStatusToBadge(String status) {
    switch (status) {
      case 'inscricoes_abertas':
        return 'ativo';
      case 'realizado':
        return 'inativo';
      case 'agendado':
        return 'pendente';
      case 'inscricoes_encerradas':
        return 'pendente';
      case 'cancelado':
        return 'inativo';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _showExecuteDrawDialog(BuildContext context, DrawEntity draw) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.casino_outlined, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Realizar Sorteio',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voce esta prestes a realizar o sorteio:',
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF6D7F95)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draw.name,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Premio: ${draw.prizeName}',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6D7F95)),
                  ),
                  Text(
                    'Participantes: ${draw.participantCount}',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6D7F95)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_outlined, size: 18, color: Color(0xFFE65100)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acao e irreversivel. O sistema selecionara um vencedor automaticamente usando um algoritmo transparente e auditavel.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFFE65100),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancelar',
              style: GoogleFonts.outfit(color: const Color(0xFF6D7F95)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<DrawBloc>().add(ExecuteDrawRequested(draw.id));
            },
            child: Text(
              'Realizar Sorteio',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showDrawResultDialog(BuildContext context, DrawEntity draw) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Icon(Icons.emoji_events, size: 56, color: Color(0xFFFFD700)),
            const SizedBox(height: 16),
            Text(
              'Sorteio Realizado!',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              draw.prizeName,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF6D7F95),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C4156), Color(0xFF1A2A3A)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Ganhador(a)',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    draw.winnerName ?? 'N/A',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'O resultado foi gerado por um algoritmo transparente e auditavel. Consulte os detalhes do sorteio para ver as informacoes de auditoria.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFF6D7F95),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Fechar',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DrawBloc, DrawState>(
      listenWhen: (previous, current) =>
          current.status == DrawStatus.saved ||
          current.status == DrawStatus.deleted ||
          current.status == DrawStatus.executed ||
          current.status == DrawStatus.failure,
      listener: (context, state) {
        if (state.status == DrawStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sorteio salvo com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == DrawStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sorteio excluido com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == DrawStatus.executed && state.executedDraw != null) {
          _showDrawResultDialog(context, state.executedDraw!);
        } else if (state.status == DrawStatus.failure) {
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
          title: 'Sorteios',
          body: Column(
            children: [
              AdminSearchBar(
                onChanged: (query) {
                  context.read<DrawBloc>().add(SearchDraws(query));
                },
              ),
              const SizedBox(height: 12),
              // Filtros
              BlocBuilder<DrawBloc, DrawState>(
                buildWhen: (prev, curr) =>
                    prev.filterDrawStatus != curr.filterDrawStatus,
                builder: (context, state) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        AdminFilterChip(
                          icon: Icons.flag_outlined,
                          label: state.filterDrawStatus != null
                              ? (_statusDisplayMap[state.filterDrawStatus] ?? state.filterDrawStatus!)
                              : 'Status',
                          isActive: state.filterDrawStatus != null,
                          onTap: () {
                            AdminFilterChip.showFilterBottomSheet(
                              context,
                              title: 'Filtrar por Status',
                              options: ['agendado', 'inscricoes_abertas', 'inscricoes_encerradas', 'realizado'],
                              current: state.filterDrawStatus,
                              displayNames: _statusDisplayMap,
                              onSelected: (value) {
                                context.read<DrawBloc>().add(
                                    FilterDrawsByStatus(value));
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
                                .read<DrawBloc>()
                                .add(ClearDrawFilters()),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<DrawBloc, DrawState>(
                builder: (context, state) {
                  if (state.status == DrawStatus.loading || state.status == DrawStatus.executing) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Center(
                        child: Column(
                          children: [
                            const CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                            if (state.status == DrawStatus.executing) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Realizando sorteio...',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  if (state.filteredItems.isEmpty &&
                      state.status == DrawStatus.loaded) {
                    return const AdminEmptyState(
                      icon: Icons.emoji_events_outlined,
                      message: 'Nenhum sorteio encontrado',
                      subtitle:
                          'Toque no botao + para cadastrar um novo sorteio.',
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final draw = state.filteredItems[index];
                      return _buildDrawItem(context, draw);
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
            final bloc = context.read<DrawBloc>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: const AdminDrawFormPage(),
                ),
              ),
            );
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDrawItem(BuildContext context, DrawEntity draw) {
    final subtitle = StringBuffer();
    subtitle.write('${_formatDate(draw.drawDate)} - ${draw.participantCount} participantes');
    if (draw.isCompleted && draw.winnerName != null) {
      subtitle.write('\nVencedor: ${draw.winnerName}');
    }

    return AdminListItem(
      title: draw.name,
      subtitle: subtitle.toString(),
      leading: AdminStatusBadge(status: _mapStatusToBadge(draw.status)),
      trailing: draw.canExecuteDraw
          ? _buildExecuteButton(context, draw)
          : null,
      onEdit: () {
        final bloc = context.read<DrawBloc>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: AdminDrawFormPage(entity: draw),
            ),
          ),
        );
      },
      onDelete: draw.isCompleted
          ? null
          : () async {
              final confirmed = await AdminDeleteDialog.show(
                context,
                draw.name,
              );
              if (confirmed == true && context.mounted) {
                context
                    .read<DrawBloc>()
                    .add(DeleteDrawRequested(draw.id));
              }
            },
    );
  }

  Widget _buildExecuteButton(BuildContext context, DrawEntity draw) {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2C4156),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.casino_outlined, size: 14),
        label: const Text('Sortear'),
        onPressed: () => _showExecuteDrawDialog(context, draw),
      ),
    );
  }
}
