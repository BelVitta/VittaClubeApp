import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/subscription_status.dart';

class SubscriptionModel extends SubscriptionEntity {
  const SubscriptionModel({
    required super.id,
    required super.userId,
    required super.planId,
    required super.level,
    required super.activationDate,
    super.expirationDate,
    required super.isCurrent,
    super.cancelledAt,
    super.pixStatus,
    super.paymentAccessStatus,
    super.wooviSubscriptionId,
    super.correlationId,
    super.paymentLinkUrl,
    super.valueCents,
    super.interval,
    super.journey,
    super.retryPolicy,
    super.dayGenerateCharge,
    super.currentPeriodStart,
    super.currentPeriodEnd,
    super.nextBillingDate,
    super.authorizedAt,
    super.rejectedAt,
    super.blockedAt,
    super.lastReconciledAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      planId: json['plan_id'] as String,
      level: planLevelFromDb(json['plan_level_status'] as String? ?? 'none'),
      activationDate: _date(json['activation_date']) ?? DateTime.now(),
      expirationDate: _date(json['expiration_date']),
      isCurrent: json['is_current'] as bool? ?? true,
      cancelledAt: _date(json['cancelled_at']),
      pixStatus:
          pixAutomaticSubscriptionStatusFromDb(json['status'] as String?),
      paymentAccessStatus:
          paymentAccessStatusFromDb(json['payment_access_status'] as String?),
      wooviSubscriptionId: json['woovi_subscription_id'] as String?,
      correlationId: json['correlation_id'] as String?,
      paymentLinkUrl: json['payment_link_url'] as String?,
      valueCents: json['value_cents'] as int? ?? 3490,
      interval: json['interval'] as String? ?? 'MONTHLY',
      journey: json['journey'] as String? ?? 'PAYMENT_ON_APPROVAL',
      retryPolicy: json['retry_policy'] as String? ?? 'THREE_RETRIES_7_DAYS',
      dayGenerateCharge: json['day_generate_charge'] as int?,
      currentPeriodStart: _date(json['current_period_start']),
      currentPeriodEnd: _date(json['current_period_end']),
      nextBillingDate: _date(json['next_billing_date']),
      authorizedAt: _date(json['authorized_at']),
      rejectedAt: _date(json['rejected_at']),
      blockedAt: _date(json['blocked_at']),
      lastReconciledAt: _date(json['last_reconciled_at']),
    );
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.parse(value as String);
  }
}
