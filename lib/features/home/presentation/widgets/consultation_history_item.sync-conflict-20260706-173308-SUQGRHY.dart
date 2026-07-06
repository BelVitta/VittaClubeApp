import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/discount_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget que representa um item no histórico de consultas
class ConsultationHistoryItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime date;
  final IconData badgeIcon;
  final double? discountAmount;
  final VoidCallback? onTap;

  const ConsultationHistoryItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.badgeIcon,
    this.discountAmount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEBEEF2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  // Badge icon
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4678CF).withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(12.5),
                    ),
                    child: Icon(
                      badgeIcon,
                      size: 13,
                      color: const Color(0xFF4678CF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (discountAmount != null && discountAmount! > 0) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Economizou ${DiscountService.formatPrice(discountAmount!)}',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E7D32),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Date
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
