import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dependent_enums.dart';
import '../../domain/repositories/qr_validation_repository.dart';

/// Card de resultado da validação de QR para a recepção.
///
/// Exibe decisão + identidade do beneficiário (nome, vínculo, patente, % e
/// usos) para a conferência humana antes de registrar o valor da consulta.
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
            if (_hasIdentity) ...[
              const SizedBox(height: 14),
              Text(
                result.memberName!.trim(),
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 22,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _beneficiaryLabel,
                style: AppTheme.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (result.isDependentBeneficiary &&
                  (result.holderName?.trim().isNotEmpty ?? false)) ...[
                const SizedBox(height: 2),
                Text(
                  'Dependente de ${result.holderName!.trim()}',
                  style: AppTheme.labelMedium,
                ),
              ],
            ],
            const SizedBox(height: 10),
            Text(result.message, style: AppTheme.bodyMedium),
            if (_hasBenefitRows) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (result.planLevel != null &&
                      result.planLevel!.trim().isNotEmpty)
                    _InfoChip(
                      icon: Icons.workspace_premium_outlined,
                      label: _formatPlanLevel(result.planLevel!),
                    ),
                  if (result.discountPercentage != null)
                    _InfoChip(
                      icon: Icons.percent,
                      label:
                          '${result.discountPercentage!.toStringAsFixed(0)}% desconto',
                    ),
                  if (result.remainingUses != null)
                    _InfoChip(
                      icon: Icons.confirmation_number_outlined,
                      label: result.remainingUses == 1
                          ? '1 uso restante'
                          : '${result.remainingUses} usos restantes',
                    ),
                ],
              ),
            ] else if (result.remainingUses != null) ...[
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

  bool get _hasIdentity =>
      result.memberName != null && result.memberName!.trim().isNotEmpty;

  bool get _hasBenefitRows =>
      (result.planLevel != null && result.planLevel!.trim().isNotEmpty) ||
      result.discountPercentage != null ||
      result.remainingUses != null;

  String get _beneficiaryLabel {
    if (result.isDependentBeneficiary) return 'Beneficiário: dependente';
    if (result.beneficiaryType == 'holder') return 'Beneficiário: titular';
    // Carteirinha do membro (sem beneficiary_type na RPC).
    return 'Titular da carteirinha';
  }

  String _formatPlanLevel(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

  String _titleFor(QrValidationDecision decision) {
    switch (decision) {
      case QrValidationDecision.approved:
        return 'Uso aprovado';
      case QrValidationDecision.replay:
        return 'QR já utilizado';
      case QrValidationDecision.quotaExhausted:
        return 'Cota esgotada';
      case QrValidationDecision.overdueHolder:
        return 'Titular inadimplente';
      case QrValidationDecision.inactiveDependent:
        return 'Dependente inativo';
      case QrValidationDecision.invalidToken:
        return 'QR inválido';
      case QrValidationDecision.expiredAppointment:
        return 'Agendamento expirado';
      case QrValidationDecision.rateLimited:
        return 'Muitas tentativas';
      case QrValidationDecision.refused:
        return 'Uso recusado';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.labelMedium.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
