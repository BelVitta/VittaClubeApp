import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/badge_repository.dart';

class DeleteBadgeUseCase {
  final BadgeRepository repository;
  DeleteBadgeUseCase(this.repository);
  Future<Either<Failure, void>> call(String id) => repository.delete(id);
}
