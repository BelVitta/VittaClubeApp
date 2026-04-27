import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/specialty_entity.dart';
import '../../repositories/specialty_repository.dart';

class GetSpecialtiesUseCase {
  final SpecialtyRepository repository;

  GetSpecialtiesUseCase(this.repository);

  Future<Either<Failure, List<SpecialtyEntity>>> call() => repository.getAll();
}
