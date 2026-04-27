import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/badge_entity.dart';
import '../../repositories/badge_repository.dart';

class CreateBadgeUseCase {
  final BadgeRepository repository;
  CreateBadgeUseCase(this.repository);
  Future<Either<Failure, BadgeEntity>> call(BadgeEntity entity) =>
      repository.create(entity);
}
