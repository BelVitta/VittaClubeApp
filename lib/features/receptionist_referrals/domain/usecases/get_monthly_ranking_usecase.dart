import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/receptionist_ranking_entry_entity.dart';
import '../repositories/receptionist_referrals_repository.dart';

class GetMonthlyRankingUseCase {
  final ReceptionistReferralsRepository repository;
  GetMonthlyRankingUseCase(this.repository);

  Future<Either<Failure, List<ReceptionistRankingEntryEntity>>> call(
    String monthReference,
  ) =>
      repository.getMonthlyRanking(monthReference: monthReference);
}
