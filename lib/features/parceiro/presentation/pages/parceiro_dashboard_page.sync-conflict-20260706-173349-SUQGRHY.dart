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
import '../../domain/usecases/partner/get_partner_by_profile_usecase.dart';
import '../widgets/parceiro_metric_card.dart';
import 'partner_services_list_page.dart';
import 'partner_validations_list_page.dart';
import 'partner_code_page.dart';

class ParceiroDashboardPage extends StatelessWidget {
  const ParceiroDashboardPage({super.key});

  Future<_PartnerDashboardData> _loadData() async {
    final profileId = SupabaseConfig.client.auth.currentUser?.id;
    if (profileId == null) {
      throw StateError('Usuário não autenticado.');
    }

    final partnerResult = await sl<GetPartnerByProfileUseCase>()(profileId);
    final partner = partnerResult.fold(
      (failure) => throw Exception(failure.message),
      (value) => value,
    );

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    final supabase = SupabaseConfig.client;

    final validations = await supabase
        .from('partner_validations')
        .select('id, discount_applied')
        .eq('partner_id', partner.id)
        .gte('validated_at', monthStart);
    final services = await supabase
        .from('partner_services')
        .select('id')
        .eq('partner_id', partner.id)
        .eq('is_active', true);

    final validationRows = validations as List<dynamic>;
    final discountTotal = validationRows.fold<double>(
      0,
      (sum, row) =>
          sum +
          (((row as Map<String, dynamic>)['discount_applied'] as num?)
                  ?.toDouble() ??
              0),
    );

    return _PartnerDashboardData(
      partner: partner,
      validationsThisMonth: validationRows.length,
      discountTotal: discountTotal,
      activeServices: (services as List<dynamic>).length,
    );
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
    return FutureBuilder<_PartnerDashboardData>(
      future: _loadData(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        return AdminPageScaffold(
          title: 'Painel Parceiro',
          subtitle: 'Gerencie seus servicos e validacoes',
          allowedRoles: const ['parceiro'],
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
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : snapshot.hasError || data == null
                  ? Center(
                      child: Text(
                        'Não foi possível carregar seus dados de parceiro.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF6D7F95),
                        ),
                      ),
                    )
                  : Column(
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
                          children: [
                            ParceiroMetricCard(
                              icon: Icons.check_circle_outlined,
                              iconColor: Color(0xFF4CAF50),
                              title: 'Validacoes',
                              value: data.validationsThisMonth.toString(),
                              variation: 'mês atual',
                              isPositiveVariation: true,
                            ),
                            ParceiroMetricCard(
                              icon: Icons.attach_money,
                              iconColor: AppTheme.primaryColor,
                              title: 'Receita Descontos',
                              value: _money(data.discountTotal),
                              variation: 'economia gerada',
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
                              count: data.activeServices,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PartnerServicesListPage(
                                    partnerId: data.partner.id,
                                  ),
                                ),
                              ),
                            ),
                            AdminDashboardCard(
                              icon: Icons.verified_outlined,
                              title: 'Validacoes',
                              count: data.validationsThisMonth,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PartnerValidationsListPage(
                                    partnerId: data.partner.id,
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
                                  builder: (_) => PartnerCodePage(
                                    partnerId: data.partner.id,
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
      },
    );
  }

  static String _money(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _PartnerDashboardData {
  final PartnerEntity partner;
  final int validationsThisMonth;
  final double discountTotal;
  final int activeServices;

  const _PartnerDashboardData({
    required this.partner,
    required this.validationsThisMonth,
    required this.discountTotal,
    required this.activeServices,
  });
}
