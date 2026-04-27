import 'package:equatable/equatable.dart';
import '../../../domain/entities/notification_template_entity.dart';

abstract class NotificationTemplateEvent extends Equatable {
  const NotificationTemplateEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotificationTemplates extends NotificationTemplateEvent {}

class SearchNotificationTemplates extends NotificationTemplateEvent {
  final String query;
  const SearchNotificationTemplates(this.query);
  @override
  List<Object?> get props => [query];
}

class CreateNotificationTemplateRequested extends NotificationTemplateEvent {
  final NotificationTemplateEntity entity;
  const CreateNotificationTemplateRequested(this.entity);
  @override
  List<Object?> get props => [entity];
}

class UpdateNotificationTemplateRequested extends NotificationTemplateEvent {
  final NotificationTemplateEntity entity;
  const UpdateNotificationTemplateRequested(this.entity);
  @override
  List<Object?> get props => [entity];
}

class DeleteNotificationTemplateRequested extends NotificationTemplateEvent {
  final String id;
  const DeleteNotificationTemplateRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class FilterNotificationsByType extends NotificationTemplateEvent {
  final String? type;
  const FilterNotificationsByType(this.type);
  @override
  List<Object?> get props => [type];
}

class FilterNotificationsByStatus extends NotificationTemplateEvent {
  final bool? isActive;
  const FilterNotificationsByStatus(this.isActive);
  @override
  List<Object?> get props => [isActive];
}

class ClearNotificationFilters extends NotificationTemplateEvent {}
