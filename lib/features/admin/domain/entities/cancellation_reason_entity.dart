import 'package:equatable/equatable.dart';

/// Entidade de motivo de cancelamento - objeto de negócio puro.
/// Não possui dependências de Flutter ou packages externos.
class CancellationReasonEntity extends Equatable {
  final String id;
  final String text;
  final int usageCount;
  final bool isActive;

  const CancellationReasonEntity({
    required this.id,
    required this.text,
    required this.usageCount,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, text, usageCount, isActive];
}
