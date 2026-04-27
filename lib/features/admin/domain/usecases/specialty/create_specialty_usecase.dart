import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/specialty_entity.dart';
import '../../repositories/specialty_repository.dart';

class CreateSpecialtyUseCase {
  final SpecialtyRepository repository;

  CreateSpecialtyUseCase(this.repository);

  Future<Either<Failure, SpecialtyEntity>> call(SpecialtyEntity entity) =>
      repository.create(entity);
}
