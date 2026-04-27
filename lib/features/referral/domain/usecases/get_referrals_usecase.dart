import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/referral_entity.dart';
import '../repositories/referral_repository.dart';

class GetReferralsUseCase {
  final ReferralRepository repository;
  GetReferralsUseCase(this.repository);

  Future<Either<Failure, List<ReferralEntity>>> call(String userId) =>
      repository.getReferralsByUser(userId);
}
