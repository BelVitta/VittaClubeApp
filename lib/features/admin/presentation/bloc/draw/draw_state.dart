import 'package:equatable/equatable.dart';
import '../../../domain/entities/draw_entity.dart';

enum DrawStatus { initial, loading, loaded, saving, saved, deleting, deleted, executing, executed, failure }

class DrawState extends Equatable {
  final DrawStatus status;
  final List<DrawEntity> items;
  final List<DrawEntity> filteredItems;
  final String searchQuery;
  final String? errorMessage;
  final String? filterDrawStatus;
  final DrawEntity? executedDraw; // Resultado do sorteio realizado

  const DrawState({
    this.status = DrawStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.filterDrawStatus,
    this.executedDraw,
  });

  bool get hasActiveFilters => filterDrawStatus != null;

  DrawState copyWith({
    DrawStatus? status,
    List<DrawEntity>? items,
    List<DrawEntity>? filteredItems,
    String? searchQuery,
    String? errorMessage,
    String? filterDrawStatus,
    bool clearDrawStatus = false,
    DrawEntity? executedDraw,
    bool clearExecutedDraw = false,
  }) {
    return DrawState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      filterDrawStatus: clearDrawStatus ? null : (filterDrawStatus ?? this.filterDrawStatus),
      executedDraw: clearExecutedDraw ? null : (executedDraw ?? this.executedDraw),
    );
  }

  @override
  List<Object?> get props => [status, items, filteredItems, searchQuery, errorMessage, filterDrawStatus, executedDraw];
}
