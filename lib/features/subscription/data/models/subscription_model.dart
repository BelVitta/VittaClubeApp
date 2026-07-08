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
    super.paymentLinkUrl,
    super.nextBillingDate,
    super.currentPeriodEnd,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      planId: json['plan_id'] as String,
      level: planLevelFromDb(json['plan_level_status'] as String),
      activationDate: DateTime.parse(json['activation_date'] as String),
      expirationDate: json['expiration_date'] == null
          ? null
          : DateTime.parse(json['expiration_date'] as String),
      isCurrent: json['is_current'] as bool,
      cancelledAt: json['cancelled_at'] == null
          ? null
          : DateTime.parse(json['cancelled_at'] as String),
      pixStatus: pixAutomaticSubscriptionStatusFromDb(
        json['pix_status'] as String?,
      ),
      paymentAccessStatus: paymentAccessStatusFromDb(
        json['payment_access_status'] as String?,
      ),
      paymentLinkUrl: json['payment_link_url'] as String?,
      nextBillingDate: json['next_billing_date'] == null
          ? null
          : DateTime.parse(json['next_billing_date'] as String),
      currentPeriodEnd: json['current_period_end'] == null
          ? null
          : DateTime.parse(json['current_period_end'] as String),
    );
  }
}
