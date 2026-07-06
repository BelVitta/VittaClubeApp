import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/consultation_entity.dart';

abstract class ConsultationRepository {
  /// Consultas do usuário logado (mais recentes primeiro).
  Future<Either<Failure, List<ConsultationEntity>>> getForCurrentUser();

  Future<Either<Failure, ConsultationEntity>> recordConsultation({
    required String userId,
    required String validatedBy,
    required double originalValue,
    required double discountPercentage,
    required double discountAmount,
    required double finalValue,
  });
}
