import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/receptionist_ranking_entry_entity.dart';
import '../entities/receptionist_referral_entity.dart';

/// Interface do repositório de indicações de recepcionistas.
abstract class ReceptionistReferralsRepository {
  /// Ranking agregado do mês informado (formato 'YYYY-MM'), ordenado por
  /// conversões e total gerado.
  Future<Either<Failure, List<ReceptionistRankingEntryEntity>>>
      getMonthlyRanking({required String monthReference});

  /// Lista detalhada de indicações (tela "quem indicou"), com filtros
  /// opcionais resolvidos no servidor. Busca por nome do indicado é feita
  /// client-side sobre o resultado, como o resto do painel admin.
  Future<Either<Failure, List<ReceptionistReferralEntity>>> getReferrals({
    String? monthReference,
    String? receptionistId,
    ReceptionistReferralStatus? status,
  });

  /// Correção manual de atribuição (somente financeiro) - via RPC auditada.
  Future<Either<Failure, void>> correctAttribution({
    required String referralId,
    required String newReceptionistId,
    required String reason,
  });
}
