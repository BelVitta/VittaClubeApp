import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/financeiro_dashboard_metrics.dart';
import '../repositories/financeiro_metrics_repository.dart';

class GetFinanceiroDashboardMetricsUseCase {
  final FinanceiroMetricsRepository repository;

  GetFinanceiroDashboardMetricsUseCase(this.repository);

  Future<Either<Failure, FinanceiroDashboardMetrics>> call() =>
      repository.getCurrentMonthMetrics();
}
