import 'package:equatable/equatable.dart';

import '../../../domain/entities/professional_entity.dart';

enum ProfessionalStatus { initial, loading, loaded, saving, saved, deleting, deleted, failure }

class ProfessionalState extends Equatable {
  final ProfessionalStatus status;
  final List<ProfessionalEntity> items;
  final List<ProfessionalEntity> filteredItems;
  final String searchQuery;
  final String? errorMessage;
  final String? filterSpecialty;
  final bool? filterIsActive;

  const ProfessionalState({
    this.status = ProfessionalStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.filterSpecialty,
    this.filterIsActive,
  });

  List<String> get availableSpecialties {
    final names = items.map((e) => e.specialtyName).toSet().toList();
    names.sort();
    return names;
  }

  bool get hasActiveFilters => filterSpecialty != null || filterIsActive != null;

  ProfessionalState copyWith({
    ProfessionalStatus? status,
    List<ProfessionalEntity>? items,
    List<ProfessionalEntity>? filteredItems,
    String? searchQuery,
    String? errorMessage,
    String? filterSpecialty,
    bool? filterIsActive,
    bool clearSpecialty = false,
    bool clearIsActive = false,
  }) {
    return ProfessionalState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      filterSpecialty: clearSpecialty ? null : (filterSpecialty ?? this.filterSpecialty),
      filterIsActive: clearIsActive ? null : (filterIsActive ?? this.filterIsActive),
    );
  }

  @override
  List<Object?> get props => [status, items, filteredItems, searchQuery, errorMessage, filterSpecialty, filterIsActive];
}
