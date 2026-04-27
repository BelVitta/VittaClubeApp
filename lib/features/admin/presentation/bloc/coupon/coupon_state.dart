import 'package:equatable/equatable.dart';
import '../../../domain/entities/coupon_entity.dart';

enum CouponStatus { initial, loading, loaded, saving, saved, deleting, deleted, failure }

class CouponState extends Equatable {
  final CouponStatus status;
  final List<CouponEntity> items;
  final List<CouponEntity> filteredItems;
  final String searchQuery;
  final String? errorMessage;
  final bool? filterIsActive;

  const CouponState({
    this.status = CouponStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.filterIsActive,
  });

  bool get hasActiveFilters => filterIsActive != null;

  CouponState copyWith({
    CouponStatus? status,
    List<CouponEntity>? items,
    List<CouponEntity>? filteredItems,
    String? searchQuery,
    String? errorMessage,
    bool? filterIsActive,
    bool clearIsActive = false,
  }) {
    return CouponState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      filterIsActive: clearIsActive ? null : (filterIsActive ?? this.filterIsActive),
    );
  }

  @override
  List<Object?> get props => [status, items, filteredItems, searchQuery, errorMessage, filterIsActive];
}
