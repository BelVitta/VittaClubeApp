import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/plan_entity.dart';
import 'plan_benefit_item.dart';

/// Widget do card de plano no carrossel horizontal
class PlanCard extends StatelessWidget {
  final PlanEntity plan;
  final IconData? checkIcon;

  const PlanCard({
    super.key,
    required this.plan,
    this.checkIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 314,
      margin: const EdgeInsets.only(right: 12),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Plan title
          Text(
            plan.name.isEmpty ? plan.type.displayName : plan.name,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'R\$ ${plan.price.toStringAsFixed(2).replaceAll('.', ',')}',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '/mês',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF6D7F95),
                ),
              ),
            ],
          ),
          Text(
            'Sem permanência mínima · cancele quando quiser',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFF6D7F95),
            ),
          ),
          const SizedBox(height: 6),
          // Benefits list
          Column(
            children: plan.benefits.map((benefit) {
              return PlanBenefitItem(
                title: benefit.title,
                description: benefit.description,
                checkIcon: checkIcon,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
