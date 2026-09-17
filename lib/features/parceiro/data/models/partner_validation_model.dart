import '../../domain/entities/partner_validation_entity.dart';

class PartnerValidationModel extends PartnerValidationEntity {
  const PartnerValidationModel({
    required super.id,
    required super.partnerId,
    required super.userId,
    required super.userName,
    required super.userBadgeLevel,
    required super.discountApplied,
    super.serviceId,
    required super.serviceName,
    required super.validatedAt,
    super.discountPercentage,
    super.originalValue,
    super.savingsAmount,
    super.beneficiaryType,
    super.dependentId,
  });

  factory PartnerValidationModel.fromJson(Map<String, dynamic> json) {
    return PartnerValidationModel(
      id: json['id'] as String,
      partnerId: (json['partnerId'] ?? json['partner_id']) as String,
      userId: (json['userId'] ?? json['user_id']) as String,
      userName: (json['userName'] ?? json['user_name']) as String,
      userBadgeLevel:
          (json['userBadgeLevel'] ?? json['user_badge_level']) as String? ??
              'bronze',
      discountApplied:
          ((json['discountApplied'] ?? json['discount_applied']) as num?)
                  ?.toDouble() ??
              0,
      serviceId: (json['serviceId'] ?? json['service_id']) as String?,
      serviceName: (json['serviceName'] ?? json['service_name']) as String? ??
          'Carteirinha Vita Clube',
      validatedAt: DateTime.parse(
          (json['validatedAt'] ?? json['validated_at']) as String),
      discountPercentage:
          ((json['discountPercentage'] ?? json['discount_percentage']) as num?)
              ?.toDouble(),
      originalValue: ((json['originalValue'] ?? json['original_value']) as num?)
          ?.toDouble(),
      savingsAmount: ((json['savingsAmount'] ?? json['savings_amount']) as num?)
              ?.toDouble() ??
          0,
      beneficiaryType:
          (json['beneficiaryType'] ?? json['beneficiary_type']) as String?,
      dependentId: (json['dependentId'] ?? json['dependent_id']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partnerId': partnerId,
      'userId': userId,
      'userName': userName,
      'userBadgeLevel': userBadgeLevel,
      'discountApplied': discountApplied,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'validatedAt': validatedAt.toIso8601String(),
    };
  }

  factory PartnerValidationModel.fromEntity(PartnerValidationEntity entity) {
    return PartnerValidationModel(
      id: entity.id,
      partnerId: entity.partnerId,
      userId: entity.userId,
      userName: entity.userName,
      userBadgeLevel: entity.userBadgeLevel,
      discountApplied: entity.discountApplied,
      serviceId: entity.serviceId,
      serviceName: entity.serviceName,
      validatedAt: entity.validatedAt,
    );
  }
}
