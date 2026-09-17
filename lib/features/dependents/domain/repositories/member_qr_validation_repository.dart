import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import 'qr_validation_repository.dart';

abstract class MemberQrValidationRepository {
  /// [identifier]: UUID (QR) ou código de 8 dígitos (digitação manual).
  Future<Either<Failure, QrValidationResult>> validateMemberQr({
    required String identifier,
    required String actorUserId,
  });
}
