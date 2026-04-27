import 'package:flutter/material.dart';

/// Enum que representa os níveis de plano disponíveis
enum PlanLevel {
  none('Sem plano', 'Bronze', Color(0xFFF6F6F6), Color(0xFFF6F6F6)),
  bronze('Bronze', 'Prata', Color(0xFFC25C3C), Color(0xFFCFDAED)),
  silver('Prata', 'Ouro', Color(0xFFC0C0C0), Color(0xFFE8E8E8)),
  gold('Ouro', 'Diamante', Color(0xFFFFD700), Color(0xFFFFF4D1)),
  diamond('Diamante', 'Diamante', Color(0xFFB9F2FF), Color(0xFFE3F8FF)),
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
        return 'Assine Vita Clube';
      case PlanLevel.inadimplente:
        return 'Inadimplente';
      case PlanLevel.cancelado:
        return 'Cancelado';
      default:
        return 'Ativo';
    }
  }

  /// Verifica se é um estado de problema (inadimplente ou cancelado)
  bool get isNegativeState =>
      this == PlanLevel.inadimplente || this == PlanLevel.cancelado;
}
