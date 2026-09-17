import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/services/auth_session_manager.dart';
import '../../../admin/presentation/widgets/admin_dashboard_card.dart';
import '../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../domain/entities/partner_entity.dart';
import '../../domain/entities/partner_validation_entity.dart';
import '../../domain/usecases/partner/get_partner_by_profile_usecase.dart';
import '../../domain/usecases/partner_validation/get_partner_validations_usecase.dart';
import '../widgets/parceiro_how_it_works_card.dart';
import '../widgets/parceiro_metric_card.dart';
import 'partner_services_list_page.dart';
import 'partner_validations_list_page.dart';
import 'parceiro_validate_page.dart';

class ParceiroDashboardPage extends StatefulWidget {
  const ParceiroDashboardPage({super.key});

  @override
  State<ParceiroDashboardPage> createState() => _ParceiroDashboardPageState();
}

class _ParceiroDashboardPageState extends State<ParceiroDashboardPage> {
  late Future<(PartnerEntity, List<PartnerValidationEntity>)> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<(PartnerEntity, List<PartnerValidationEntity>)> _loadData() async {
    final profileId = SupabaseConfig.client.auth.currentUser?.id ?? '';
    final partnerResult = await sl<GetPartnerByProfileUseCase>()(profileId);
    final partner = partnerResult.fold(
      (failure) => throw Exception(failure.message),
      (partner) => partner,
    );
    final validationsResult =
        await sl<GetPartnerValidationsUseCase>()(partner.id);
    final validations = validationsResult.fold(
      (failure) => throw Exception(failure.message),
      (validations) => validations,
    );
    return (partner, validations);
  }

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
      subtitle: 'Valide a carteirinha no caixa e acompanhe o mês',
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
      body: FutureBuilder<(PartnerEntity, List<PartnerValidationEntity>)>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ParceiroHowItWorksCard(),
                const SizedBox(height: 24),
                Text(
                  'Não foi possível carregar seus dados de parceiro.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF6D7F95),
                  ),
                ),
              ],
            );
          }
          final (partner, validations) = snapshot.data!;
          final now = DateTime.now();
          final thisMonth = validations.where((v) =>
              v.validatedAt.year == now.year &&
              v.validatedAt.month == now.month);
          final validationsCount = thisMonth.length;
          final revenue =
              thisMonth.fold<double>(0, (sum, v) => sum + v.discountApplied);
          final currency =
              'R\$ ${revenue.toStringAsFixed(2).replaceAll('.', ',')}';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ParceiroHowItWorksCard(),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ParceiroValidatePage(),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                              'Validar desconto',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Leia a carteirinha no seu aparelho',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
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
              // Metricas
              Text(
                'Metricas do Mês',
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
                children: [
                  ParceiroMetricCard(
                    icon: Icons.check_circle_outlined,
                    iconColor: const Color(0xFF4CAF50),
                    title: 'Validações',
                    value: '$validationsCount',
                  ),
                  ParceiroMetricCard(
                    icon: Icons.attach_money,
                    iconColor: AppTheme.primaryColor,
                    title: 'Receita Descontos',
                    value: currency,
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
                    title: 'Serviços',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PartnerServicesListPage(
                          partnerId: partner.id,
                        ),
                      ),
                    ),
                  ),
                  AdminDashboardCard(
                    icon: Icons.verified_outlined,
                    title: 'Validações',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PartnerValidationsListPage(
                          partnerId: partner.id,
                        ),
                      ),
                    ),
                  ),
                  AdminDashboardCard(
                    icon: Icons.qr_code_scanner,
                    title: 'Validar',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParceiroValidatePage(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
