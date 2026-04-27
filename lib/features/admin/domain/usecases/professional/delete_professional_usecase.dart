import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../repositories/professional_repository.dart';

class DeleteProfessionalUseCase {
  final ProfessionalRepository repository;

  DeleteProfessionalUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) => repository.delete(id);
}
