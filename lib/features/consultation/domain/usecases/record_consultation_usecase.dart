import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/discount_service.dart';
import '../entities/consultation_entity.dart';
import '../repositories/consultation_repository.dart';

class RecordConsultationParams {
  final String userId;
  final String validatedBy;
  final double originalValue;
  final double discountPercentage;

  const RecordConsultationParams({
    required this.userId,
    required this.validatedBy,
    required this.originalValue,
    required this.discountPercentage,
  });
}

class RecordConsultationUseCase {
  final ConsultationRepository repository;

  const RecordConsultationUseCase(this.repository);

  Future<Either<Failure, ConsultationEntity>> call(
    RecordConsultationParams params,
  ) {
    final discountService = DiscountService(
      discountPercentage: params.discountPercentage,
      isEligibleForDiscount: params.discountPercentage > 0,
    );
    final discountAmount =
        discountService.calculateDiscountAmount(params.originalValue);
    final finalValue =
        discountService.calculateDiscountedPrice(params.originalValue);

    return repository.recordConsultation(
      userId: params.userId,
      validatedBy: params.validatedBy,
      originalValue: params.originalValue,
      discountPercentage: params.discountPercentage,
      discountAmount: discountAmount,
      finalValue: finalValue,
    );
  }
}
