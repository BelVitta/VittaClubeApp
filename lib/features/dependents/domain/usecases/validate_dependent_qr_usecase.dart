import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/qr_validation_repository.dart';

class ValidateDependentQrParams {
  final String qrToken;
  final String actorUserId;
  final String? establishmentId;

  const ValidateDependentQrParams({
    required this.qrToken,
    required this.actorUserId,
    this.establishmentId,
  });
}

class ValidateDependentQrUseCase {
  final QrValidationRepository repository;

  const ValidateDependentQrUseCase(this.repository);

  Future<Either<Failure, QrValidationResult>> call(
    ValidateDependentQrParams params,
  ) {
    return repository.validateQr(
      qrToken: params.qrToken,
      actorUserId: params.actorUserId,
      establishmentId: params.establishmentId,
    );
  }
}
