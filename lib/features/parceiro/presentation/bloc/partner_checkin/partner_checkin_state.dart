import 'package:equatable/equatable.dart';

import '../../../domain/entities/partner_validation_entity.dart';

enum PartnerCheckinStatus { initial, generatingToken, tokenGenerated, validating, validated, failure }

class PartnerCheckinState extends Equatable {
  final PartnerCheckinStatus status;
  final String? tokenValue;
  final DateTime? expiresAt;
  final PartnerValidationEntity? validation;
  final String? errorMessage;

  const PartnerCheckinState({
    this.status = PartnerCheckinStatus.initial,
    this.tokenValue,
    this.expiresAt,
    this.validation,
    this.errorMessage,
  });

  PartnerCheckinState copyWith({
    PartnerCheckinStatus? status,
    String? tokenValue,
    DateTime? expiresAt,
    PartnerValidationEntity? validation,
    String? errorMessage,
  }) {
    return PartnerCheckinState(
      status: status ?? this.status,
      tokenValue: tokenValue ?? this.tokenValue,
      expiresAt: expiresAt ?? this.expiresAt,
      validation: validation ?? this.validation,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, tokenValue, expiresAt, validation, errorMessage];
}
