import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/member_qr_validation_repository.dart';
import '../repositories/qr_validation_repository.dart';

class ValidateMemberQrParams {
  /// UUID (QR da carteirinha) ou código curto de 8 dígitos.
  final String identifier;
  final String actorUserId;

  const ValidateMemberQrParams({
    required this.identifier,
    required this.actorUserId,
  });

  /// Compat: callers antigos usavam `userId`.
  factory ValidateMemberQrParams.fromUserId({
    required String userId,
    required String actorUserId,
  }) =>
      ValidateMemberQrParams(identifier: userId, actorUserId: actorUserId);
}

class ValidateMemberQrUseCase {
  final MemberQrValidationRepository repository;

  const ValidateMemberQrUseCase(this.repository);

  Future<Either<Failure, QrValidationResult>> call(
    ValidateMemberQrParams params,
  ) {
    return repository.validateMemberQr(
      identifier: params.identifier,
      actorUserId: params.actorUserId,
    );
  }
}
