import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/consultation_limit_service.dart';
import '../../core/theme/app_theme.dart';

/// Widget que exibe o uso de consultas do mes com barra de progresso.
class ConsultationLimitWidget extends StatelessWidget {
  final String badgeLevel;
  final int consultationsThisMonth;
  final int? maxOverride;

  const ConsultationLimitWidget({
    super.key,
    required this.badgeLevel,
    required this.consultationsThisMonth,
    this.maxOverride,
  });

  @override
  Widget build(BuildContext context) {
    final maxConsultations =
        maxOverride ?? ConsultationLimitService.getDefaultLimit(badgeLevel);
    final service = ConsultationLimitService(
      badgeLevel: badgeLevel,
      consultationsThisMonth: consultationsThisMonth,
      maxConsultationsPerMonth: maxConsultations,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consultas este mes',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryText,
                ),
              ),
              Text(
                '$consultationsThisMonth / $maxConsultations',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: service.canScheduleMore
                      ? AppTheme.primaryColor
                      : AppTheme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: service.usagePercentage,
              backgroundColor: AppTheme.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                service.canScheduleMore
                    ? AppTheme.primaryColor
                    : AppTheme.errorColor,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            service.limitMessage,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
