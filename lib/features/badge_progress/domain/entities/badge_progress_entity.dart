import 'package:equatable/equatable.dart';

/// Entidade que rastreia o progresso do usuario em direcao ao proximo badge.
class BadgeProgressEntity extends Equatable {
  final String userId;
  final String currentBadgeLevel;
  final int consultationCount;
  final int referralCount;
  final DateTime memberSince;
  final DateTime? planActivationDate;
  final bool hasAnnualPlan;

  const BadgeProgressEntity({
    required this.userId,
    required this.currentBadgeLevel,
    required this.consultationCount,
    required this.referralCount,
    required this.memberSince,
    this.planActivationDate,
    this.hasAnnualPlan = false,
  });

  /// Meses como membro ativo
  int get monthsAsMember {
    return DateTime.now().difference(memberSince).inDays ~/ 30;
  }

  /// Verifica se pode subir para Prata
  /// Requisitos: 6 meses + 4 consultas
  bool get canUpgradeToSilver {
    if (currentBadgeLevel != 'bronze') return false;
    return monthsAsMember >= 6 && consultationCount >= 4;
  }

  /// Verifica se pode subir para Ouro
  /// Requisitos: +6 meses (12 total) + 6 consultas + 2 indicacoes
  bool get canUpgradeToGold {
    if (currentBadgeLevel != 'silver') return false;
    return monthsAsMember >= 12 && consultationCount >= 6 && referralCount >= 2;
  }

  /// Verifica se pode subir para Diamante
  /// Requisitos: +12 meses (24 total) + 14 consultas + 3 indicacoes + plano anual
  bool get canUpgradeToDiamond {
    if (currentBadgeLevel != 'gold') return false;
    return monthsAsMember >= 24 &&
        consultationCount >= 14 &&
        referralCount >= 3 &&
        hasAnnualPlan;
  }

  /// Retorna o proximo nivel possivel, ou null se ja esta no maximo
  String? get nextBadgeLevel {
    switch (currentBadgeLevel) {
      case 'bronze':
        return 'silver';
      case 'silver':
        return 'gold';
      case 'gold':
        return 'diamond';
      default:
        return null;
    }
  }

  /// Verifica se pode fazer upgrade para qualquer nivel
  bool get canUpgrade {
    return canUpgradeToSilver || canUpgradeToGold || canUpgradeToDiamond;
  }

  /// Retorna o progresso percentual para o proximo nivel (0.0 a 1.0)
  double get progressToNextLevel {
    switch (currentBadgeLevel) {
      case 'bronze':
        final monthsProgress = (monthsAsMember / 6).clamp(0.0, 1.0);
        final consultProgress = (consultationCount / 4).clamp(0.0, 1.0);
        return (monthsProgress + consultProgress) / 2;
      case 'silver':
        final monthsProgress = (monthsAsMember / 12).clamp(0.0, 1.0);
        final consultProgress = (consultationCount / 6).clamp(0.0, 1.0);
        final referralProgress = (referralCount / 2).clamp(0.0, 1.0);
        return (monthsProgress + consultProgress + referralProgress) / 3;
      case 'gold':
        final monthsProgress = (monthsAsMember / 24).clamp(0.0, 1.0);
        final consultProgress = (consultationCount / 14).clamp(0.0, 1.0);
        final referralProgress = (referralCount / 3).clamp(0.0, 1.0);
        final planProgress = hasAnnualPlan ? 1.0 : 0.0;
        return (monthsProgress + consultProgress + referralProgress + planProgress) / 4;
      default:
        return 1.0;
    }
  }

  @override
  List<Object?> get props => [
        userId,
        currentBadgeLevel,
        consultationCount,
        referralCount,
        memberSince,
        planActivationDate,
        hasAnnualPlan,
      ];
}
