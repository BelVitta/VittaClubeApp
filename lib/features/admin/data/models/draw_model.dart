import '../../domain/entities/draw_entity.dart';

/// Model de sorteio - DTO para serialização.
class DrawModel extends DrawEntity {
  const DrawModel({
    required super.id,
    required super.name,
    required super.prizeName,
    super.prizeDescription,
    super.prizeImageUrl,
    required super.drawDate,
    super.registrationStartDate,
    super.registrationEndDate,
    required super.status,
    required super.participantCount,
    super.winnerId,
    super.winnerName,
    super.eligiblePlanLevels,
    super.rules,
    super.drawSeedHash,
    super.participantListHash,
    super.executedAt,
    super.winnerIndex,
  });

  factory DrawModel.fromJson(Map<String, dynamic> json) {
    return DrawModel(
      id: json['id'] as String,
      name: json['name'] as String,
      prizeName: json['prizeName'] as String,
      prizeDescription: json['prizeDescription'] as String?,
      prizeImageUrl: json['prizeImageUrl'] as String?,
      drawDate: DateTime.parse(json['drawDate'] as String),
      registrationStartDate: json['registrationStartDate'] != null
          ? DateTime.parse(json['registrationStartDate'] as String)
          : null,
      registrationEndDate: json['registrationEndDate'] != null
          ? DateTime.parse(json['registrationEndDate'] as String)
          : null,
      status: json['status'] as String,
      participantCount: json['participantCount'] as int,
      winnerId: json['winnerId'] as String?,
      winnerName: json['winnerName'] as String?,
      eligiblePlanLevels: json['eligiblePlanLevels'] != null
          ? List<String>.from(json['eligiblePlanLevels'] as List)
          : const [],
      rules: json['rules'] as String?,
      drawSeedHash: json['drawSeedHash'] as String?,
      participantListHash: json['participantListHash'] as String?,
      executedAt: json['executedAt'] != null
          ? DateTime.parse(json['executedAt'] as String)
          : null,
      winnerIndex: json['winnerIndex'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'prizeName': prizeName,
      'prizeDescription': prizeDescription,
      'prizeImageUrl': prizeImageUrl,
      'drawDate': drawDate.toIso8601String(),
      'registrationStartDate': registrationStartDate?.toIso8601String(),
      'registrationEndDate': registrationEndDate?.toIso8601String(),
      'status': status,
      'participantCount': participantCount,
      'winnerId': winnerId,
      'winnerName': winnerName,
      'eligiblePlanLevels': eligiblePlanLevels,
      'rules': rules,
      'drawSeedHash': drawSeedHash,
      'participantListHash': participantListHash,
      'executedAt': executedAt?.toIso8601String(),
      'winnerIndex': winnerIndex,
    };
  }

  factory DrawModel.fromEntity(DrawEntity entity) {
    return DrawModel(
      id: entity.id,
      name: entity.name,
      prizeName: entity.prizeName,
      prizeDescription: entity.prizeDescription,
      prizeImageUrl: entity.prizeImageUrl,
      drawDate: entity.drawDate,
      registrationStartDate: entity.registrationStartDate,
      registrationEndDate: entity.registrationEndDate,
      status: entity.status,
      participantCount: entity.participantCount,
      winnerId: entity.winnerId,
      winnerName: entity.winnerName,
      eligiblePlanLevels: entity.eligiblePlanLevels,
      rules: entity.rules,
      drawSeedHash: entity.drawSeedHash,
      participantListHash: entity.participantListHash,
      executedAt: entity.executedAt,
      winnerIndex: entity.winnerIndex,
    );
  }
}
