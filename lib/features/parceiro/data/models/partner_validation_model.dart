import '../../domain/entities/partner_validation_entity.dart';

class PartnerValidationModel extends PartnerValidationEntity {
  const PartnerValidationModel({
    required super.id,
    required super.partnerId,
    required super.userId,
    required super.userName,
    required super.userBadgeLevel,
    required super.discountApplied,
    required super.serviceId,
    required super.serviceName,
    required super.validatedAt,
  });

  factory PartnerValidationModel.fromJson(Map<String, dynamic> json) {
    return PartnerValidationModel(
      id: json['id'] as String,
      partnerId: json['partnerId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userBadgeLevel: json['userBadgeLevel'] as String? ?? 'bronze',
      discountApplied: (json['discountApplied'] as num?)?.toDouble() ?? 0,
      serviceId: json['serviceId'] as String,
      serviceName: json['serviceName'] as String,
      validatedAt: DateTime.parse(json['validatedAt'] as String),
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
