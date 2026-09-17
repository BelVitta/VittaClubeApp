import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/receptionist_referrals_repository.dart';

class CorrectReferralAttributionUseCase {
  final ReceptionistReferralsRepository repository;
  CorrectReferralAttributionUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String referralId,
    required String newReceptionistId,
    required String reason,
  }) =>
      repository.correctAttribution(
        referralId: referralId,
        newReceptionistId: newReceptionistId,
        reason: reason,
      );
}
