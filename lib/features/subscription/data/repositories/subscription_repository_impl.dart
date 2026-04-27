import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_supabase_datasource.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionSupabaseDataSource dataSource;

  SubscriptionRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, SubscriptionEntity?>> getCurrent() async {
    try {
      final result = await dataSource.getCurrent();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Erro ao buscar assinatura: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity>> activate({
    required String planId,
    required String planLevelDb,
  }) async {
    try {
      final result = await dataSource.activate(
        planId: planId,
        planLevelDb: planLevelDb,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Erro ao ativar assinatura: ${e.toString()}'));
    }
  }
}
