import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/badge_progress_entity.dart';

/// Interface do repositorio de progresso de badges.
abstract class BadgeProgressRepository {
  /// Obtém o progresso do badge de um usuario
  Future<Either<Failure, BadgeProgressEntity>> getProgress(String userId);

  /// Verifica e executa upgrade de badge se elegivel
  Future<Either<Failure, BadgeProgressEntity>> checkAndUpgrade(String userId);

  /// Atualiza o progresso (ex: apos consulta ou indicacao)
  Future<Either<Failure, BadgeProgressEntity>> updateProgress(
      BadgeProgressEntity progress);
}
