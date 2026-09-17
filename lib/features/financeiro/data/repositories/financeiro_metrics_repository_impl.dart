import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/financeiro_dashboard_metrics.dart';
import '../../domain/repositories/financeiro_metrics_repository.dart';
import '../datasources/financeiro_metrics_supabase_datasource.dart';

class FinanceiroMetricsRepositoryImpl implements FinanceiroMetricsRepository {
  final FinanceiroMetricsSupabaseDataSource dataSource;

  FinanceiroMetricsRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, FinanceiroDashboardMetrics>>
      getCurrentMonthMetrics() async {
    try {
      return Right(await dataSource.getCurrentMonthMetrics());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
