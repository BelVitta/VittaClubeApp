import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget que exibe um benefício do plano com checkmark
class PlanBenefitItem extends StatelessWidget {
  final String title;
  final String description;
  final IconData? checkIcon;

  const PlanBenefitItem({
    super.key,
    required this.title,
    required this.description,
    this.checkIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkmark icon
          Icon(
            checkIcon ?? Icons.check,
            size: 16,
            color: const Color(0xFF2C4156),
          ),
          const SizedBox(width: 8),
          // Title and description
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
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6D7F95),
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
