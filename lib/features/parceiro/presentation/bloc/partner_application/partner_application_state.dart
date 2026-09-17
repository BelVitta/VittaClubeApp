import 'package:equatable/equatable.dart';

import '../../../domain/entities/partner_application_entity.dart';

enum PartnerApplicationStatus {
  initial,
  loading,
  loaded,
  approving,
  approved,
  rejecting,
  rejected,
  failure,
}

class PartnerApplicationState extends Equatable {
  final PartnerApplicationStatus status;
  final List<PartnerApplicationEntity> items;
  final List<PartnerApplicationEntity> filteredItems;
  final String searchQuery;
  final String? filterStatus;
  final String? filterCategory;
  final String? errorMessage;

  const PartnerApplicationState({
    this.status = PartnerApplicationStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.filterStatus,
    this.filterCategory,
    this.errorMessage,
  });

  bool get hasActiveFilters => filterStatus != null || filterCategory != null;

  PartnerApplicationState copyWith({
    PartnerApplicationStatus? status,
    List<PartnerApplicationEntity>? items,
    List<PartnerApplicationEntity>? filteredItems,
    String? searchQuery,
    String? filterStatus,
    bool clearFilterStatus = false,
    String? filterCategory,
    bool clearFilterCategory = false,
    String? errorMessage,
  }) {
    return PartnerApplicationState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus:
          clearFilterStatus ? null : (filterStatus ?? this.filterStatus),
      filterCategory:
          clearFilterCategory ? null : (filterCategory ?? this.filterCategory),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        filteredItems,
        searchQuery,
        filterStatus,
        filterCategory,
        errorMessage,
      ];
}
