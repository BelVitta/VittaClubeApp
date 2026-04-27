import 'package:equatable/equatable.dart';

abstract class PartnerCheckinEvent extends Equatable {
  const PartnerCheckinEvent();

  @override
  List<Object?> get props => [];
}

class GenerateCheckinToken extends PartnerCheckinEvent {
  final String userId;

  const GenerateCheckinToken(this.userId);

  @override
  List<Object?> get props => [userId];
}

class SubmitPartnerCode extends PartnerCheckinEvent {
  final String userId;
  final String token;
  final String partnerCode;
  final String serviceId;

  const SubmitPartnerCode({
    required this.userId,
    required this.token,
    required this.partnerCode,
    required this.serviceId,
  });

  @override
  List<Object?> get props => [userId, token, partnerCode, serviceId];
}
