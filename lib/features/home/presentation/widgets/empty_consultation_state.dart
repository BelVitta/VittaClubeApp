import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget que exibe o estado vazio para o histórico de consultas
class EmptyConsultationState extends StatelessWidget {
  final IconData icon;

  const EmptyConsultationState({
    super.key,
    this.icon = Icons.calendar_today_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Illustration placeholder
        Container(
          width: 157,
          height: 157,
          decoration: BoxDecoration(
            color: AppTheme.gradientLight.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            size: 64,
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 16),
        // Title
        Text(
          'Sem Consultas',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF031535),
            letterSpacing: 0.12,
          ),
        ),
        const SizedBox(height: 9),
        // Description
        Text(
          'Sem consultas no momento. Agende uma para começar seu acompanhamento.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D7F95),
            letterSpacing: 0.07,
            height: 1.07,
          ),
        ),
      ],
    );
  }
}
