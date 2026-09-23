import 'badge_catalog_service.dart';

/// Serviço que verifica limites publicados pelo financeiro.
class ConsultationLimitService {
  final String badgeLevel;
  final int consultationsThisMonth;
  final int maxConsultationsPerMonth;

  const ConsultationLimitService({
    required this.badgeLevel,
    required this.consultationsThisMonth,
    required this.maxConsultationsPerMonth,
  });

  /// Numero de consultas restantes no mes
  int get remainingConsultations {
    final remaining = maxConsultationsPerMonth - consultationsThisMonth;
    return remaining > 0 ? remaining : 0;
  }

  /// Verifica se o usuario pode agendar mais consultas neste mes
  bool get canScheduleMore => remainingConsultations > 0;

  /// Percentual de consultas usadas (0.0 a 1.0)
  double get usagePercentage {
    if (maxConsultationsPerMonth == 0) return 0.0;
    return (consultationsThisMonth / maxConsultationsPerMonth).clamp(0.0, 1.0);
  }

  /// Mensagem de limite
  String get limitMessage {
    if (canScheduleMore) {
      return 'Você tem $remainingConsultations consulta(s) restante(s) este mês.';
    }
    return 'Você atingiu o limite de $maxConsultationsPerMonth consultas este mês.';
  }

  /// Retorna o limite configurado no banco para a patente.
  static int getDefaultLimit(String badgeLevel) {
    return BadgeCatalogService.consultationsLimitFor(badgeLevel);
  }
}
