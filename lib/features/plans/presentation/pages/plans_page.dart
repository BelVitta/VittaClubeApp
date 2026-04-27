import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/datasources/plans_supabase_datasource.dart';
import '../../domain/entities/subscription_type.dart';
import '../widgets/plan_card.dart';
import '../widgets/plan_selection_item.dart';
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
  late final Future<List<RemotePlan>> _plansFuture;

  static const IconData _checkIcon = Icons.check_circle_outlined;

  SubscriptionType _selectedType = SubscriptionType.monthly;

  @override
  void initState() {
    super.initState();
    _plansFuture = sl<PlansSupabaseDataSource>().getActivePlans();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleContinue(List<RemotePlan> plans) {
    final selected = plans.firstWhere(
      (p) => p.subscriptionType == _selectedType,
      orElse: () => plans.first,
    );
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
                      AppTheme.gradientLight.withOpacity(0.3),
                      Colors.white.withOpacity(0),
                    ],
                    stops: const [0, 1],
                  ),
                ),
              ),
            ),
            FutureBuilder<List<RemotePlan>>(
              future: _plansFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _buildError(snap.error.toString());
                }
                final plans = snap.data ?? const [];
                if (plans.isEmpty) {
                  return _buildError('Nenhum plano disponível no momento.');
                }
                return _buildContent(plans);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<RemotePlan> plans) {
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
                        color: const Color(0xFF01225B).withOpacity(0.2),
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
                    const SizedBox(height: 12),
                    _buildPlansCarousel(plans),
                    const SizedBox(height: 12),
                    _buildPlanSelection(plans),
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
            text: 'Continuar',
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Planos',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
            letterSpacing: 0.12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Conheça nossos planos de fidelidade e descubra os benefícios que melhor combinam com você.',
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

  Widget _buildPlanSelection(List<RemotePlan> plans) {
    return Column(
      children: plans.map((p) {
        final t = p.subscriptionType;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: PlanSelectionItem(
            type: t,
            isSelected: _selectedType == t,
            onTap: () => setState(() => _selectedType = t),
          ),
        );
      }).toList(),
    );
  }
}
