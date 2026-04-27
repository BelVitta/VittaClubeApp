import 'package:equatable/equatable.dart';
import '../../../domain/entities/cancellation_reason_entity.dart';

enum CancellationReasonStatus { initial, loading, loaded, saving, saved, deleting, deleted, failure }

class CancellationReasonState extends Equatable {
  final CancellationReasonStatus status;
  final List<CancellationReasonEntity> items;
  final List<CancellationReasonEntity> filteredItems;
  final String searchQuery;
  final String? errorMessage;

  const CancellationReasonState({
    this.status = CancellationReasonStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  CancellationReasonState copyWith({
    CancellationReasonStatus? status,
    List<CancellationReasonEntity>? items,
    List<CancellationReasonEntity>? filteredItems,
    String? searchQuery,
    String? errorMessage,
  }) {
    return CancellationReasonState(
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
