/// Servico de carencia de 7 dias apos ativacao do plano.
///
/// Spec: carencia de 7 dias apos ativacao - durante esse periodo
/// o usuario nao pode agendar consultas nem usar descontos.
class GracePeriodService {
  static const int gracePeriodDays = 7;

  final DateTime? activationDate;

  const GracePeriodService({this.activationDate});

  /// Verifica se o usuario esta em periodo de carencia
  bool get isInGracePeriod {
    if (activationDate == null) return false;
    final daysSinceActivation =
        DateTime.now().difference(activationDate!).inDays;
    return daysSinceActivation < gracePeriodDays;
  }

  /// Dias restantes de carencia
  int get remainingGraceDays {
    if (activationDate == null) return 0;
    final daysSinceActivation =
        DateTime.now().difference(activationDate!).inDays;
    final remaining = gracePeriodDays - daysSinceActivation;
    return remaining > 0 ? remaining : 0;
  }

  /// Data em que a carencia termina
  DateTime? get gracePeriodEndDate {
    if (activationDate == null) return null;
    return activationDate!.add(const Duration(days: gracePeriodDays));
  }

  /// Mensagem sobre periodo de carencia
  String get gracePeriodMessage {
    if (!isInGracePeriod) return '';
    return 'Seu plano esta em carencia. Faltam $remainingGraceDays dia(s) para liberar todos os beneficios.';
  }
}
