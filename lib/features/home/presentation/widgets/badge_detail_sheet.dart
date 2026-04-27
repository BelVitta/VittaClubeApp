import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/consultation_limit_service.dart';
import '../../../../core/services/discount_service.dart';
import '../../domain/entities/plan_level.dart';

/// Bottom sheet que exibe detalhes do badge ao clicar no PlanBanner.
class BadgeDetailSheet extends StatelessWidget {
  final PlanLevel planLevel;
  final double progress;
  final int consultationsThisMonth;
  final int monthsAsMember;
  final int totalConsultations;
  final bool hasAnnualPlan;
  final VoidCallback? onViewPlans;

  const BadgeDetailSheet({
    super.key,
    required this.planLevel,
    required this.progress,
    this.consultationsThisMonth = 0,
    this.monthsAsMember = 0,
    this.totalConsultations = 0,
    this.hasAnnualPlan = false,
    this.onViewPlans,
  });

  /// Abre o bottom sheet
  static void show(
    BuildContext context, {
    required PlanLevel planLevel,
    required double progress,
    int consultationsThisMonth = 0,
    int monthsAsMember = 0,
    int totalConsultations = 0,
    bool hasAnnualPlan = false,
    VoidCallback? onViewPlans,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BadgeDetailSheet(
        planLevel: planLevel,
        progress: progress,
        consultationsThisMonth: consultationsThisMonth,
        monthsAsMember: monthsAsMember,
        totalConsultations: totalConsultations,
        hasAnnualPlan: hasAnnualPlan,
        onViewPlans: onViewPlans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE1E6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildBadgeSummary(),
                const SizedBox(height: 24),
                _buildConsultationsSection(),
                const SizedBox(height: 24),
                if (_showProgressSection()) ...[
                  _buildProgressSection(),
                  const SizedBox(height: 24),
                  _buildNextLevelBenefits(),
                  const SizedBox(height: 24),
                ],
                if (onViewPlans != null) _buildCTA(context),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Seção 1: Resumo do nível atual ──

  Widget _buildBadgeSummary() {
    final discount = DiscountService.getDefaultDiscount(_badgeLevelString());

    return Row(
      children: [
        // Ícone grande do badge
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: planLevel.progressColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(
              planLevel.getBadgeIcon(),
              size: 36,
              color: planLevel.progressColor,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                planLevel.displayName,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Membro há $monthsAsMember ${monthsAsMember == 1 ? 'mês' : 'meses'}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                ),
              ),
              if (discount > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: planLevel.progressColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${discount.toStringAsFixed(0)}% de desconto',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: planLevel.progressColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Seção 2: Consultas do mês ──

  Widget _buildConsultationsSection() {
    final maxConsultations =
        ConsultationLimitService.getDefaultLimit(_badgeLevelString());
    final remaining = (maxConsultations - consultationsThisMonth)
        .clamp(0, maxConsultations);
    final usagePercent = maxConsultations > 0
        ? (consultationsThisMonth / maxConsultations).clamp(0.0, 1.0)
        : 0.0;
    final isAtLimit = remaining == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBEEF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consultas este mês',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                '$consultationsThisMonth / $maxConsultations',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isAtLimit
                      ? const Color(0xFFE53935)
                      : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Barra de progresso
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E8ED),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: usagePercent,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isAtLimit
                        ? const Color(0xFFE53935)
                        : planLevel.progressColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAtLimit
                ? 'Limite atingido este mês'
                : '$remaining restante${remaining != 1 ? 's' : ''} este mês',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isAtLimit
                  ? const Color(0xFFE53935)
                  : AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Seção 3: Progresso para o próximo nível ──

  bool _showProgressSection() {
    return planLevel != PlanLevel.diamond &&
        planLevel != PlanLevel.none &&
        !planLevel.isNegativeState;
  }

  Widget _buildProgressSection() {
    final requirements = _getNextLevelRequirements();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progresso para ${planLevel.nextLevel}',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...requirements.map((req) => _buildRequirementRow(req)),
        const SizedBox(height: 12),
        // Barra de progresso geral
        Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4E8ED),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: planLevel.progressColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirementRow(_Requirement req) {
    final isMet = req.current >= req.target;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isMet
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                  : const Color(0xFFE4E8ED),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Icon(
                isMet ? Icons.check : Icons.lock_outline,
                size: 14,
                color:
                    isMet ? const Color(0xFF4CAF50) : const Color(0xFF9CA3AF),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              req.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isMet
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor.withValues(alpha: 0.6),
              ),
            ),
          ),
          Text(
            '${req.current}/${req.target}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isMet
                  ? const Color(0xFF4CAF50)
                  : AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Seção 4: Benefícios do próximo nível ──

  Widget _buildNextLevelBenefits() {
    final nextLevel = planLevel.nextLevel;
    if (nextLevel.isEmpty) return const SizedBox.shrink();

    final nextBadgeString = _nextBadgeLevelString();
    final nextDiscount = DiscountService.getDefaultDiscount(nextBadgeString);
    final nextConsultations =
        ConsultationLimitService.getDefaultLimit(nextBadgeString);
    final currentDiscount = DiscountService.getDefaultDiscount(_badgeLevelString());
    final currentConsultations =
        ConsultationLimitService.getDefaultLimit(_badgeLevelString());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            planLevel.progressColor.withValues(alpha: 0.06),
            planLevel.progressColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: planLevel.progressColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ao atingir $nextLevel você ganha:',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildBenefitComparison(
            Icons.calendar_month_outlined,
            '$nextConsultations consultas/mês',
            'atual: $currentConsultations',
          ),
          const SizedBox(height: 8),
          _buildBenefitComparison(
            Icons.percent,
            '${nextDiscount.toStringAsFixed(0)}% de desconto',
            'atual: ${currentDiscount.toStringAsFixed(0)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitComparison(
      IconData icon, String benefit, String current) {
    return Row(
      children: [
        Icon(icon, size: 18, color: planLevel.progressColor),
        const SizedBox(width: 10),
        Text(
          benefit,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($current)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  // ── Seção 5: CTA ──

  Widget _buildCTA(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          onViewPlans?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          'Ver Planos',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Helpers ──

  String _badgeLevelString() {
    switch (planLevel) {
      case PlanLevel.bronze:
        return 'bronze';
      case PlanLevel.silver:
        return 'prata';
      case PlanLevel.gold:
        return 'ouro';
      case PlanLevel.diamond:
        return 'diamante';
      default:
        return 'bronze';
    }
  }

  String _nextBadgeLevelString() {
    switch (planLevel) {
      case PlanLevel.bronze:
        return 'prata';
      case PlanLevel.silver:
        return 'ouro';
      case PlanLevel.gold:
        return 'diamante';
      default:
        return '';
    }
  }

  List<_Requirement> _getNextLevelRequirements() {
    switch (planLevel) {
      case PlanLevel.bronze:
        return [
          _Requirement('Meses de membro', monthsAsMember, 6),
          _Requirement('Consultas realizadas', totalConsultations, 4),
        ];
      case PlanLevel.silver:
        return [
          _Requirement('Meses de membro', monthsAsMember, 12),
          _Requirement('Consultas realizadas', totalConsultations, 6),
        ];
      case PlanLevel.gold:
        return [
          _Requirement('Meses de membro', monthsAsMember, 24),
          _Requirement('Consultas realizadas', totalConsultations, 14),
          _Requirement('Plano anual ativo', hasAnnualPlan ? 1 : 0, 1),
        ];
      default:
        return [];
    }
  }
}

class _Requirement {
  final String label;
  final int current;
  final int target;

  _Requirement(this.label, this.current, this.target);
}
