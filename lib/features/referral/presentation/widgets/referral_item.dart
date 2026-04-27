import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/referral_entity.dart';

/// Widget que exibe uma indicacao na lista de historico.
class ReferralItem extends StatelessWidget {
  final ReferralEntity referral;
  final VoidCallback? onClaimReward;

  const ReferralItem({
    super.key,
    required this.referral,
    this.onClaimReward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_statusIcon, color: _statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.referredName ?? 'Aguardando...',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (referral.isEligibleForReward &&
              referral.status == ReferralStatus.active)
            TextButton(
              onPressed: onClaimReward,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.successColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: Text(
                'Resgatar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _badgeText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _statusColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (referral.status) {
      case ReferralStatus.pending:
        return const Color(0xFFE8872B);
      case ReferralStatus.active:
        return const Color(0xFF2196F3);
      case ReferralStatus.rewarded:
        return AppTheme.successColor;
      case ReferralStatus.expired:
        return AppTheme.secondaryText;
    }
  }

  IconData get _statusIcon {
    switch (referral.status) {
      case ReferralStatus.pending:
        return Icons.hourglass_empty;
      case ReferralStatus.active:
        return Icons.person_add;
      case ReferralStatus.rewarded:
        return Icons.card_giftcard;
      case ReferralStatus.expired:
        return Icons.timer_off;
    }
  }

  String get _statusText {
    switch (referral.status) {
      case ReferralStatus.pending:
        return 'Codigo: ${referral.referralCode}';
      case ReferralStatus.active:
        if (referral.referredCompletedConsultation) {
          return 'Indicado realizou consulta';
        }
        return 'Indicado ativo - aguardando consulta';
      case ReferralStatus.rewarded:
        return 'Recompensa resgatada';
      case ReferralStatus.expired:
        return 'Indicacao expirada';
    }
  }

  String get _badgeText {
    switch (referral.status) {
      case ReferralStatus.pending:
        return 'Pendente';
      case ReferralStatus.active:
        return 'Ativo';
      case ReferralStatus.rewarded:
        return 'Resgatado';
      case ReferralStatus.expired:
        return 'Expirado';
    }
  }
}
