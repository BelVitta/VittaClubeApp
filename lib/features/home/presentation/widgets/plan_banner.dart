import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/plan_level.dart';

/// Widget que exibe o banner com o status do plano do usuário
class PlanBanner extends StatelessWidget {
  final PlanLevel planLevel;
  final double progress;
  final VoidCallback? onTap;

  const PlanBanner({
    super.key,
    required this.planLevel,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEBEEF2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planLevel.getStatusText(),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: planLevel.isNegativeState
                          ? planLevel.progressColor.withValues(alpha: 0.8)
                          : AppTheme.primaryColor.withValues(alpha: 0.4),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        planLevel.displayName,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      if (planLevel.nextLevel.isNotEmpty) ...[
                        const SizedBox(width: 2),
                        Text(
                          '/ ${planLevel.nextLevel}',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                      if (planLevel == PlanLevel.inadimplente) ...[
                        const SizedBox(width: 4),
                        Text(
                          '/ {planAtual}',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                      if (planLevel == PlanLevel.cancelado) ...[
                        const SizedBox(width: 4),
                        Text(
                          '/ Diamante',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              // Badge icon
              _buildBadgeIcon(),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar with stack for proper layering
          Stack(
            children: [
              // Background bar
              Container(
                height: 9,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: planLevel.progressBackgroundColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Progress bar
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor:
                    planLevel.isNegativeState ? 1.0 : progress.clamp(0.0, 1.0),
                child: Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: planLevel.progressColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildBadgeIcon() {
    if (planLevel == PlanLevel.inadimplente) {
      // Orange hexagonal warning icon
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFE8872B),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE8872B).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.error_outline, size: 28, color: Colors.white),
        ),
      );
    }
    if (planLevel == PlanLevel.cancelado) {
      // Dark hexagonal X icon
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.close, size: 28, color: Colors.white),
        ),
      );
    }
    // Default badge icon — SVG tingido com a cor do nível atual.
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: planLevel.progressColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SvgPicture.asset(
          'assets/icons/icon_badge.svg',
          width: 28,
          height: 28,
          colorFilter: ColorFilter.mode(
            planLevel.progressColor,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
