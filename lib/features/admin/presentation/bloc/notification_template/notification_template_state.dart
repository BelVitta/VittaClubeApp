import 'package:equatable/equatable.dart';
import '../../../domain/entities/notification_template_entity.dart';

enum NotificationTemplateStatus { initial, loading, loaded, saving, saved, deleting, deleted, failure }

class NotificationTemplateState extends Equatable {
  final NotificationTemplateStatus status;
  final List<NotificationTemplateEntity> items;
  final List<NotificationTemplateEntity> filteredItems;
  final String searchQuery;
  final String? errorMessage;
  final String? filterType;
  final bool? filterIsActive;

  const NotificationTemplateState({
    this.status = NotificationTemplateStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.filterType,
    this.filterIsActive,
  });

  bool get hasActiveFilters => filterType != null || filterIsActive != null;

  NotificationTemplateState copyWith({
    NotificationTemplateStatus? status,
    List<NotificationTemplateEntity>? items,
    List<NotificationTemplateEntity>? filteredItems,
    String? searchQuery,
    String? errorMessage,
    String? filterType,
    bool? filterIsActive,
    bool clearType = false,
    bool clearIsActive = false,
  }) {
    return NotificationTemplateState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      filterType: clearType ? null : (filterType ?? this.filterType),
      filterIsActive: clearIsActive ? null : (filterIsActive ?? this.filterIsActive),
    );
  }

  @override
  List<Object?> get props => [status, items, filteredItems, searchQuery, errorMessage, filterType, filterIsActive];
}
