import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../repositories/specialty_repository.dart';

class DeleteSpecialtyUseCase {
  final SpecialtyRepository repository;

  DeleteSpecialtyUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) => repository.delete(id);
}
