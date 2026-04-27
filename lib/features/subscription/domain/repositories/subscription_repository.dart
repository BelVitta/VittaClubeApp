import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
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
}
