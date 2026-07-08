import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/member_qr_validation_repository.dart';
import '../repositories/qr_validation_repository.dart';

class ValidateMemberQrParams {
  final String userId;
  final String actorUserId;

  const ValidateMemberQrParams({
    required this.userId,
    required this.actorUserId,
  });
}

class ValidateMemberQrUseCase {
  final MemberQrValidationRepository repository;

  const ValidateMemberQrUseCase(this.repository);

  Future<Either<Failure, QrValidationResult>> call(
    ValidateMemberQrParams params,
  ) {
    return repository.validateMemberQr(
      userId: params.userId,
      actorUserId: params.actorUserId,
    );
  }
}
