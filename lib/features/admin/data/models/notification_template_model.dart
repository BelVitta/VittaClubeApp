import '../../domain/entities/notification_template_entity.dart';

/// Model de template de notificação - DTO para serialização.
/// Estende NotificationTemplateEntity e adiciona métodos fromJson/toJson.
class NotificationTemplateModel extends NotificationTemplateEntity {
  const NotificationTemplateModel({
    required super.id,
    required super.title,
    required super.body,
    required super.type,
    required super.triggerEvent,
    required super.isActive,
  });

  /// Cria NotificationTemplateModel a partir de JSON
  factory NotificationTemplateModel.fromJson(Map<String, dynamic> json) {
    return NotificationTemplateModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      triggerEvent: json['triggerEvent'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'triggerEvent': triggerEvent,
      'isActive': isActive,
    };
  }

  /// Cria NotificationTemplateModel a partir de NotificationTemplateEntity
  factory NotificationTemplateModel.fromEntity(
      NotificationTemplateEntity entity) {
    return NotificationTemplateModel(
      id: entity.id,
      title: entity.title,
      body: entity.body,
      type: entity.type,
      triggerEvent: entity.triggerEvent,
      isActive: entity.isActive,
    );
  }
}
