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
  final int paidMonths;
  final Map<String, int> requiredMonthsByLevel;

  const BadgeProgressEntity({
    required this.userId,
    required this.currentBadgeLevel,
    required this.consultationCount,
    required this.referralCount,
    required this.memberSince,
    this.planActivationDate,
    this.hasAnnualPlan = false,
    this.paidMonths = 0,
    this.requiredMonthsByLevel = const {},
  });

  /// Meses pagos acumulados. A evolução não usa o tempo desde o cadastro.
  int get monthsAsMember => paidMonths;

  /// A evolução oficial é baseada apenas nas mensalidades aprovadas.
  bool get canUpgradeToSilver {
    if (currentBadgeLevel != 'bronze') return false;
    final target = requiredMonthsByLevel['prata'] ?? 0;
    return target > 0 && monthsAsMember >= target;
  }

  bool get canUpgradeToGold {
    if (currentBadgeLevel != 'silver' && currentBadgeLevel != 'prata') {
      return false;
    }
    final target = requiredMonthsByLevel['ouro'] ?? 0;
    return target > 0 && monthsAsMember >= target;
  }

  bool get canUpgradeToDiamond {
    if (currentBadgeLevel != 'gold' && currentBadgeLevel != 'ouro') {
      return false;
    }
    final target = requiredMonthsByLevel['diamante'] ?? 0;
    return target > 0 && monthsAsMember >= target;
  }

  /// Retorna o proximo nivel possivel, ou null se ja esta no maximo
  String? get nextBadgeLevel {
    switch (currentBadgeLevel) {
      case 'bronze':
        return 'prata';
      case 'prata':
      case 'silver':
        return 'ouro';
      case 'ouro':
      case 'gold':
        return 'diamante';
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
        return _progressFor('prata');
      case 'silver':
      case 'prata':
        return _progressFor('ouro');
      case 'gold':
      case 'ouro':
        return _progressFor('diamante');
      default:
        return 1.0;
    }
  }

  double _progressFor(String level) {
    final target = requiredMonthsByLevel[level] ?? 0;
    if (target == 0) return 0;
    return (monthsAsMember / target).clamp(0.0, 1.0);
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
        paidMonths,
        requiredMonthsByLevel,
      ];
}
