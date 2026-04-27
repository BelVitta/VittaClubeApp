import 'package:equatable/equatable.dart';

/// Status de uma indicacao
enum ReferralStatus {
  pending,
  active,
  rewarded,
  expired,
}

/// Entidade de indicacao - objeto de negocio puro.
class ReferralEntity extends Equatable {
  final String id;
  final String referrerId;
  final String referrerName;
  final String? referredId;
  final String? referredName;
  final String referralCode;
  final ReferralStatus status;
  final DateTime createdAt;
  final DateTime? activatedAt;
  final DateTime? rewardClaimedAt;
  final bool referredCompletedConsultation;

  const ReferralEntity({
    required this.id,
    required this.referrerId,
    required this.referrerName,
    this.referredId,
    this.referredName,
    required this.referralCode,
    required this.status,
    required this.createdAt,
    this.activatedAt,
    this.rewardClaimedAt,
    this.referredCompletedConsultation = false,
  });

  /// Verifica se a indicacao esta elegivel para recompensa.
  /// Requisitos: indicado ativo por 60 dias + realizou 1 consulta.
  bool get isEligibleForReward {
    if (status != ReferralStatus.active) return false;
    if (activatedAt == null) return false;
    if (!referredCompletedConsultation) return false;
    final daysSinceActivation = DateTime.now().difference(activatedAt!).inDays;
    return daysSinceActivation >= 60;
  }

  @override
  List<Object?> get props => [
        id,
        referrerId,
        referrerName,
        referredId,
        referredName,
        referralCode,
        status,
        createdAt,
        activatedAt,
        rewardClaimedAt,
        referredCompletedConsultation,
      ];
}
