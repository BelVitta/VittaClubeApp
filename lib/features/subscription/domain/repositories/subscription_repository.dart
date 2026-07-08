import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/pix_automatic_models.dart';
import '../entities/subscription_entity.dart';

/// Contrato de acesso à assinatura do usuário atual.
abstract class SubscriptionRepository {
  /// Retorna a assinatura ativa do usuário logado.
  /// `Right(null)` significa que o usuário ainda não tem plano — a UI deve
  /// exibir o card de "adquira seu plano".
  Future<Either<Failure, SubscriptionEntity?>> getCurrent();

  /// Cria uma nova assinatura após pagamento aprovado.
  Future<Either<Failure, SubscriptionEntity>> activate({
    required String planId,
    required String planLevelDb,
  });

  /// Cancela a assinatura informada.
  Future<Either<Failure, void>> cancelSubscription({
    required String subscriptionId,
    String? reason,
  });

  /// Cria assinatura via Pix Automático.
  Future<Either<Failure, SubscriptionEntity>> createPixAutomaticSubscription({
    required String planId,
    required PixAutomaticCustomer customer,
  });

  /// Relê o status da assinatura do servidor (sem cache).
  Future<Either<Failure, SubscriptionEntity?>> refreshSubscriptionStatus();

  /// Salva o perfil de cobrança do usuário para Pix Automático.
  Future<Either<Failure, PixAutomaticBillingProfile>> saveBillingProfile(
    PixAutomaticBillingProfile profile,
  );
}
