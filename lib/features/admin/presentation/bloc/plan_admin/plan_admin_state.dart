import 'package:equatable/equatable.dart';

import '../../../domain/entities/plan_admin_entity.dart';

enum PlanAdminStatus { initial, loading, loaded, saving, saved, deleting, deleted, failure }

class PlanAdminState extends Equatable {
  final PlanAdminStatus status;
  final List<PlanAdminEntity> items;
  final List<PlanAdminEntity> filteredItems;
  final String searchQuery;
  final String? errorMessage;

  const PlanAdminState({
    this.status = PlanAdminStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  PlanAdminState copyWith({
    PlanAdminStatus? status,
    List<PlanAdminEntity>? items,
    List<PlanAdminEntity>? filteredItems,
    String? searchQuery,
    String? errorMessage,
  }) {
    return PlanAdminState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, filteredItems, searchQuery, errorMessage];
}
