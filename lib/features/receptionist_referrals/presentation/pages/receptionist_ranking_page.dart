import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/receptionist_ranking_bloc.dart';
import '../bloc/receptionist_ranking_event.dart';
import '../bloc/receptionist_ranking_state.dart';
import '../widgets/receptionist_ranking_summary_card.dart';
import '../widgets/receptionist_ranking_tile.dart';
import '../../../admin/presentation/widgets/admin_empty_state.dart';
import '../../../admin/presentation/widgets/admin_page_scaffold.dart';

/// Ranking mensal das recepcionistas: cabeçalho com o desempenho da
/// recepcionista logada (dashboard individual) + lista completa abaixo.
class ReceptionistRankingPage extends StatelessWidget {
  const ReceptionistRankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ReceptionistRankingBloc>()..add(const LoadReceptionistRanking()),
      child: const _ReceptionistRankingView(),
    );
  }
}

class _ReceptionistRankingView extends StatelessWidget {
  const _ReceptionistRankingView();

  String _monthLabel(String monthReference) {
    final date = DateTime.parse('$monthReference-01');
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return '${months[date.month - 1][0].toUpperCase()}${months[date.month - 1].substring(1)}/${date.year}';
  }

  void _changeMonth(BuildContext context, String currentMonth, int offset) {
    final date = DateTime.parse('$currentMonth-01');
    final newDate = DateTime(date.year, date.month + offset, 1);
    final newMonth = DateFormat('yyyy-MM').format(newDate);
    context
        .read<ReceptionistRankingBloc>()
        .add(LoadReceptionistRanking(monthReference: newMonth));
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Ranking de Indicações',
      subtitle: 'Indicações e conversões por recepcionista',
      body: BlocBuilder<ReceptionistRankingBloc, ReceptionistRankingState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () =>
                        _changeMonth(context, state.monthReference, -1),
                    icon: const Icon(Icons.chevron_left,
                        color: AppTheme.primaryColor),
                  ),
                  Text(
                    _monthLabel(state.monthReference),
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        _changeMonth(context, state.monthReference, 1),
                    icon: const Icon(Icons.chevron_right,
                        color: AppTheme.primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (state.status == ReceptionistRankingStatus.loading)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                )
              else ...[
                if (state.ownEntry != null) ...[
                  ReceptionistRankingSummaryCard(entry: state.ownEntry!),
                  const SizedBox(height: 20),
                ],
                Text(
                  'Ranking completo',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                if (state.entries.isEmpty)
                  const AdminEmptyState(
                    icon: Icons.emoji_events_outlined,
                    message: 'Nenhuma indicação neste mês',
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = state.entries[index];
                      return ReceptionistRankingTile(
                        entry: entry,
                        isOwnEntry: entry.receptionistId == state.currentUserId,
                      );
                    },
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
