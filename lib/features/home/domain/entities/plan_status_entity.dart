import 'package:equatable/equatable.dart';

/// Entidade que representa o status do plano do usuário
class PlanStatusEntity extends Equatable {
  final String currentPlan;
  final String nextPlan;
  final double progress; // 0.0 a 1.0

  const PlanStatusEntity({
    required this.currentPlan,
    required this.nextPlan,
    required this.progress,
  });

  bool get hasNoPlan => currentPlan.toLowerCase() == 'sem plano';

  @override
  List<Object?> get props => [currentPlan, nextPlan, progress];
}
