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
  final PixAutomaticSubscriptionStatus pixStatus;
  final PaymentAccessStatus paymentAccessStatus;
  final String? wooviSubscriptionId;
  final String? correlationId;
  final String? paymentLinkUrl;
  final int valueCents;
  final String interval;
  final String journey;
  final String retryPolicy;
  final int? dayGenerateCharge;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? nextBillingDate;
  final DateTime? authorizedAt;
  final DateTime? rejectedAt;
  final DateTime? blockedAt;
  final DateTime? lastReconciledAt;

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
    this.paymentAccessStatus = PaymentAccessStatus.blocked,
    this.wooviSubscriptionId,
    this.correlationId,
    this.paymentLinkUrl,
    this.valueCents = 3490,
    this.interval = 'MONTHLY',
    this.journey = 'PAYMENT_ON_APPROVAL',
    this.retryPolicy = 'THREE_RETRIES_7_DAYS',
    this.dayGenerateCharge,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.nextBillingDate,
    this.authorizedAt,
    this.rejectedAt,
    this.blockedAt,
    this.lastReconciledAt,
  });

  bool get isActive =>
      isCurrent &&
      cancelledAt == null &&
      level != PlanLevel.inadimplente &&
      level != PlanLevel.cancelado &&
      pixStatus != PixAutomaticSubscriptionStatus.blocked &&
      pixStatus != PixAutomaticSubscriptionStatus.rejected &&
      pixStatus != PixAutomaticSubscriptionStatus.expired;

  bool get canAccessBenefits {
    return SubscriptionAccessPolicy(
      status: pixStatus,
      accessStatus: paymentAccessStatus,
      currentPeriodEnd: currentPeriodEnd,
    ).canAccessBenefits;
  }

  bool get canUseQr {
    return SubscriptionAccessPolicy(
      status: pixStatus,
      accessStatus: paymentAccessStatus,
      currentPeriodEnd: currentPeriodEnd,
    ).canUseQr;
  }

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
        wooviSubscriptionId,
        correlationId,
        paymentLinkUrl,
        valueCents,
        interval,
        journey,
        retryPolicy,
        dayGenerateCharge,
        currentPeriodStart,
        currentPeriodEnd,
        nextBillingDate,
        authorizedAt,
        rejectedAt,
        blockedAt,
        lastReconciledAt,
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
