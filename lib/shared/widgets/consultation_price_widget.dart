import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/discount_service.dart';
import '../../core/theme/app_theme.dart';

/// Widget que exibe o preco de uma consulta com desconto aplicado por badge.
class ConsultationPriceWidget extends StatelessWidget {
  final double originalPrice;
  final String badgeLevel;
  final bool isEligibleForDiscount;

  const ConsultationPriceWidget({
    super.key,
    required this.originalPrice,
    required this.badgeLevel,
    this.isEligibleForDiscount = true,
  });

  @override
  Widget build(BuildContext context) {
    final discountPercentage = DiscountService.getDefaultDiscount(badgeLevel);
    final discount = DiscountService(
      discountPercentage: discountPercentage,
      isEligibleForDiscount: isEligibleForDiscount,
    );
    final finalPrice = discount.calculateDiscountedPrice(originalPrice);
    final hasDiscount = isEligibleForDiscount && discountPercentage > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (hasDiscount) ...[
          Text(
            DiscountService.formatPrice(originalPrice),
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.secondaryText,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '-${discount.formattedDiscount}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                DiscountService.formatPrice(finalPrice),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryText,
                ),
              ),
            ],
          ),
        ] else ...[
          Text(
            DiscountService.formatPrice(originalPrice),
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryText,
            ),
          ),
        ],
      ],
    );
  }
}
