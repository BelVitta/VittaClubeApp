import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/badge_entity.dart';
import '../../repositories/badge_repository.dart';

class UpdateBadgeUseCase {
  final BadgeRepository repository;
  UpdateBadgeUseCase(this.repository);
  Future<Either<Failure, BadgeEntity>> call(BadgeEntity entity) =>
      repository.update(entity);
}
