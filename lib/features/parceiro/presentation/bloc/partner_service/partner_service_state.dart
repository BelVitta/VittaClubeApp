import 'package:equatable/equatable.dart';

import '../../../domain/entities/partner_service_entity.dart';

enum PartnerServiceStatus { initial, loading, loaded, saving, saved, deleting, deleted, failure }

class PartnerServiceState extends Equatable {
  final PartnerServiceStatus status;
  final List<PartnerServiceEntity> items;
  final List<PartnerServiceEntity> filteredItems;
  final String searchQuery;
  final String? errorMessage;

  const PartnerServiceState({
    this.status = PartnerServiceStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  PartnerServiceState copyWith({
    PartnerServiceStatus? status,
    List<PartnerServiceEntity>? items,
    List<PartnerServiceEntity>? filteredItems,
    String? searchQuery,
    String? errorMessage,
  }) {
    return PartnerServiceState(
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
