import 'package:equatable/equatable.dart';

class PartnerValidationEntity extends Equatable {
  final String id;
  final String partnerId;
  final String userId;
  final String userName;
  final String userBadgeLevel;
  final double discountApplied;
  final String? serviceId;
  final String serviceName;
  final DateTime validatedAt;
  final double? discountPercentage;
  final double? originalValue;
  final double savingsAmount;
  final String? beneficiaryType;
  final String? dependentId;

  const PartnerValidationEntity({
    required this.id,
    required this.partnerId,
    required this.userId,
    required this.userName,
    required this.userBadgeLevel,
    required this.discountApplied,
    this.serviceId,
    required this.serviceName,
    required this.validatedAt,
    this.discountPercentage,
    this.originalValue,
    this.savingsAmount = 0,
    this.beneficiaryType,
    this.dependentId,
  });

  @override
  List<Object?> get props => [
        id,
        partnerId,
        userId,
        userName,
        userBadgeLevel,
        discountApplied,
        serviceId,
        serviceName,
        validatedAt,
        discountPercentage,
        originalValue,
        savingsAmount,
        beneficiaryType,
        dependentId,
      ];
}
