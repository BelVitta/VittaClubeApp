import '../../domain/entities/cancellation_reason_entity.dart';

/// Model de motivo de cancelamento - DTO para serialização.
/// Estende CancellationReasonEntity e adiciona métodos fromJson/toJson.
class CancellationReasonModel extends CancellationReasonEntity {
  const CancellationReasonModel({
    required super.id,
    required super.text,
    required super.usageCount,
    required super.isActive,
  });

  /// Cria CancellationReasonModel a partir de JSON
  factory CancellationReasonModel.fromJson(Map<String, dynamic> json) {
    return CancellationReasonModel(
      id: json['id'] as String,
      text: json['text'] as String,
      usageCount: json['usageCount'] as int,
      isActive: json['isActive'] as bool,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'usageCount': usageCount,
      'isActive': isActive,
    };
  }

  /// Cria CancellationReasonModel a partir de CancellationReasonEntity
  factory CancellationReasonModel.fromEntity(
      CancellationReasonEntity entity) {
    return CancellationReasonModel(
      id: entity.id,
      text: entity.text,
      usageCount: entity.usageCount,
      isActive: entity.isActive,
    );
  }
}
