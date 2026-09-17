import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/financeiro_dashboard_metrics.dart';
import '../../domain/usecases/get_financeiro_dashboard_metrics_usecase.dart';
import '../../../auth/data/services/auth_session_manager.dart';
import '../../../admin/presentation/pages/admin_dashboard_page.dart';
import '../../../admin/presentation/pages/badges/admin_badges_list_page.dart';
import '../../../admin/presentation/pages/plans/admin_plans_list_page.dart';
import '../../../admin/presentation/pages/users/admin_users_list_page.dart';
import '../../../admin/presentation/pages/payments/admin_payments_list_page.dart';
import '../../../admin/presentation/pages/cancellation_reasons/admin_reasons_list_page.dart';
import '../../../admin/presentation/widgets/admin_dashboard_card.dart';
import '../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../parceiro/presentation/pages/financeiro_partners_list_page.dart';
import '../widgets/financeiro_how_it_works_card.dart';
import '../widgets/financeiro_metric_card.dart';

/// Dashboard principal do Financeiro.
/// Mostra metricas, gestao estrategica e acesso ao painel operacional (admin).
class FinanceiroDashboardPage extends StatelessWidget {
  const FinanceiroDashboardPage({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              await sl<AuthSessionManager>().clearSession();
              if (!context.mounted) return;
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Financeiro',
      subtitle: 'Visão gerencial',
      actions: [
        GestureDetector(
          onTap: () => _showLogoutDialog(context),
          child: Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.logout,
              size: 18,
              color: Colors.red,
            ),
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FinanceiroHowItWorksCard(),
          const SizedBox(height: 24),
          // ============================================================
          // Metricas
          // ============================================================
          Text(
            'Metricas do Mês',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const _FinanceiroMetricsGrid(),
          const SizedBox(height: 24),

          // ============================================================
          // Gestao Estrategica
          // ============================================================
          Text(
            'Gestao',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              AdminDashboardCard(
                icon: Icons.card_membership_outlined,
                title: 'Planos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminPlansListPage(),
                  ),
                ),
              ),
              AdminDashboardCard(
                icon: Icons.military_tech_outlined,
                title: 'Badges',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminBadgesListPage(),
                  ),
                ),
              ),
              AdminDashboardCard(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Equipe',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminUsersListPage(),
                  ),
                ),
              ),
              AdminDashboardCard(
                icon: Icons.handshake_outlined,
                title: 'Parceiros',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FinanceiroPartnersListPage(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ============================================================
          // Relatorios
          // ============================================================
          Text(
            'Relatórios',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              AdminDashboardCard(
                icon: Icons.receipt_long_outlined,
                title: 'Faturamento',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminPaymentsListPage(),
                  ),
                ),
              ),
              AdminDashboardCard(
                icon: Icons.cancel_outlined,
                title: 'Motivos Canc.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminReasonsListPage(),
                  ),
                ),
              ),
              AdminDashboardCard(
                icon: Icons.people_outlined,
                title: 'Usuários',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminUsersListPage(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ============================================================
          // Acesso ao painel operacional (admin)
          // ============================================================
          Text(
            'Operacional',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminDashboardPage(),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.dashboard_outlined,
                      size: 24,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Painel Administrativo',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Acesso completo às funções do admin',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6D7F95),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FinanceiroMetricsGrid extends StatefulWidget {
  const _FinanceiroMetricsGrid();

  @override
  State<_FinanceiroMetricsGrid> createState() => _FinanceiroMetricsGridState();
}

class _FinanceiroMetricsGridState extends State<_FinanceiroMetricsGrid> {
  late Future<FinanceiroDashboardMetrics> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<FinanceiroDashboardMetrics> _load() async {
    final result = await sl<GetFinanceiroDashboardMetricsUseCase>()();
    return result.fold((failure) => throw Exception(failure.message), (m) => m);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return FutureBuilder<FinanceiroDashboardMetrics>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Text(
            'Não foi possível carregar as métricas do mês.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF6D7F95),
            ),
          );
        }
        final metrics = snapshot.data!;
        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4,
          children: [
            FinanceiroMetricCard(
              icon: Icons.attach_money,
              iconColor: const Color(0xFF4CAF50),
              title: 'Receita do Mês',
              value: currency.format(metrics.monthRevenue),
            ),
            FinanceiroMetricCard(
              icon: Icons.people_outlined,
              iconColor: AppTheme.primaryColor,
              title: 'Membros Ativos',
              value: '${metrics.activeMembers}',
            ),
            FinanceiroMetricCard(
              icon: Icons.warning_amber_outlined,
              iconColor: const Color(0xFFFF9800),
              title: 'Inadimplentes',
              value: '${metrics.overdueMembers}',
            ),
            FinanceiroMetricCard(
              icon: Icons.cancel_outlined,
              iconColor: const Color(0xFFE53935),
              title: 'Cancelamentos',
              value: '${metrics.monthCancellations}',
            ),
          ],
        );
      },
    );
  }
}
