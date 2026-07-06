import 'package:equatable/equatable.dart';

import '../../domain/repositories/qr_validation_repository.dart';

enum QrValidationStatus { initial, loading, completed, failure }

class QrValidationState extends Equatable {
  final QrValidationStatus status;
  final QrValidationResult? result;
  final String? errorMessage;

  const QrValidationState({
    this.status = QrValidationStatus.initial,
    this.result,
    this.errorMessage,
  });

  QrValidationState copyWith({
    QrValidationStatus? status,
    QrValidationResult? result,
    String? errorMessage,
  }) {
    return QrValidationState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, result, errorMessage];
}
