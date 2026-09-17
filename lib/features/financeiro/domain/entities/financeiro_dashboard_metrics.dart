import 'package:equatable/equatable.dart';

/// Totais do mês corrente, calculados no banco — nunca números de vitrine.
class FinanceiroDashboardMetrics extends Equatable {
  final double monthRevenue;
  final int activeMembers;
  final int overdueMembers;
  final int monthCancellations;

  const FinanceiroDashboardMetrics({
    required this.monthRevenue,
    required this.activeMembers,
    required this.overdueMembers,
    required this.monthCancellations,
  });

  @override
  List<Object?> get props => [
        monthRevenue,
        activeMembers,
        overdueMembers,
        monthCancellations,
      ];
}
