import 'package:flutter/material.dart';

/// Enum que representa os níveis de plano disponíveis
enum PlanLevel {
  /// Sem assinatura: badge sem cor (cinza neutro).
  none('Sem plano', 'Bronze', Color(0xFFB0B8C1), Color(0xFFEBEEF2)),

  /// Patentes ativas — cada uma com a cor da patente.
  bronze('Bronze', 'Prata', Color(0xFFC25C3C), Color(0xFFCFDAED)),
  silver('Prata', 'Ouro', Color(0xFFC0C0C0), Color(0xFFE8E8E8)),
  gold('Ouro', 'Diamante', Color(0xFFFFD700), Color(0xFFFFF4D1)),
  diamond('Diamante', 'Diamante', Color(0xFF4FC3F7), Color(0xFFE3F8FF)),
  inadimplente('Pendente', '', Color(0xFFE8872B), Color(0xFFFDE4CC)),
  cancelado('Cancelado', '', Color(0xFF6D7F95), Color(0xFFE0E3E7));

  final String displayName;
  final String nextLevel;
  final Color progressColor;
  final Color progressBackgroundColor;

  const PlanLevel(
    this.displayName,
    this.nextLevel,
    this.progressColor,
    this.progressBackgroundColor,
  );

  /// Retorna o ícone correspondente ao nível
  IconData getBadgeIcon() {
    switch (this) {
      case PlanLevel.none:
        return Icons.shield_outlined;
      case PlanLevel.bronze:
        return Icons.shield;
      case PlanLevel.silver:
        return Icons.shield;
      case PlanLevel.gold:
        return Icons.shield;
      case PlanLevel.diamond:
        return Icons.diamond_outlined;
      case PlanLevel.inadimplente:
        return Icons.warning_amber_outlined;
      case PlanLevel.cancelado:
        return Icons.cancel_outlined;
    }
  }

  /// Retorna o status text baseado no nível
  String getStatusText() {
    switch (this) {
      case PlanLevel.none:
        return 'Sem plano ativo';
      case PlanLevel.inadimplente:
        return 'Inadimplente';
      case PlanLevel.cancelado:
        return 'Cancelado';
      default:
        return 'Patente ativa';
    }
  }

  /// Verifica se é um estado de problema (inadimplente ou cancelado)
  bool get isNegativeState =>
      this == PlanLevel.inadimplente || this == PlanLevel.cancelado;

  /// Sem assinatura — badge visualmente “sem cor”.
  bool get isColorless => this == PlanLevel.none;
}
