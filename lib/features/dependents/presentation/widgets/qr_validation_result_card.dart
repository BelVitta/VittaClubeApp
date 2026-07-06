import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dependent_enums.dart';
import '../../domain/repositories/qr_validation_repository.dart';

class QrValidationResultCard extends StatelessWidget {
  final QrValidationResult result;

  const QrValidationResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final approved = result.decision == QrValidationDecision.approved;
    final color = approved ? AppTheme.successColor : AppTheme.errorColor;

    return Semantics(
      label: approved ? 'QR aprovado' : 'QR recusado',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  approved ? Icons.check_circle_outline : Icons.error_outline,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _titleFor(result.decision),
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(result.message, style: AppTheme.bodyMedium),
            if (result.remainingUses != null) ...[
              const SizedBox(height: 8),
              Text(
                '${result.remainingUses} usos restantes neste ciclo',
                style: AppTheme.labelMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _titleFor(QrValidationDecision decision) {
    switch (decision) {
      case QrValidationDecision.approved:
        return 'Uso aprovado';
      case QrValidationDecision.replay:
        return 'QR ja utilizado';
      case QrValidationDecision.quotaExhausted:
        return 'Cota esgotada';
      case QrValidationDecision.overdueHolder:
        return 'Titular inadimplente';
      case QrValidationDecision.inactiveDependent:
        return 'Dependente inativo';
      case QrValidationDecision.invalidToken:
        return 'QR invalido';
      case QrValidationDecision.expiredAppointment:
        return 'Agendamento expirado';
      case QrValidationDecision.refused:
        return 'Uso recusado';
    }
  }
}
