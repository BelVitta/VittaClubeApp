import '../../domain/entities/badge_progress_entity.dart';

/// Model de progresso de badge - DTO para serializacao.
class BadgeProgressModel extends BadgeProgressEntity {
  const BadgeProgressModel({
    required super.userId,
    required super.currentBadgeLevel,
    required super.consultationCount,
    required super.referralCount,
    required super.memberSince,
    super.planActivationDate,
    super.hasAnnualPlan,
  });

  factory BadgeProgressModel.fromJson(Map<String, dynamic> json) {
    return BadgeProgressModel(
      userId: json['userId'] as String,
      currentBadgeLevel: json['currentBadgeLevel'] as String,
      consultationCount: json['consultationCount'] as int,
      referralCount: json['referralCount'] as int,
      memberSince: DateTime.parse(json['memberSince'] as String),
      planActivationDate: json['planActivationDate'] != null
          ? DateTime.parse(json['planActivationDate'] as String)
          : null,
      hasAnnualPlan: json['hasAnnualPlan'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'currentBadgeLevel': currentBadgeLevel,
      'consultationCount': consultationCount,
      'referralCount': referralCount,
      'memberSince': memberSince.toIso8601String(),
      'planActivationDate': planActivationDate?.toIso8601String(),
      'hasAnnualPlan': hasAnnualPlan,
    };
  }

  factory BadgeProgressModel.fromEntity(BadgeProgressEntity entity) {
    return BadgeProgressModel(
      userId: entity.userId,
      currentBadgeLevel: entity.currentBadgeLevel,
      consultationCount: entity.consultationCount,
      referralCount: entity.referralCount,
      memberSince: entity.memberSince,
      planActivationDate: entity.planActivationDate,
      hasAnnualPlan: entity.hasAnnualPlan,
    );
  }
}
