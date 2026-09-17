import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../profile/domain/entities/profile_entity.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/services/auth_session_manager.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../widgets/admin_page_scaffold.dart';
import '../widgets/admin_dashboard_card.dart';
import '../widgets/admin_how_it_works_card.dart';
import 'specialties/admin_specialties_list_page.dart';
import 'professionals/admin_professionals_list_page.dart';
import 'users/admin_users_list_page.dart';
import 'dependents/admin_dependents_list_page.dart';
import 'payments/admin_payments_list_page.dart';
import 'consultations/admin_consultations_list_page.dart';
import 'notifications/admin_notifications_list_page.dart';
import 'draws/admin_draws_list_page.dart';
import 'admin_qr_scanner_page.dart';
import 'coupons/admin_coupons_list_page.dart';
import 'clinic_settings/admin_clinic_settings_page.dart';
import '../../../receptionist_referrals/presentation/pages/receptionist_ranking_page.dart';
import '../../../receptionist_referrals/presentation/pages/admin_referrals_list_page.dart';
import '../../../parceiro/presentation/pages/admin_partner_applications_list_page.dart';

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
    return BlocProvider(
      create: (_) => sl<ProfileBloc>()..add(const LoadCurrentProfile()),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoaded && state.profile.hasAdminAccess) {
            return _buildDashboard(context, state.profile);
          }
          if (state is ProfileLoading || state is ProfileInitial) {
            return const AdminPageScaffold(
              title: 'Administração',
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildAccessDenied(context);
        },
      ),
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return AdminPageScaffold(
      title: 'Administração',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Acesso restrito',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Esta área é exclusiva para administradores.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6D7F95),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, ProfileEntity profile) {
    final isRecepcionista = profile.role == 'admin';
    return AdminPageScaffold(
      title: 'Administração',
      showBackButton: false,
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
          const AdminHowItWorksCard(),
          if (isRecepcionista &&
              (profile.receptionistCode ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _ReceptionistCodeCard(code: profile.receptionistCode!.trim()),
          ],
          const SizedBox(height: 16),
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
              AdminDashboardCard(
                icon: Icons.family_restroom_outlined,
                title: 'Dependentes',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminDependentsListPage(),
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
              if (isRecepcionista)
                AdminDashboardCard(
                  icon: Icons.emoji_events_outlined,
                  title: 'Ranking Indicações',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReceptionistRankingPage(),
                    ),
                  ),
                ),
              AdminDashboardCard(
                icon: Icons.person_search_outlined,
                title: 'Quem Indicou',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminReferralsListPage(),
                  ),
                ),
              ),
              AdminDashboardCard(
                icon: Icons.handshake_outlined,
                title: 'Candidaturas Parceiro',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminPartnerApplicationsListPage(),
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

class _ReceptionistCodeCard extends StatelessWidget {
  final String code;

  const _ReceptionistCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E4EC)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seu código no balcão',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF6D7F95),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Passe este código no cadastro de quem você indicar.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF6D7F95),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar código',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código copiado.')),
              );
            },
            icon: const Icon(Icons.copy_outlined, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}
