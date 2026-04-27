import 'package:equatable/equatable.dart';

class PartnerValidationEntity extends Equatable {
  final String id;
  final String partnerId;
  final String userId;
  final String userName;
  final String userBadgeLevel;
  final double discountApplied;
  final String serviceId;
  final String serviceName;
  final DateTime validatedAt;

  const PartnerValidationEntity({
    required this.id,
    required this.partnerId,
    required this.userId,
    required this.userName,
    required this.userBadgeLevel,
    required this.discountApplied,
    required this.serviceId,
    required this.serviceName,
    required this.validatedAt,
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
      ];
}
