import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/receptionist_referral_entity.dart';
import '../bloc/receptionist_referrals_admin_bloc.dart';
import '../bloc/receptionist_referrals_admin_event.dart';
import '../bloc/receptionist_referrals_admin_state.dart';
import '../../../admin/presentation/widgets/admin_empty_state.dart';
import '../../../admin/presentation/widgets/admin_filter_chip.dart';
import '../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../../admin/presentation/widgets/admin_search_bar.dart';
import '../../../admin/presentation/widgets/admin_status_badge.dart';
import '../widgets/correct_referral_attribution_sheet.dart';

/// Tela "quem indicou": lista as indicações com filtros, histórico e
/// exportação CSV. Financeiro também corrige atribuições por aqui.
class AdminReferralsListPage extends StatelessWidget {
  const AdminReferralsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ReceptionistReferralsAdminBloc>()..add(const LoadReferrals()),
      child: const _AdminReferralsListView(),
    );
  }
}

class _AdminReferralsListView extends StatelessWidget {
  const _AdminReferralsListView();

  static const _statusOptions = ['pending', 'converted'];
  static const _statusLabels = {
    'pending': 'Pendente',
    'converted': 'Convertida',
  };

  List<String> _lastTwelveMonths() {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final date = DateTime(now.year, now.month - i, 1);
      return DateFormat('yyyy-MM').format(date);
    });
  }

  Future<void> _exportCsv(
    BuildContext context,
    List<ReceptionistReferralEntity> items,
  ) async {
    final rows = <List<dynamic>>[
      [
        'Indicado',
        'E-mail',
        'Recepcionista',
        'Código usado',
        'Cadastro',
        'Situação',
        'Ativação',
        'Plano contratado',
        'Valor',
      ],
    ];
    final dateFormat = DateFormat('dd/MM/yyyy');
    for (final item in items) {
      rows.add([
        item.referredUserName,
        item.referredUserEmail,
        item.receptionistName,
        item.referralCode,
        dateFormat.format(item.createdAt),
        _statusLabels[item.status.name] ?? item.status.name,
        item.convertedAt != null ? dateFormat.format(item.convertedAt!) : '',
        item.planNameAtConversion ?? '',
        item.planPriceAtConversion?.toStringAsFixed(2) ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/indicações.csv');
    await file.writeAsString(csv);

    if (!context.mounted) return;
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Indicações de recepcionistas',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReceptionistReferralsAdminBloc,
        ReceptionistReferralsAdminState>(
      listenWhen: (previous, current) =>
          current.status == ReceptionistReferralsAdminStatus.corrected ||
          current.status == ReceptionistReferralsAdminStatus.failure,
      listener: (context, state) {
        if (state.status == ReceptionistReferralsAdminStatus.corrected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Atribuição corrigida com sucesso!',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13)),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == ReceptionistReferralsAdminStatus.failure) {
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
        title: 'Quem Indicou',
        subtitle: 'Histórico de indicações das recepcionistas',
        actions: [
          BlocBuilder<ReceptionistReferralsAdminBloc,
              ReceptionistReferralsAdminState>(
            builder: (context, state) {
              return IconButton(
                onPressed: state.filteredItems.isEmpty
                    ? null
                    : () => _exportCsv(context, state.filteredItems),
                icon: const Icon(Icons.ios_share, color: AppTheme.primaryColor),
                tooltip: 'Exportar CSV',
              );
            },
          ),
        ],
        body: Column(
          children: [
            AdminSearchBar(
              hintText: 'Buscar por nome ou e-mail...',
              onChanged: (query) => context
                  .read<ReceptionistReferralsAdminBloc>()
                  .add(SearchReferrals(query)),
            ),
            const SizedBox(height: 12),
            BlocBuilder<ReceptionistReferralsAdminBloc,
                ReceptionistReferralsAdminState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      AdminFilterChip(
                        icon: Icons.calendar_month_outlined,
                        label: state.monthReference ?? 'Mês',
                        isActive: state.monthReference != null,
                        onTap: () {
                          AdminFilterChip.showFilterBottomSheet(
                            context,
                            title: 'Filtrar por mês',
                            options: _lastTwelveMonths(),
                            current: state.monthReference,
                            onSelected: (value) => context
                                .read<ReceptionistReferralsAdminBloc>()
                                .add(LoadReferrals(
                                  monthReference: value,
                                  receptionistId: state.receptionistId,
                                  status: state.referralStatus,
                                )),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      AdminFilterChip(
                        icon: Icons.toggle_on_outlined,
                        label: state.referralStatus != null
                            ? (_statusLabels[state.referralStatus!.name] ?? '')
                            : 'Situação',
                        isActive: state.referralStatus != null,
                        onTap: () {
                          AdminFilterChip.showFilterBottomSheet(
                            context,
                            title: 'Filtrar por situação',
                            options: _statusOptions,
                            current: state.referralStatus?.name,
                            displayNames: _statusLabels,
                            onSelected: (value) => context
                                .read<ReceptionistReferralsAdminBloc>()
                                .add(LoadReferrals(
                                  monthReference: state.monthReference,
                                  receptionistId: state.receptionistId,
                                  status: value == null
                                      ? null
                                      : ReceptionistReferralStatus.values
                                          .firstWhere((s) => s.name == value),
                                )),
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
                              .read<ReceptionistReferralsAdminBloc>()
                              .add(const LoadReferrals()),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            BlocBuilder<ReceptionistReferralsAdminBloc,
                ReceptionistReferralsAdminState>(
              builder: (context, state) {
                if (state.status == ReceptionistReferralsAdminStatus.loading) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor),
                    ),
                  );
                }

                if (state.filteredItems.isEmpty) {
                  return const AdminEmptyState(
                    icon: Icons.person_search_outlined,
                    message: 'Nenhuma indicação encontrada',
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.filteredItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = state.filteredItems[index];
                    return _ReferralListItem(item: item);
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

class _ReferralListItem extends StatelessWidget {
  final ReceptionistReferralEntity item;

  const _ReferralListItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final subtitleParts = <String>[
      item.referredUserEmail,
      'Recepcionista: ${item.receptionistName}',
      'Cadastro: ${dateFormat.format(item.createdAt)}',
      if (item.convertedAt != null)
        'Ativação: ${dateFormat.format(item.convertedAt!)}',
      if (item.planNameAtConversion != null)
        'Plano: ${item.planNameAtConversion}',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEEF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminStatusBadge(
            status: item.status == ReceptionistReferralStatus.converted
                ? 'ativo'
                : 'pendente',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.referredUserName,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleParts.join(' · '),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6D7F95),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Corrigir atribuição (financeiro)',
            onPressed: () => showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (sheetContext) => CorrectReferralAttributionSheet(
                referral: item,
                bloc: context.read<ReceptionistReferralsAdminBloc>(),
              ),
            ),
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: AppTheme.primaryColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
