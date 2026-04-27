import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/services/auth_session_manager.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../widgets/admin_page_scaffold.dart';
import '../widgets/admin_dashboard_card.dart';
import 'specialties/admin_specialties_list_page.dart';
import 'professionals/admin_professionals_list_page.dart';
import 'users/admin_users_list_page.dart';
import 'payments/admin_payments_list_page.dart';
import 'consultations/admin_consultations_list_page.dart';
import 'notifications/admin_notifications_list_page.dart';
import 'draws/admin_draws_list_page.dart';
import 'admin_qr_scanner_page.dart';
import 'coupons/admin_coupons_list_page.dart';
import 'cancellation_reasons/admin_reasons_list_page.dart';
import 'clinic_settings/admin_clinic_settings_page.dart';

/// Painel administrativo principal com grid de acesso rápido
/// às entidades do sistema, organizadas por seção.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

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
      title: 'Administração',
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
          // Ação rápida: Scanner QR
          // ============================================================
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminQrScannerPage(),
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
                      Icons.qr_code_scanner,
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
                          'Ler QR Code',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Validar carteirinha do paciente',
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
          const SizedBox(height: 24),

          // ============================================================
          // Seção: Cadastros
          // ============================================================
          Text(
            'Cadastros',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 0.92,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              AdminDashboardCard(
                icon: Icons.medical_services_outlined,
                title: 'Profissionais',

                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminProfessionalsListPage(),
                  ),
                ),
              ),
              AdminDashboardCard(
                icon: Icons.category_outlined,
                title: 'Especialidades',

                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminSpecialtiesListPage(),
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
          // Seção: Operações
          // ============================================================
          Text(
            'Operações',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 0.92,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              AdminDashboardCard(
                icon: Icons.payment_outlined,
                title: 'Pagamentos',

                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminPaymentsListPage(),
                  ),
                ),
              ),
              AdminDashboardCard(
                icon: Icons.event_note_outlined,
                title: 'Consultas',

                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminConsultationsListPage(),
                  ),
                ),
              ),
              AdminDashboardCard(
                icon: Icons.notifications_outlined,
                title: 'Notificações',

                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminNotificationsListPage(),
                  ),
                ),
              ),
              AdminDashboardCard(
                icon: Icons.card_giftcard_outlined,
                title: 'Sorteios',

                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminDrawsListPage(),
                  ),
                ),
              ),
              AdminDashboardCard(
                icon: Icons.local_offer_outlined,
                title: 'Cupons',

                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminCouponsListPage(),
                  ),
                ),
              ),
              AdminDashboardCard(
                icon: Icons.qr_code_scanner_outlined,
                title: 'Scanner QR',

                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminQrScannerPage(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ============================================================
          // Seção: Configurações
          // ============================================================
          Text(
            'Configurações',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 0.92,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
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
                icon: Icons.settings_outlined,
                title: 'Clínica',

                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminClinicSettingsPage(),
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
