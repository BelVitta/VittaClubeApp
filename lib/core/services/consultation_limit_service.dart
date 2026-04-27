/// Servico que verifica limites de consultas por mes baseado no badge do usuario.
///
/// Tabela de limites (spec):
/// - Bronze: 4 consultas/mes
/// - Prata: 8 consultas/mes
/// - Ouro: 12 consultas/mes
/// - Diamante: 20 consultas/mes
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
      return 'Voce tem $remainingConsultations consulta(s) restante(s) este mes.';
    }
    return 'Voce atingiu o limite de $maxConsultationsPerMonth consultas este mes.';
  }

  /// Retorna o limite padrao por nivel de badge
  static int getDefaultLimit(String badgeLevel) {
    switch (badgeLevel.toLowerCase()) {
      case 'bronze':
        return 4;
      case 'silver':
      case 'prata':
        return 8;
      case 'gold':
      case 'ouro':
        return 12;
      case 'diamond':
      case 'diamante':
        return 20;
      default:
        return 0;
    }
  }
}
