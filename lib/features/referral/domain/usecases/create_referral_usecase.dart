import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/referral_entity.dart';
import '../repositories/referral_repository.dart';

class CreateReferralUseCase {
  final ReferralRepository repository;
  CreateReferralUseCase(this.repository);

  /// Cria uma nova indicacao, respeitando o limite de 10/mes por CPF.
  Future<Either<Failure, ReferralEntity>> call(String userId) async {
    final countResult = await repository.getReferralCountThisMonth(userId);
    return countResult.fold(
      (failure) => Left(failure),
      (count) async {
        if (count >= 10) {
          return const Left(
            ValidationFailure('Limite de 10 indicacoes por mes atingido.'),
          );
        }
        return repository.createReferral(userId);
      },
    );
  }
}
