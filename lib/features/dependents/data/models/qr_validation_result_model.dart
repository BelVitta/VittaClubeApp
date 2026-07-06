import '../../domain/entities/dependent_enums.dart';
import '../../domain/repositories/qr_validation_repository.dart';

class QrValidationResultModel extends QrValidationResult {
  final String? actorUserId;
  final String? establishmentId;
  final String? reason;
  final DateTime validatedAt;

  QrValidationResultModel({
    required super.decision,
    required super.message,
    super.appointmentId,
    super.usageRecordId,
    super.remainingUses,
    super.memberName,
    super.planLevel,
    super.discountPercentage,
    super.subscriptionId,
    this.actorUserId,
    this.establishmentId,
    this.reason,
    DateTime? validatedAt,
  }) : validatedAt = validatedAt ?? DateTime.now();

  factory QrValidationResultModel.fromJson(Map<String, dynamic> json) {
    return QrValidationResultModel(
      decision: _decisionFromDb(json['decision'] as String?),
      message: json['message'] as String? ?? 'Validacao processada.',
      appointmentId: json['appointment_id'] as String?,
      usageRecordId: json['usage_record_id'] as String?,
      remainingUses: json['remaining_uses'] as int?,
      memberName: json['member_name'] as String?,
      planLevel: json['plan_level'] as String?,
      discountPercentage: _doubleFromJson(json['discount_percentage']),
      subscriptionId: json['subscription_id'] as String?,
      actorUserId: json['actor_user_id'] as String?,
      establishmentId: json['establishment_id'] as String?,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toAuditMetadata() {
    return {
      'decision': decision.name,
      'message': message,
      'appointment_id': appointmentId,
      'usage_record_id': usageRecordId,
      'remaining_uses': remainingUses,
      'member_name': memberName,
      'plan_level': planLevel,
      'discount_percentage': discountPercentage,
      'subscription_id': subscriptionId,
      'actor_user_id': actorUserId,
      'establishment_id': establishmentId,
      'reason': reason,
      'validated_at': validatedAt.toIso8601String(),
    };
  }

  static QrValidationDecision _decisionFromDb(String? value) {
    switch (value) {
      case 'approved':
        return QrValidationDecision.approved;
      case 'replay':
        return QrValidationDecision.replay;
      case 'quota_exhausted':
        return QrValidationDecision.quotaExhausted;
      case 'overdue_holder':
        return QrValidationDecision.overdueHolder;
      case 'inactive_dependent':
        return QrValidationDecision.inactiveDependent;
      case 'invalid_token':
        return QrValidationDecision.invalidToken;
      case 'expired_appointment':
        return QrValidationDecision.expiredAppointment;
      default:
        return QrValidationDecision.refused;
    }
  }

  static double? _doubleFromJson(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
