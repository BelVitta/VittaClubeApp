import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/badge_entity.dart';
import '../../repositories/badge_repository.dart';

class GetBadgesUseCase {
  final BadgeRepository repository;
  GetBadgesUseCase(this.repository);
  Future<Either<Failure, List<BadgeEntity>>> call() => repository.getAll();
}
