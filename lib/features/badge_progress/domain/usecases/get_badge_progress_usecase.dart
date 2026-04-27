import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/badge_progress_entity.dart';
import '../repositories/badge_progress_repository.dart';

class GetBadgeProgressUseCase {
  final BadgeProgressRepository repository;
  GetBadgeProgressUseCase(this.repository);

  Future<Either<Failure, BadgeProgressEntity>> call(String userId) =>
      repository.getProgress(userId);
}
