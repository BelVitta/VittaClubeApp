import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/pix_automatic_models.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/subscription_status.dart';
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
  Future<Either<Failure, void>> cancelSubscription({
    required String subscriptionId,
    String? reason,
    SubscriptionProvider provider = SubscriptionProvider.manual,
  }) async {
    try {
      await dataSource.cancelSubscription(
        subscriptionId: subscriptionId,
        reason: reason,
        provider: provider,
      );
      return const Right(null);
    } catch (e) {
      return Left(
          ServerFailure('Erro ao cancelar assinatura: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity>> createMercadoPagoSubscription({
    required String planId,
    required String cardTokenId,
  }) async {
    try {
      return Right(await dataSource.createMercadoPagoSubscription(
        planId: planId,
        cardTokenId: cardTokenId,
      ));
    } catch (e) {
      return Left(ServerFailure(
        'Erro ao criar assinatura por cartão: ${e.toString()}',
      ));
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
      return Left(ServerFailure(
          'Erro ao criar assinatura Pix Automático: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity?>> refreshSubscriptionStatus({
    String? subscriptionId,
  }) async {
    try {
      final result = await dataSource.refreshCurrent(
        subscriptionId: subscriptionId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(
          'Erro ao atualizar status da assinatura: ${e.toString()}'));
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
          ServerFailure('Erro ao salvar perfil de cobrança: ${e.toString()}'));
    }
  }
}
