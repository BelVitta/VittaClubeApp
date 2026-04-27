import 'package:equatable/equatable.dart';

import '../../../domain/entities/consultation_admin_entity.dart';

enum ConsultationAdminStatus { initial, loading, loaded, saving, saved, deleting, deleted, failure }

class ConsultationAdminState extends Equatable {
  final ConsultationAdminStatus status;
  final List<ConsultationAdminEntity> items;
  final List<ConsultationAdminEntity> filteredItems;
  final String searchQuery;
  final String? filterProfessional;
  final DateTime? filterDateStart;
  final DateTime? filterDateEnd;
  final String? errorMessage;
  final int displayCount;
  final bool hasMore;

  static const int pageSize = 10;

  const ConsultationAdminState({
    this.status = ConsultationAdminStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.filterProfessional,
    this.filterDateStart,
    this.filterDateEnd,
    this.errorMessage,
    this.displayCount = pageSize,
    this.hasMore = false,
  });

  List<ConsultationAdminEntity> get visibleItems =>
      filteredItems.take(displayCount).toList();

  List<String> get availableProfessionals {
    final names = items.map((e) => e.professionalName).toSet().toList();
    names.sort();
    return names;
  }

  bool get hasActiveFilters =>
      filterProfessional != null ||
      filterDateStart != null ||
      filterDateEnd != null;

  ConsultationAdminState copyWith({
    ConsultationAdminStatus? status,
    List<ConsultationAdminEntity>? items,
    List<ConsultationAdminEntity>? filteredItems,
    String? searchQuery,
    String? filterProfessional,
    DateTime? filterDateStart,
    DateTime? filterDateEnd,
    String? errorMessage,
    int? displayCount,
    bool? hasMore,
    bool clearProfessional = false,
    bool clearDateStart = false,
    bool clearDateEnd = false,
  }) {
    final newFiltered = filteredItems ?? this.filteredItems;
    final newDisplayCount = displayCount ?? this.displayCount;

    return ConsultationAdminState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredItems: newFiltered,
      searchQuery: searchQuery ?? this.searchQuery,
      filterProfessional: clearProfessional ? null : (filterProfessional ?? this.filterProfessional),
      filterDateStart: clearDateStart ? null : (filterDateStart ?? this.filterDateStart),
      filterDateEnd: clearDateEnd ? null : (filterDateEnd ?? this.filterDateEnd),
      errorMessage: errorMessage,
      displayCount: newDisplayCount,
      hasMore: hasMore ?? newFiltered.length > newDisplayCount,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        filteredItems,
        searchQuery,
        filterProfessional,
        filterDateStart,
        filterDateEnd,
        errorMessage,
        displayCount,
        hasMore,
      ];
}
