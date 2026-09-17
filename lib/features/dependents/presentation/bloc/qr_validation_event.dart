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
  /// UUID (QR) ou código curto de 8 dígitos (digitação manual).
  final String identifier;
  final String actorUserId;

  const ValidateMemberQrRequested({
    required this.identifier,
    required this.actorUserId,
  });

  /// Compat com callers que ainda passam `userId`.
  factory ValidateMemberQrRequested.fromUserId({
    required String userId,
    required String actorUserId,
  }) =>
      ValidateMemberQrRequested(identifier: userId, actorUserId: actorUserId);

  @override
  List<Object?> get props => [identifier, actorUserId];
}
