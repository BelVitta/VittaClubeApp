import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../repositories/partner_validation_repository.dart';

class ConfirmPartnerValidationParams {
  final String validationId;
  final double? originalValue;

  const ConfirmPartnerValidationParams({
    required this.validationId,
    this.originalValue,
  });
}

class ConfirmPartnerValidationUseCase {
  final PartnerValidationRepository repository;

  ConfirmPartnerValidationUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(
    ConfirmPartnerValidationParams params,
  ) {
    return repository.confirmValidation(
      validationId: params.validationId,
      originalValue: params.originalValue,
    );
  }
}
