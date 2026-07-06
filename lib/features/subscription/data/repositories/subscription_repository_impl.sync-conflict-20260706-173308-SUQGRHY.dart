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

  @override
  Future<Either<Failure, SubscriptionEntity>> createPixAutomaticSubscription({
    required String planId,
    required PixAutomaticCustomer customer,
  }) async {
    try {
      final result = await dataSource.createPixAutomaticSubscription(
        planId: planId,
        customer: customer,
      );
      return Right(result);
    } catch (e) {
      return Left(
        ServerFailure(
            'Erro ao criar assinatura Pix Automático: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, PixAutomaticBillingProfile?>>
      getBillingProfile() async {
    try {
      final result = await dataSource.getBillingProfile();
      return Right(result);
    } catch (e) {
      return Left(
        ServerFailure('Erro ao buscar dados de cobrança: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, PixAutomaticBillingProfile>> saveBillingProfile(
    PixAutomaticBillingProfile profile,
  ) async {
    try {
      final result = await dataSource.saveBillingProfile(profile);
      return Right(result);
    } catch (e) {
      return Left(
        ServerFailure('Erro ao salvar dados de cobrança: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity?>>
      refreshSubscriptionStatus() async {
    try {
      final result = await dataSource.refreshSubscriptionStatus();
      return Right(result);
    } catch (e) {
      return Left(
        ServerFailure('Erro ao atualizar assinatura: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> cancelSubscription({
    required String subscriptionId,
    String? reason,
  }) async {
    try {
      await dataSource.cancelSubscription(
        subscriptionId: subscriptionId,
        reason: reason,
      );
      return const Right(null);
    } catch (e) {
      return Left(
        ServerFailure('Erro ao cancelar assinatura: ${e.toString()}'),
      );
    }
  }
}
