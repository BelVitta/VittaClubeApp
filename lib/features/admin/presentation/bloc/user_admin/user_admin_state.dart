import 'package:equatable/equatable.dart';

import '../../../domain/entities/user_admin_entity.dart';

enum UserAdminStatus { initial, loading, loaded, saving, saved, deleting, deleted, failure }

class UserAdminState extends Equatable {
  final UserAdminStatus status;
  final List<UserAdminEntity> items;
  final List<UserAdminEntity> filteredItems;
  final String searchQuery;
  final String? errorMessage;
  final String? filterStatus;
  final String? filterLevel;

  const UserAdminState({
    this.status = UserAdminStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.filterStatus,
    this.filterLevel,
  });

  bool get hasActiveFilters => filterStatus != null || filterLevel != null;

  UserAdminState copyWith({
    UserAdminStatus? status,
    List<UserAdminEntity>? items,
    List<UserAdminEntity>? filteredItems,
    String? searchQuery,
    String? errorMessage,
    String? filterStatus,
    String? filterLevel,
    bool clearFilterStatus = false,
    bool clearFilterLevel = false,
  }) {
    return UserAdminState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      filterStatus: clearFilterStatus ? null : (filterStatus ?? this.filterStatus),
      filterLevel: clearFilterLevel ? null : (filterLevel ?? this.filterLevel),
    );
  }

  @override
  List<Object?> get props => [status, items, filteredItems, searchQuery, errorMessage, filterStatus, filterLevel];
}
