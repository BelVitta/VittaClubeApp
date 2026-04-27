import 'package:equatable/equatable.dart';

import '../../../domain/entities/partner_validation_entity.dart';

enum PartnerValidationStatus { initial, loading, loaded, failure }

class PartnerValidationState extends Equatable {
  final PartnerValidationStatus status;
  final List<PartnerValidationEntity> items;
  final List<PartnerValidationEntity> filteredItems;
  final String searchQuery;
  final String? errorMessage;

  const PartnerValidationState({
    this.status = PartnerValidationStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  PartnerValidationState copyWith({
    PartnerValidationStatus? status,
    List<PartnerValidationEntity>? items,
    List<PartnerValidationEntity>? filteredItems,
    String? searchQuery,
    String? errorMessage,
  }) {
    return PartnerValidationState(
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
