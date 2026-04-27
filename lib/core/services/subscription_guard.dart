/// Guard/service que verifica o status da assinatura do usuario
/// e controla acesso a funcionalidades baseado em inadimplencia.
///
/// Regras de inadimplencia (spec):
/// - Bloqueado: agendamento, sorteios, descontos
/// - Mantido: historico e carteirinha
class SubscriptionGuard {
  final String userStatus;
  final String? planActivationDate;

  const SubscriptionGuard({
    required this.userStatus,
    this.planActivationDate,
  });

  /// Verifica se o usuario esta inadimplente
  bool get isInadimplente => userStatus == 'inadimplente';

  /// Verifica se o usuario esta cancelado
  bool get isCancelado => userStatus == 'cancelado';

  /// Verifica se o usuario tem status negativo (inadimplente ou cancelado)
  bool get hasNegativeStatus => isInadimplente || isCancelado;

  /// Verifica se o usuario esta ativo
  bool get isActive => userStatus == 'ativo';

  /// Verifica se o usuario ainda esta em periodo de carencia (7 dias)
  bool get isInGracePeriod {
    if (planActivationDate == null) return false;
    final activation = DateTime.tryParse(planActivationDate!);
    if (activation == null) return false;
    final daysSinceActivation = DateTime.now().difference(activation).inDays;
    return daysSinceActivation < 7;
  }

  /// Pode agendar consultas?
  /// Bloqueado para: inadimplentes, cancelados, em carencia
  bool get canScheduleConsultation {
    if (hasNegativeStatus) return false;
    if (isInGracePeriod) return false;
    return true;
  }

  /// Pode participar de sorteios?
  /// Bloqueado para: inadimplentes, cancelados
  bool get canParticipateInDraws {
    return !hasNegativeStatus;
  }

  /// Pode usar descontos do badge?
  /// Bloqueado para: inadimplentes, cancelados
  bool get canUseDiscounts {
    return !hasNegativeStatus;
  }

  /// Pode ver historico?
  /// Mantido para todos
  bool get canViewHistory => true;

  /// Pode ver carteirinha?
  /// Mantido para todos
  bool get canViewCard => true;

  /// Retorna mensagem de bloqueio apropriada
  String getBlockedMessage(String feature) {
    if (isCancelado) {
      return 'Seu plano foi cancelado. Reative para acessar $feature.';
    }
    if (isInadimplente) {
      return 'Regularize seu pagamento para acessar $feature.';
    }
    if (isInGracePeriod) {
      return 'Aguarde o periodo de carencia de 7 dias para acessar $feature.';
    }
    return '';
  }
}
