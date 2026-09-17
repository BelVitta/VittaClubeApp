import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/financeiro_dashboard_metrics.dart';

abstract class FinanceiroMetricsRepository {
  Future<Either<Failure, FinanceiroDashboardMetrics>> getCurrentMonthMetrics();
}
