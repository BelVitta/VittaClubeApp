import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../repositories/consultation_admin_repository.dart';

class DeleteConsultationUseCase {
  final ConsultationAdminRepository repository;

  DeleteConsultationUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) => repository.delete(id);
}
