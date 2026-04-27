import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/di/injection_container.dart';
import '../../bloc/payment_admin/payment_admin_bloc.dart';
import '../../bloc/payment_admin/payment_admin_event.dart';
import '../../bloc/payment_admin/payment_admin_state.dart';
import '../../widgets/admin_page_scaffold.dart';
import '../../widgets/admin_search_bar.dart';
import '../../widgets/admin_list_item.dart';
import '../../widgets/admin_status_badge.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/admin_delete_dialog.dart';
import 'admin_payment_detail_page.dart';

class AdminPaymentsListPage extends StatelessWidget {
  const AdminPaymentsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PaymentAdminBloc>()..add(LoadPayments()),
      child: const _PaymentsListView(),
    );
  }
}

class _PaymentsListView extends StatefulWidget {
  const _PaymentsListView();

  @override
  State<_PaymentsListView> createState() => _PaymentsListViewState();
}

class _PaymentsListViewState extends State<_PaymentsListView> {
  String? _filterStatus;
  String? _filterMethod;

  static const _statusOptions = ['aprovado', 'pendente', 'cancelado'];
  static const _methodOptions = ['cartao', 'pix', 'boleto'];

  List<dynamic> _applyLocalFilters(List<dynamic> items) {
    var result = items;
    if (_filterStatus != null) {
      result = result.where((p) => p.status == _filterStatus).toList();
    }
    if (_filterMethod != null) {
      result = result.where((p) => p.method == _filterMethod).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentAdminBloc, PaymentAdminState>(
      listenWhen: (previous, current) =>
          current.status == PaymentAdminStatus.saved ||
          current.status == PaymentAdminStatus.deleted ||
          current.status == PaymentAdminStatus.failure,
      listener: (context, state) {
        if (state.status == PaymentAdminStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pagamento salvo com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == PaymentAdminStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pagamento excluido com sucesso!',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state.status == PaymentAdminStatus.failure) {
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
          title: 'Pagamentos',
          body: Column(
            children: [
              // Barra de pesquisa
              AdminSearchBar(
                onChanged: (query) {
                  context
                      .read<PaymentAdminBloc>()
                      .add(SearchPayments(query));
                },
              ),
              const SizedBox(height: 12),
              // Filtros
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      icon: Icons.check_circle_outline,
                      label: _filterStatus ?? 'Status',
                      isActive: _filterStatus != null,
                      onTap: () => _showStatusFilter(context),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      icon: Icons.payment_outlined,
                      label: _filterMethod ?? 'Metodo',
                      isActive: _filterMethod != null,
                      onTap: () => _showMethodFilter(context),
                    ),
                    if (_filterStatus != null || _filterMethod != null) ...[
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        icon: Icons.clear,
                        label: 'Limpar',
                        isActive: false,
                        onTap: () {
                          setState(() {
                            _filterStatus = null;
                            _filterMethod = null;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Lista de pagamentos
              BlocBuilder<PaymentAdminBloc, PaymentAdminState>(
                builder: (context, state) {
                  if (state.status == PaymentAdminStatus.loading) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    );
                  }

                  final filtered = _applyLocalFilters(state.filteredItems);

                  if (filtered.isEmpty &&
                      state.status == PaymentAdminStatus.loaded) {
                    return const AdminEmptyState(
                      icon: Icons.payment_outlined,
                      message: 'Nenhum pagamento encontrado',
                      subtitle:
                          'Os pagamentos realizados aparecerao aqui.',
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final payment = filtered[index];
                      return AdminListItem(
                        title: payment.userName,
                        subtitle:
                            '${payment.planName} - ${payment.date} - R\$ ${payment.amount.toStringAsFixed(2)}',
                        leading: AdminStatusBadge(
                          status: payment.status,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminPaymentDetailPage(
                                entity: payment,
                              ),
                            ),
                          ).then((result) {
                            if (result == true) {
                              context
                                  .read<PaymentAdminBloc>()
                                  .add(LoadPayments());
                            }
                          });
                        },
                        onDelete: () async {
                          final confirmed = await AdminDeleteDialog.show(
                            context,
                            'pagamento de ${payment.userName}',
                          );
                          if (confirmed == true && context.mounted) {
                            context
                                .read<PaymentAdminBloc>()
                                .add(DeletePaymentRequested(payment.id));
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

  void _showStatusFilter(BuildContext context) {
    _showFilterBottomSheet(
      context,
      title: 'Filtrar por Status',
      options: _statusOptions,
      current: _filterStatus,
      onSelected: (value) {
        setState(() => _filterStatus = value);
      },
    );
  }

  void _showMethodFilter(BuildContext context) {
    _showFilterBottomSheet(
      context,
      title: 'Filtrar por Metodo',
      options: _methodOptions,
      current: _filterMethod,
      onSelected: (value) {
        setState(() => _filterMethod = value);
      },
    );
  }

  void _showFilterBottomSheet(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String? current,
    required ValueChanged<String?> onSelected,
  }) {
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
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              if (current != null)
                ListTile(
                  leading: const Icon(Icons.clear, color: Colors.red, size: 20),
                  title: Text(
                    'Remover filtro',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, color: Colors.red),
                  ),
                  onTap: () {
                    onSelected(null);
                    Navigator.pop(bottomContext);
                  },
                ),
              ...options.map((option) => ListTile(
                    leading: Icon(
                      current == option
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: current == option
                          ? AppTheme.primaryColor
                          : const Color(0xFF6D7F95),
                      size: 20,
                    ),
                    title: Text(
                      option[0].toUpperCase() + option.substring(1),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: current == option
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    onTap: () {
                      onSelected(option);
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

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
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
            Icon(icon, size: 14,
                color: isActive ? AppTheme.primaryColor : const Color(0xFF6D7F95)),
            const SizedBox(width: 6),
            Text(
              label[0].toUpperCase() + label.substring(1),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.primaryColor : const Color(0xFF6D7F95),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
