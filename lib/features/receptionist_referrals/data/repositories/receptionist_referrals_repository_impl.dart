import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/receptionist_ranking_entry_entity.dart';
import '../../domain/entities/receptionist_referral_entity.dart';
import '../../domain/repositories/receptionist_referrals_repository.dart';
import '../datasources/receptionist_referrals_supabase_datasource.dart';

class ReceptionistReferralsRepositoryImpl
    implements ReceptionistReferralsRepository {
  final ReceptionistReferralsSupabaseDataSource dataSource;

  ReceptionistReferralsRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<ReceptionistRankingEntryEntity>>>
      getMonthlyRanking({required String monthReference}) async {
    try {
      final result = await dataSource.getMonthlyRanking(monthReference);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Erro ao buscar ranking: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ReceptionistReferralEntity>>> getReferrals({
    String? monthReference,
    String? receptionistId,
    ReceptionistReferralStatus? status,
  }) async {
    try {
      final result = await dataSource.getReferrals(
        monthReference: monthReference,
        receptionistId: receptionistId,
        status: status,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Erro ao buscar indicações: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> correctAttribution({
    required String referralId,
    required String newReceptionistId,
    required String reason,
  }) async {
    try {
      await dataSource.correctAttribution(
        referralId: referralId,
        newReceptionistId: newReceptionistId,
        reason: reason,
      );
      return const Right(null);
    } catch (e) {
      return Left(ValidationFailure(e.toString()));
    }
  }
}
