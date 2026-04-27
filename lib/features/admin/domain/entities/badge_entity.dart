import 'package:equatable/equatable.dart';

/// Entidade de badge/emblema de nível - objeto de negócio puro.
/// Não possui dependências de Flutter ou packages externos.
class BadgeEntity extends Equatable {
  final String id;
  final String levelName;
  final String displayName;
  final String badgeImageUrl;
  final int progressColor;
  final int progressBgColor;
  final int sortOrder;
  final double discountPercentage;
  final int maxConsultationsPerMonth;

  const BadgeEntity({
    required this.id,
    required this.levelName,
    required this.displayName,
    required this.badgeImageUrl,
    required this.progressColor,
    required this.progressBgColor,
    required this.sortOrder,
    this.discountPercentage = 0,
    this.maxConsultationsPerMonth = 0,
  });

  @override
  List<Object?> get props => [
        id,
        levelName,
        displayName,
        badgeImageUrl,
        progressColor,
        progressBgColor,
        sortOrder,
        discountPercentage,
        maxConsultationsPerMonth,
      ];
}
