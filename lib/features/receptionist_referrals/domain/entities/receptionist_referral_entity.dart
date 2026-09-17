import 'package:equatable/equatable.dart';

/// Situação de uma indicação de recepcionista.
enum ReceptionistReferralStatus {
  pending,
  converted,
}

/// Uma indicação feita por uma recepcionista (usuário com role 'admin') -
/// objeto de negócio puro.
class ReceptionistReferralEntity extends Equatable {
  final String id;
  final String receptionistId;
  final String receptionistName;
  final String referralCode;
  final String referredUserId;
  final String referredUserName;
  final String referredUserEmail;
  final DateTime referredMemberSince;
  final ReceptionistReferralStatus status;
  final DateTime? convertedAt;
  final String? planNameAtConversion;
  final double? planPriceAtConversion;
  final String? monthReference;
  final DateTime createdAt;

  const ReceptionistReferralEntity({
    required this.id,
    required this.receptionistId,
    required this.receptionistName,
    required this.referralCode,
    required this.referredUserId,
    required this.referredUserName,
    required this.referredUserEmail,
    required this.referredMemberSince,
    required this.status,
    this.convertedAt,
    this.planNameAtConversion,
    this.planPriceAtConversion,
    this.monthReference,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        receptionistId,
        receptionistName,
        referralCode,
        referredUserId,
        referredUserName,
        referredUserEmail,
        referredMemberSince,
        status,
        convertedAt,
        planNameAtConversion,
        planPriceAtConversion,
        monthReference,
        createdAt,
      ];
}
