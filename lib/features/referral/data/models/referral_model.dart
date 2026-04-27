import '../../domain/entities/referral_entity.dart';

/// Model de indicacao - DTO para serializacao.
class ReferralModel extends ReferralEntity {
  const ReferralModel({
    required super.id,
    required super.referrerId,
    required super.referrerName,
    super.referredId,
    super.referredName,
    required super.referralCode,
    required super.status,
    required super.createdAt,
    super.activatedAt,
    super.rewardClaimedAt,
    super.referredCompletedConsultation,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      id: json['id'] as String,
      referrerId: json['referrerId'] as String,
      referrerName: json['referrerName'] as String,
      referredId: json['referredId'] as String?,
      referredName: json['referredName'] as String?,
      referralCode: json['referralCode'] as String,
      status: ReferralStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReferralStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      activatedAt: json['activatedAt'] != null
          ? DateTime.parse(json['activatedAt'] as String)
          : null,
      rewardClaimedAt: json['rewardClaimedAt'] != null
          ? DateTime.parse(json['rewardClaimedAt'] as String)
          : null,
      referredCompletedConsultation:
          json['referredCompletedConsultation'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referrerId': referrerId,
      'referrerName': referrerName,
      'referredId': referredId,
      'referredName': referredName,
      'referralCode': referralCode,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'activatedAt': activatedAt?.toIso8601String(),
      'rewardClaimedAt': rewardClaimedAt?.toIso8601String(),
      'referredCompletedConsultation': referredCompletedConsultation,
    };
  }

  factory ReferralModel.fromEntity(ReferralEntity entity) {
    return ReferralModel(
      id: entity.id,
      referrerId: entity.referrerId,
      referrerName: entity.referrerName,
      referredId: entity.referredId,
      referredName: entity.referredName,
      referralCode: entity.referralCode,
      status: entity.status,
      createdAt: entity.createdAt,
      activatedAt: entity.activatedAt,
      rewardClaimedAt: entity.rewardClaimedAt,
      referredCompletedConsultation: entity.referredCompletedConsultation,
    );
  }
}
