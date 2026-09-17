import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/dependent_enums.dart';

class QrValidationResult {
  final QrValidationDecision decision;
  final String message;
  final String? appointmentId;
  final String? usageRecordId;
  final int? remainingUses;

  /// Nome do beneficiário (titular ou dependente) — o que a recepção confere.
  final String? memberName;

  /// Nome do titular quando o beneficiário é dependente.
  final String? holderName;

  /// `holder` | `dependent` (vindo da RPC de agendamento; null na carteirinha).
  final String? beneficiaryType;

  final String? planLevel;
  final double? discountPercentage;
  final String? subscriptionId;

  /// Id do titular (auth) responsável pela consulta — presente tanto na
  /// validação de QR do titular quanto na de dependente (o dependente em si
  /// não tem conta própria; a consulta é sempre registrada em nome do
  /// titular). Usado por `ConsultationValueSheet` pra saber em que `user_id`
  /// gravar `consultations`.
  final String? holderUserId;
  final String? dependentId;
  final String? cpfMasked;
  final String? discountSource;
  final String? partnerId;

  const QrValidationResult({
    required this.decision,
    required this.message,
    this.appointmentId,
    this.usageRecordId,
    this.remainingUses,
    this.memberName,
    this.holderName,
    this.beneficiaryType,
    this.planLevel,
    this.discountPercentage,
    this.subscriptionId,
    this.holderUserId,
    this.dependentId,
    this.cpfMasked,
    this.discountSource,
    this.partnerId,
  });

  bool get isApproved => decision == QrValidationDecision.approved;

  bool get isDependentBeneficiary => beneficiaryType == 'dependent';
}

abstract class QrValidationRepository {
  Future<Either<Failure, QrValidationResult>> validateQr({
    required String qrToken,
    required String actorUserId,
    String? establishmentId,
  });
}
