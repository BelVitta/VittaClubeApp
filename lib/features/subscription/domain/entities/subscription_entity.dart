import 'package:equatable/equatable.dart';

import '../../../home/domain/entities/plan_level.dart';
import '../services/subscription_access_policy.dart';
import 'subscription_status.dart';

/// Representa a assinatura atual do usuário logado.
///
/// Se o usuário nunca assinou, o repositório retorna `null` no lugar desta
/// entidade — nenhum estado "none" é armazenado no banco, apenas ausência.
class SubscriptionEntity extends Equatable {
  final String id;
  final String userId;
  final String planId;
  final PlanLevel level;
  final DateTime activationDate;
  final DateTime? expirationDate;
  final bool isCurrent;
  final DateTime? cancelledAt;

  /// Status do Pix Automático. `none` quando não utiliza Pix Automático.
  final PixAutomaticSubscriptionStatus pixStatus;

  /// Status de acesso ao pagamento (controla bloqueio por inadimplência).
  final PaymentAccessStatus paymentAccessStatus;

  /// URL de redirecionamento para o app do banco (Pix Automático).
  final String? paymentLinkUrl;

  /// Data da próxima cobrança (Pix Automático ativo).
  final DateTime? nextBillingDate;

  /// Fim do período pago atual (usado para cancelamentos com período vigente).
  final DateTime? currentPeriodEnd;

  const SubscriptionEntity({
    required this.id,
    required this.userId,
    required this.planId,
    required this.level,
    required this.activationDate,
    this.expirationDate,
    required this.isCurrent,
    this.cancelledAt,
    this.pixStatus = PixAutomaticSubscriptionStatus.none,
    this.paymentAccessStatus = PaymentAccessStatus.allowed,
    this.paymentLinkUrl,
    this.nextBillingDate,
    this.currentPeriodEnd,
  });

  bool get isActive =>
      isCurrent &&
      cancelledAt == null &&
      level != PlanLevel.inadimplente &&
      level != PlanLevel.cancelado;

  bool get canAccessBenefits {
    if (pixStatus == PixAutomaticSubscriptionStatus.none) return isActive;
    return SubscriptionAccessPolicy(
      status: pixStatus,
      accessStatus: paymentAccessStatus,
      currentPeriodEnd: currentPeriodEnd,
    ).canAccessBenefits;
  }

  bool get canUseQr => canAccessBenefits;

  @override
  List<Object?> get props => [
        id,
        userId,
        planId,
        level,
        activationDate,
        expirationDate,
        isCurrent,
        cancelledAt,
        pixStatus,
        paymentAccessStatus,
        paymentLinkUrl,
        nextBillingDate,
        currentPeriodEnd,
      ];
}

/// Converte o enum `plan_level_status` do Supabase (snake_case em pt-br) para o
/// `PlanLevel` usado na UI.
PlanLevel planLevelFromDb(String raw) {
  switch (raw) {
    case 'bronze':
      return PlanLevel.bronze;
    case 'prata':
      return PlanLevel.silver;
    case 'ouro':
      return PlanLevel.gold;
    case 'diamante':
      return PlanLevel.diamond;
    case 'inadimplente':
      return PlanLevel.inadimplente;
    case 'cancelado':
      return PlanLevel.cancelado;
    case 'none':
    default:
      return PlanLevel.none;
  }
}

String planLevelToDb(PlanLevel level) {
  switch (level) {
    case PlanLevel.bronze:
      return 'bronze';
    case PlanLevel.silver:
      return 'prata';
    case PlanLevel.gold:
      return 'ouro';
    case PlanLevel.diamond:
      return 'diamante';
    case PlanLevel.inadimplente:
      return 'inadimplente';
    case PlanLevel.cancelado:
      return 'cancelado';
    case PlanLevel.none:
      return 'none';
  }
}
