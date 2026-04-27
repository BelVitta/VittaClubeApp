import 'package:equatable/equatable.dart';
import '../../../domain/entities/badge_entity.dart';

enum BadgeStatus { initial, loading, loaded, saving, saved, deleting, deleted, failure }

class BadgeState extends Equatable {
  final BadgeStatus status;
  final List<BadgeEntity> items;
  final List<BadgeEntity> filteredItems;
  final String searchQuery;
  final String? errorMessage;

  const BadgeState({
    this.status = BadgeStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  BadgeState copyWith({
    BadgeStatus? status,
    List<BadgeEntity>? items,
    List<BadgeEntity>? filteredItems,
    String? searchQuery,
    String? errorMessage,
  }) {
    return BadgeState(
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
