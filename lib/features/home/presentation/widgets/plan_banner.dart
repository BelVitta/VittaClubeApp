import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/plan_level.dart';

/// Banner de status da patente/plano do usuário.
///
/// - [PlanLevel.none]: "Sem plano" + badge sem cor (cinza).
/// - Patentes (bronze/prata/ouro/diamante): nome + cor da patente.
/// - Estados negativos: inadimplente / cancelado.
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
                Expanded(
                  child: Column(
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
                          Flexible(
                            child: Text(
                              planLevel.displayName,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: planLevel.isColorless
                                    ? AppTheme.secondaryText
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          if (planLevel.nextLevel.isNotEmpty &&
                              !planLevel.isColorless) ...[
                            const SizedBox(width: 4),
                            Text(
                              '/ ${planLevel.nextLevel}',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                          if (planLevel.isColorless) ...[
                            const SizedBox(width: 4),
                            Text(
                              '/ ${planLevel.nextLevel}',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.secondaryText
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                _buildBadgeIcon(),
              ],
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(
                  height: 9,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: planLevel.progressBackgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: planLevel.isNegativeState
                      ? 1.0
                      : planLevel.isColorless
                          ? 0.0
                          : progress.clamp(0.0, 1.0),
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

    // Sem plano: badge “sem cor” (contorno cinza, ícone neutro).
    if (planLevel.isColorless) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDDFE5)),
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/icons/icon_badge.svg',
            width: 28,
            height: 28,
            colorFilter: const ColorFilter.mode(
              Color(0xFFB0B8C1),
              BlendMode.srcIn,
            ),
          ),
        ),
      );
    }

    // Patente ativa: ícone tingido com a cor da patente.
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
