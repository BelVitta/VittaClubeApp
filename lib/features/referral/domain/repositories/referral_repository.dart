import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/referral_entity.dart';

/// Interface do repositorio de indicacoes.
abstract class ReferralRepository {
  /// Obtém todas as indicacoes de um usuario
  Future<Either<Failure, List<ReferralEntity>>> getReferralsByUser(
      String userId);

  /// Cria uma nova indicacao (gera codigo)
  Future<Either<Failure, ReferralEntity>> createReferral(String userId);

  /// Valida um codigo de indicacao (quando o indicado se cadastra)
  Future<Either<Failure, ReferralEntity>> validateReferralCode(
      String code, String referredUserId);

  /// Reivindica recompensa de uma indicacao
  Future<Either<Failure, ReferralEntity>> claimReward(String referralId);

  /// Obtém o numero de indicacoes feitas no mes atual
  Future<Either<Failure, int>> getReferralCountThisMonth(String userId);

  /// Obtém indicacao por codigo
  Future<Either<Failure, ReferralEntity>> getReferralByCode(String code);
}
