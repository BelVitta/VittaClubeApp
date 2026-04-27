import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/services/auth_session_manager.dart';
import '../../../admin/presentation/widgets/admin_dashboard_card.dart';
import '../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../widgets/parceiro_metric_card.dart';
import 'partner_services_list_page.dart';
import 'partner_validations_list_page.dart';
import 'partner_code_page.dart';

class ParceiroDashboardPage extends StatelessWidget {
  const ParceiroDashboardPage({super.key});

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
      title: 'Painel Parceiro',
      subtitle: 'Gerencie seus servicos e validacoes',
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
          // Metricas
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
              ParceiroMetricCard(
                icon: Icons.check_circle_outlined,
                iconColor: Color(0xFF4CAF50),
                title: 'Validacoes',
                value: '32',
                variation: '+15%',
                isPositiveVariation: true,
              ),
              ParceiroMetricCard(
                icon: Icons.attach_money,
                iconColor: AppTheme.primaryColor,
                title: 'Receita Descontos',
                value: 'R\$ 2.840',
                variation: '+8%',
                isPositiveVariation: true,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Gestao
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
                icon: Icons.medical_services_outlined,
                title: 'Servicos',
                count: 0,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PartnerServicesListPage(
                      partnerId: 'partner-001',
                    ),
                  ),
                ),
              ),
              AdminDashboardCard(
                icon: Icons.verified_outlined,
                title: 'Validacoes',
                count: 0,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PartnerValidationsListPage(
                      partnerId: 'partner-001',
                    ),
                  ),
                ),
              ),
              AdminDashboardCard(
                icon: Icons.qr_code_outlined,
                title: 'Meu Codigo',
                count: 0,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PartnerCodePage(
                      partnerId: 'partner-001',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
