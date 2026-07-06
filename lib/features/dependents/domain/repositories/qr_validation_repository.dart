import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/dependent_enums.dart';

class QrValidationResult {
  final QrValidationDecision decision;
  final String message;
  final String? appointmentId;
  final String? usageRecordId;
  final int? remainingUses;
  final String? memberName;
  final String? planLevel;
  final double? discountPercentage;
  final String? subscriptionId;

  const QrValidationResult({
    required this.decision,
    required this.message,
    this.appointmentId,
    this.usageRecordId,
    this.remainingUses,
    this.memberName,
    this.planLevel,
    this.discountPercentage,
    this.subscriptionId,
  });

  bool get isApproved => decision == QrValidationDecision.approved;
}

abstract class QrValidationRepository {
  Future<Either<Failure, QrValidationResult>> validateQr({
    required String qrToken,
    required String actorUserId,
    String? establishmentId,
  });
}
