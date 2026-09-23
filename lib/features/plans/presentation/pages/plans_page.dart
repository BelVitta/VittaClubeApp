import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/datasources/plans_supabase_datasource.dart';
import '../widgets/plan_card.dart';
import 'choose_plan_page.dart';

/// Página de seleção de planos de assinatura. Carrega os planos ativos e seus
/// benefícios do Supabase (`plans` + `plan_benefits`).
class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  final PageController _pageController = PageController();
  late final Future<PlansCatalog> _catalogFuture;

  static const IconData _checkIcon = Icons.check_circle_outlined;

  @override
  void initState() {
    super.initState();
    _catalogFuture = AppConfig.instance.useSupabase
        ? sl<PlansSupabaseDataSource>().getCatalog()
        : Future.error(StateError(
            'Configure SUPABASE_URL e SUPABASE_ANON_KEY para o ambiente dev.',
          ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleContinue(List<RemotePlan> plans) {
    final selected = plans.first;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChoosePlanPage(
          initialPlan: selected,
          allPlans: plans,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -16,
              left: MediaQuery.of(context).size.width / 2 - 251.75,
              child: Container(
                width: 503.5,
                height: 283.06,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.gradientLight.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 1],
                  ),
                ),
              ),
            ),
            FutureBuilder<PlansCatalog>(
              future: _catalogFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _buildError(snap.error.toString());
                }
                final plans = snap.data?.plans ?? const <RemotePlan>[];
                if (plans.isEmpty) {
                  return _buildEmpty();
                }
                return _buildContent(plans, snap.data?.badges ?? const []);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<RemotePlan> plans, List<RemoteBadge> badges) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    child: Container(
                      width: 39,
                      height: 39,
                      decoration: BoxDecoration(
                        color: const Color(0xFF01225B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(19.5),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    _buildPlansCarousel(plans),
                    const SizedBox(height: 18),
                    _buildLoyaltyJourney(badges),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          left: 24,
          right: 24,
          child: PrimaryButton(
            text: 'Quero fazer parte',
            onPressed: () => _handleContinue(plans),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'Não foi possível carregar os planos.',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF6D7F95),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _catalogFuture = AppConfig.instance.useSupabase
                    ? sl<PlansSupabaseDataSource>().getCatalog()
                    : Future.error(StateError(
                        'Configure SUPABASE_URL e SUPABASE_ANON_KEY para o ambiente dev.',
                      ));
              }),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() => _buildError(
        'O catálogo está sendo atualizado. Tente novamente em instantes.',
      );

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuide de você. Evolua com o clube.',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
            letterSpacing: 0.12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Um plano mensal, benefícios que crescem com o tempo e vantagens exclusivas em cada patente.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D7F95),
            letterSpacing: 0.07,
            height: 1.07,
          ),
        ),
      ],
    );
  }

  Widget _buildPlansCarousel(List<RemotePlan> plans) {
    return SizedBox(
      height: 350,
      child: PageView.builder(
        controller: _pageController,
        itemCount: plans.length,
        itemBuilder: (context, index) {
          return PlanCard(
            plan: plans[index].toPlanEntity(),
            checkIcon: _checkIcon,
          );
        },
      ),
    );
  }

  Widget _buildLoyaltyJourney(List<RemoteBadge> badges) {
    if (badges.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sua jornada de patentes',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cada mensalidade aprovada aproxima você do próximo nível.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF6D7F95),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FE),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCE6F5)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < badges.length; i++) ...[
                _buildBadgeStep(badges[i], i == badges.length - 1),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Seu progresso é preservado mesmo se você fizer uma pausa. Os benefícios ficam disponíveis enquanto a assinatura estiver ativa.',
          style: GoogleFonts.outfit(
            fontSize: 12,
            height: 1.25,
            color: const Color(0xFF6D7F95),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeStep(RemoteBadge badge, bool isLast) {
    final color = switch (badge.levelName.toLowerCase()) {
      'bronze' => const Color(0xFFAD6C3D),
      'prata' => const Color(0xFF718096),
      'ouro' => const Color(0xFFC28A18),
      'diamante' => const Color(0xFF4189C7),
      _ => AppTheme.primaryColor,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: color.withValues(alpha: 0.16),
              child: Icon(Icons.workspace_premium, color: color, size: 20),
            ),
            if (!isLast)
              Container(
                  width: 2, height: 40, color: color.withValues(alpha: 0.22)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      badge.displayName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${badge.requiredMonths} ${badge.requiredMonths == 1 ? 'mês' : 'meses'}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${badge.discountPercentage.toStringAsFixed(0)}% de desconto em consultas · ${badge.drawLabel}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF6D7F95),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
