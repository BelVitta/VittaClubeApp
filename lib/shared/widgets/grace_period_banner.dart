import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/grace_period_service.dart';
import '../../core/theme/app_theme.dart';

/// Banner que exibe informacao sobre periodo de carencia de 7 dias.
class GracePeriodBanner extends StatelessWidget {
  final DateTime? activationDate;

  const GracePeriodBanner({
    super.key,
    this.activationDate,
  });

  @override
  Widget build(BuildContext context) {
    final service = GracePeriodService(activationDate: activationDate);

    if (!service.isInGracePeriod) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule,
            size: 20,
            color: Color(0xFFE8872B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Periodo de Carencia',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE8872B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${service.remainingGraceDays} dia(s) restante(s) para liberar todos os beneficios.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
