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
            plan.type.displayName,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
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
