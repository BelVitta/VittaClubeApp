import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
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
import '../../../parceiro/presentation/pages/user/partners_list_page.dart';
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
      subtitle: 'Visao gerencial',
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
          // ============================================================
          // Metricas
          // ============================================================
          Text(
            'Metricas do Mes',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            children: const [
              FinanceiroMetricCard(
                icon: Icons.attach_money,
                iconColor: Color(0xFF4CAF50),
                title: 'Receita do Mes',
                value: 'R\$ 12.450',
                variation: '+8%',
                isPositiveVariation: true,
              ),
              FinanceiroMetricCard(
                icon: Icons.people_outlined,
                iconColor: AppTheme.primaryColor,
                title: 'Membros Ativos',
                value: '247',
                variation: '+12',
                isPositiveVariation: true,
              ),
              FinanceiroMetricCard(
                icon: Icons.warning_amber_outlined,
                iconColor: Color(0xFFFF9800),
                title: 'Inadimplentes',
                value: '18',
                variation: '-3',
                isPositiveVariation: true,
              ),
              FinanceiroMetricCard(
                icon: Icons.cancel_outlined,
                iconColor: Color(0xFFE53935),
                title: 'Cancelamentos',
                value: '5',
                variation: '+2',
                isPositiveVariation: false,
              ),
            ],
          ),
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
                count: 0,
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
                count: 0,
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
                count: 0,
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
                count: 0,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PartnersListPage(),
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
            'Relatorios',
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
                count: 0,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminPaymentsListPage(),
                  ),
                ),
              ),
              AdminDashboardCard(
                icon: Icons.cancel_outlined,
                title: 'Cancelamentos',
                count: 0,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminReasonsListPage(),
                  ),
                ),
              ),
              AdminDashboardCard(
                icon: Icons.people_outlined,
                title: 'Usuarios',
                count: 0,
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
                          'Acesso completo as funcoes do admin',
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
