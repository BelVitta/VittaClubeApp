import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import 'qr_validation_repository.dart';

abstract class MemberQrValidationRepository {
  Future<Either<Failure, QrValidationResult>> validateMemberQr({
    required String userId,
    required String actorUserId,
  });
}
