import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection_container.dart';
import '../../bloc/consultation_admin/consultation_admin_bloc.dart';
import '../../bloc/consultation_admin/consultation_admin_event.dart';
import '../../bloc/consultation_admin/consultation_admin_state.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_search_bar.dart';
import '../../widgets/admin_list_item.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_delete_dialog.dart';
import 'admin_consultation_form_page.dart';

/// Página de listagem de consultas no módulo admin.
/// Exibe lista filtrada com busca, ações de editar/excluir e FAB para criar.
class AdminConsultationsListPage extends StatelessWidget {
  const AdminConsultationsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ConsultationAdminBloc>()..add(LoadConsultations()),
      child: const _ConsultationsListView(),
    );
  }
}

class _ConsultationsListView extends StatelessWidget {
  const _ConsultationsListView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConsultationAdminBloc, ConsultationAdminState>(
      listenWhen: (previous, current) =>
          current.status == ConsultationAdminStatus.saved ||
          current.status == ConsultationAdminStatus.deleted ||
          current.status == ConsultationAdminStatus.failure,
      listener: (context, state) {
        if (state.status == ConsultationAdminStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Consulta salva com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == ConsultationAdminStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Consulta excluída com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == ConsultationAdminStatus.failure) {
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
          title: 'Consultas',
          body: Column(
            children: [
              // Barra de pesquisa
              AdminSearchBar(
                onChanged: (query) {
                  context
                      .read<ConsultationAdminBloc>()
                      .add(SearchConsultations(query));
                },
              ),
              const SizedBox(height: 12),
              // Filtros
              BlocBuilder<ConsultationAdminBloc, ConsultationAdminState>(
                buildWhen: (prev, curr) =>
                    prev.filterProfessional != curr.filterProfessional ||
                    prev.filterDateStart != curr.filterDateStart ||
                    prev.filterDateEnd != curr.filterDateEnd ||
                    prev.items != curr.items,
                builder: (context, state) {
                  return _FiltersSection(state: state);
                },
              ),
              const SizedBox(height: 16),
              // Título da seção
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Últimas consultas',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Lista de consultas
              BlocBuilder<ConsultationAdminBloc, ConsultationAdminState>(
                builder: (context, state) {
                  if (state.status == ConsultationAdminStatus.loading) {
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
                      state.status == ConsultationAdminStatus.loaded) {
                    return const AdminEmptyState(
                      icon: Icons.event_note_outlined,
                      message: 'Nenhuma consulta encontrada',
                      subtitle:
                          'Toque no botão + para cadastrar uma nova consulta.',
                    );
                  }

                  final visible = state.visibleItems;

                  return Column(
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final consultation = visible[index];
                          return AdminListItem(
                            title: consultation.title,
                            subtitle:
                                '${consultation.professionalName} - ${DateFormat('dd/MM/yyyy').format(consultation.date)}',
                            onEdit: () {
                              final bloc =
                                  context.read<ConsultationAdminBloc>();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: bloc,
                                    child: AdminConsultationFormPage(
                                      entity: consultation,
                                    ),
                                  ),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  context
                                      .read<ConsultationAdminBloc>()
                                      .add(LoadConsultations());
                                }
                              });
                            },
                            onDelete: () async {
                              final confirmed =
                                  await AdminDeleteDialog.show(
                                context,
                                consultation.title,
                              );
                              if (confirmed == true && context.mounted) {
                                context
                                    .read<ConsultationAdminBloc>()
                                    .add(DeleteConsultationRequested(
                                        consultation.id));
                              }
                            },
                          );
                        },
                      ),
                      if (state.hasMore) ...[
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => context
                              .read<ConsultationAdminBloc>()
                              .add(LoadMoreConsultations()),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE0E4EC),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Carregar mais',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.primaryColor,
          onPressed: () {
            final bloc = context.read<ConsultationAdminBloc>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: const AdminConsultationFormPage(),
                ),
              ),
            ).then((result) {
              if (result == true && context.mounted) {
                context
                    .read<ConsultationAdminBloc>()
                    .add(LoadConsultations());
              }
            });
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class _FiltersSection extends StatelessWidget {
  final ConsultationAdminState state;

  const _FiltersSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Filtro por profissional
          _FilterChip(
            icon: Icons.person_outlined,
            label: state.filterProfessional ?? 'Profissional',
            isActive: state.filterProfessional != null,
            onTap: () => _showProfessionalFilter(context),
          ),
          const SizedBox(width: 8),
          // Filtro por período
          _FilterChip(
            icon: Icons.calendar_today_outlined,
            label: state.filterDateStart != null ||
                    state.filterDateEnd != null
                ? _formatDateRange(
                    state.filterDateStart, state.filterDateEnd, dateFormat)
                : 'Período',
            isActive:
                state.filterDateStart != null || state.filterDateEnd != null,
            onTap: () => _showDateFilter(context),
          ),
          if (state.hasActiveFilters) ...[
            const SizedBox(width: 8),
            _FilterChip(
              icon: Icons.clear,
              label: 'Limpar',
              isActive: false,
              onTap: () =>
                  context.read<ConsultationAdminBloc>().add(ClearFilters()),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end, DateFormat fmt) {
    if (start != null && end != null) {
      return '${fmt.format(start)} - ${fmt.format(end)}';
    } else if (start != null) {
      return 'A partir de ${fmt.format(start)}';
    } else if (end != null) {
      return 'Até ${fmt.format(end)}';
    }
    return 'Período';
  }

  void _showProfessionalFilter(BuildContext context) {
    final professionals = state.availableProfessionals;
    if (professionals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nenhum profissional disponível para filtrar.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Filtrar por Profissional',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              if (state.filterProfessional != null)
                ListTile(
                  leading:
                      const Icon(Icons.clear, color: Colors.red, size: 20),
                  title: Text(
                    'Remover filtro',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    context
                        .read<ConsultationAdminBloc>()
                        .add(const FilterByProfessional(null));
                    Navigator.pop(bottomContext);
                  },
                ),
              ...professionals.map((name) => ListTile(
                    leading: Icon(
                      state.filterProfessional == name
                          ? Icons.check_circle
                          : Icons.person_outline,
                      color: state.filterProfessional == name
                          ? AppTheme.primaryColor
                          : const Color(0xFF6D7F95),
                      size: 20,
                    ),
                    title: Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: state.filterProfessional == name
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    onTap: () {
                      context
                          .read<ConsultationAdminBloc>()
                          .add(FilterByProfessional(name));
                      Navigator.pop(bottomContext);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showDateFilter(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: state.filterDateStart != null &&
              state.filterDateEnd != null
          ? DateTimeRange(
              start: state.filterDateStart!, end: state.filterDateEnd!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      context.read<ConsultationAdminBloc>().add(
            FilterByDateRange(start: picked.start, end: picked.end),
          );
    }
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                : const Color(0xFFE0E4EC),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  isActive ? AppTheme.primaryColor : const Color(0xFF6D7F95),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color:
                    isActive ? AppTheme.primaryColor : const Color(0xFF6D7F95),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
