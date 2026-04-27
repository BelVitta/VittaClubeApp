import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/referral_entity.dart';
import '../repositories/referral_repository.dart';

class ClaimRewardUseCase {
  final ReferralRepository repository;
  ClaimRewardUseCase(this.repository);

  Future<Either<Failure, ReferralEntity>> call(String referralId) =>
      repository.claimReward(referralId);
}
