import 'package:equatable/equatable.dart';

abstract class QrValidationEvent extends Equatable {
  const QrValidationEvent();

  @override
  List<Object?> get props => [];
}

class ValidateQrRequested extends QrValidationEvent {
  final String qrToken;
  final String actorUserId;
  final String? establishmentId;

  const ValidateQrRequested({
    required this.qrToken,
    required this.actorUserId,
    this.establishmentId,
  });

  @override
  List<Object?> get props => [qrToken, actorUserId, establishmentId];
}

class ValidateMemberQrRequested extends QrValidationEvent {
  final String userId;
  final String actorUserId;

  const ValidateMemberQrRequested({
    required this.userId,
    required this.actorUserId,
  });

  @override
  List<Object?> get props => [userId, actorUserId];
}
