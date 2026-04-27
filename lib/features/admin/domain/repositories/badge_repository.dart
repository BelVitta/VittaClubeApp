import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/badge_entity.dart';

/// Interface do repositório de badges/emblemas.
/// Define o contrato que a camada Data deve implementar.
abstract class BadgeRepository {
  /// Obtém todos os badges
  Future<Either<Failure, List<BadgeEntity>>> getAll();

  /// Cria um novo badge
  Future<Either<Failure, BadgeEntity>> create(BadgeEntity entity);

  /// Atualiza um badge existente
  Future<Either<Failure, BadgeEntity>> update(BadgeEntity entity);

  /// Remove um badge pelo ID
  Future<Either<Failure, void>> delete(String id);
}
