import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/receptionist_referral_entity.dart';
import '../repositories/receptionist_referrals_repository.dart';

class GetReceptionistReferralsUseCase {
  final ReceptionistReferralsRepository repository;
  GetReceptionistReferralsUseCase(this.repository);

  Future<Either<Failure, List<ReceptionistReferralEntity>>> call({
    String? monthReference,
    String? receptionistId,
    ReceptionistReferralStatus? status,
  }) =>
      repository.getReferrals(
        monthReference: monthReference,
        receptionistId: receptionistId,
        status: status,
      );
}
