import 'package:equatable/equatable.dart';

import '../../../domain/entities/specialty_entity.dart';

enum SpecialtyStatus { initial, loading, loaded, saving, saved, deleting, deleted, failure }

class SpecialtyState extends Equatable {
  final SpecialtyStatus status;
  final List<SpecialtyEntity> items;
  final List<SpecialtyEntity> filteredItems;
  final String searchQuery;
  final String? errorMessage;

  const SpecialtyState({
    this.status = SpecialtyStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  SpecialtyState copyWith({
    SpecialtyStatus? status,
    List<SpecialtyEntity>? items,
    List<SpecialtyEntity>? filteredItems,
    String? searchQuery,
    String? errorMessage,
  }) {
    return SpecialtyState(
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
