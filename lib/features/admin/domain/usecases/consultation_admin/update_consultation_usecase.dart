import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/consultation_admin_entity.dart';
import '../../repositories/consultation_admin_repository.dart';

class UpdateConsultationUseCase {
  final ConsultationAdminRepository repository;

  UpdateConsultationUseCase(this.repository);

  Future<Either<Failure, ConsultationAdminEntity>> call(
          ConsultationAdminEntity entity) =>
      repository.update(entity);
}
