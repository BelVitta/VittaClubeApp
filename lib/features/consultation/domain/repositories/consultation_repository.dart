import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/consultation_entity.dart';

abstract class ConsultationRepository {
  /// Consultas do usuário logado (mais recentes primeiro).
  Future<Either<Failure, List<ConsultationEntity>>> getForCurrentUser();
}
