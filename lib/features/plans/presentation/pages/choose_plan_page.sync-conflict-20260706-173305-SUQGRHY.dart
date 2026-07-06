import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/datasources/plans_supabase_datasource.dart';
import '../widgets/plan_benefit_item.dart';
import '../widgets/plan_selection_item.dart';
import 'payment_page.dart';

/// Página "Escolha o seu plano" — seleção detalhada do período + benefícios.
class ChoosePlanPage extends StatefulWidget {
  final RemotePlan initialPlan;
  final List<RemotePlan> allPlans;

  const ChoosePlanPage({
    super.key,
    required this.initialPlan,
    required this.allPlans,
  });

  @override
  State<ChoosePlanPage> createState() => _ChoosePlanPageState();
}

class _ChoosePlanPageState extends State<ChoosePlanPage> {
  late RemotePlan _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialPlan;
  }

  void _handleSubscribe() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(selectedPlan: _selected),
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
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 39,
                          height: 39,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF01225B).withValues(alpha: 0.2),
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
                        Text(
                          'Escolha o seu plano',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nossos planos de fidelidade garantem uma experiência completa, com prioridade nos serviços, benefícios diferenciados e descontos exclusivos.',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6D7F95),
                            letterSpacing: 0.07,
                            height: 1.07,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPlanSelection(),
                        const SizedBox(height: 12),
                        _buildBenefitsSection(),
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
                text: 'Assinar Agora',
                onPressed: _handleSubscribe,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSelection() {
    return Column(
      children: widget.allPlans.map((plan) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: PlanSelectionItem(
            type: plan.subscriptionType,
            isSelected: _selected.id == plan.id,
            onTap: () => setState(() => _selected = plan),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C96C4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benefícios',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          ..._selected.benefits.map(
            (b) => PlanBenefitItem(
              title: b.title,
              description: b.description,
            ),
          ),
        ],
      ),
    );
  }
}
