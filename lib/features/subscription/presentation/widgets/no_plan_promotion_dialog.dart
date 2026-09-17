import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/secondary_button.dart';

/// Modal promocional exibido na frente do app quando o usuário não tem
/// assinatura. Complementa o [NoPlanCard] permanente no topo da Home.
class NoPlanPromotionDialog extends StatelessWidget {
  final VoidCallback onViewPlans;
  final VoidCallback onDismiss;

  /// Preço formatado do plano mais barato (ex: "R\$ 49,90/mês").
  final String? priceLabel;

  const NoPlanPromotionDialog({
    super.key,
    required this.onViewPlans,
    required this.onDismiss,
    this.priceLabel,
  });

  /// Exibe o dialog com barrier não-dismissível (fecha só por X / "Agora não").
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onViewPlans,
    String? priceLabel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        return NoPlanPromotionDialog(
          priceLabel: priceLabel,
          onViewPlans: () {
            Navigator.of(dialogContext).pop();
            onViewPlans();
          },
          onDismiss: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onDismiss: onDismiss, priceLabel: priceLabel),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ative seu plano Vita',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Desbloqueie descontos em consultas, carteirinha digital e benefícios com parceiros.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _BenefitRow(
                    icon: Icons.medical_services_outlined,
                    text: 'Descontos liberados pelo QR do membro',
                  ),
                  const SizedBox(height: 10),
                  const _BenefitRow(
                    icon: Icons.workspace_premium_outlined,
                    text: 'Benefícios e parceiros em um só lugar',
                  ),
                  const SizedBox(height: 10),
                  const _BenefitRow(
                    icon: Icons.verified_user_outlined,
                    text: 'Carteirinha digital sempre no bolso',
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    text: 'Conhecer planos',
                    onPressed: onViewPlans,
                  ),
                  const SizedBox(height: 8),
                  SecondaryButton(
                    text: 'Agora não',
                    onPressed: onDismiss,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onDismiss;
  final String? priceLabel;

  const _Header({required this.onDismiss, this.priceLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
            AppTheme.gradientLight.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.24),
              ),
            ),
            child: const Icon(
              Icons.local_offer_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Oferta para membros',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  priceLabel ?? 'Planos a partir de um valor mensal',
                  style: GoogleFonts.outfit(
                    fontSize: priceLabel != null ? 22 : 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: onDismiss,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.successColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryText,
            ),
          ),
        ),
      ],
    );
  }
}
