import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetCurrentProfileUseCase {
  final ProfileRepository repository;

  GetCurrentProfileUseCase(this.repository);

  Future<Either<Failure, ProfileEntity?>> call() => repository.getCurrent();
}
