import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/professional_entity.dart';

abstract class ProfessionalsRepository {
  /// Profissionais ativos, para a listagem pública.
  Future<Either<Failure, List<ProfessionalEntity>>> getActiveProfessionals();
}
