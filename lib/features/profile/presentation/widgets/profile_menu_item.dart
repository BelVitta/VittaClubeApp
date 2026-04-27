import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Item de menu da página de perfil com chevron à direita
class ProfileMenuItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? borderColor;
  final bool showChevron;

  const ProfileMenuItem({
    super.key,
    required this.title,
    required this.onTap,
    this.textColor,
    this.borderColor,
    this.showChevron = true,
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
            color: borderColor ?? const Color(0xFFEBEEF2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor ?? AppTheme.primaryColor,
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                size: 16,
                color: textColor ?? AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}
