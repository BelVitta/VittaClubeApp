import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/referral_entity.dart';
import '../repositories/referral_repository.dart';

class ValidateReferralUseCase {
  final ReferralRepository repository;
  ValidateReferralUseCase(this.repository);

  Future<Either<Failure, ReferralEntity>> call(
          String code, String referredUserId) =>
      repository.validateReferralCode(code, referredUserId);
}
