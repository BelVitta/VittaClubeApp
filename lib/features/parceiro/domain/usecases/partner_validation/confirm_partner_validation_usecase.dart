import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../repositories/partner_validation_repository.dart';

class ConfirmPartnerValidationParams {
  final String holderUserId;
  final String memberName;
  final String? dependentId;
  final double? originalValue;
  final String? planLevel;

  const ConfirmPartnerValidationParams({
    required this.holderUserId,
    required this.memberName,
    this.dependentId,
    this.originalValue,
    this.planLevel,
  });
}

class ConfirmPartnerValidationUseCase {
  final PartnerValidationRepository repository;

  ConfirmPartnerValidationUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(
    ConfirmPartnerValidationParams params,
  ) {
    return repository.confirmValidation(
      holderUserId: params.holderUserId,
      memberName: params.memberName,
      dependentId: params.dependentId,
      originalValue: params.originalValue,
      planLevel: params.planLevel,
    );
  }
}
