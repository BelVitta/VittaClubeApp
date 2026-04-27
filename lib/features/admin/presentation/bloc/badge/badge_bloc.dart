import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/badge/get_badges_usecase.dart';
import '../../../domain/usecases/badge/create_badge_usecase.dart';
import '../../../domain/usecases/badge/update_badge_usecase.dart';
import '../../../domain/usecases/badge/delete_badge_usecase.dart';
import '../../../domain/entities/badge_entity.dart';
import 'badge_event.dart';
import 'badge_state.dart';

class BadgeBloc extends Bloc<BadgeEvent, BadgeState> {
  final GetBadgesUseCase getBadgesUseCase;
  final CreateBadgeUseCase createBadgeUseCase;
  final UpdateBadgeUseCase updateBadgeUseCase;
  final DeleteBadgeUseCase deleteBadgeUseCase;

  BadgeBloc({
    required this.getBadgesUseCase,
    required this.createBadgeUseCase,
    required this.updateBadgeUseCase,
    required this.deleteBadgeUseCase,
  }) : super(const BadgeState()) {
    on<LoadBadges>(_onLoad);
    on<SearchBadges>(_onSearch);
    on<CreateBadgeRequested>(_onCreate);
    on<UpdateBadgeRequested>(_onUpdate);
    on<DeleteBadgeRequested>(_onDelete);
  }

  Future<void> _onLoad(LoadBadges event, Emitter<BadgeState> emit) async {
    emit(state.copyWith(status: BadgeStatus.loading));
    final result = await getBadgesUseCase();
    result.fold(
      (failure) => emit(state.copyWith(status: BadgeStatus.failure, errorMessage: failure.message)),
      (items) => emit(state.copyWith(status: BadgeStatus.loaded, items: items, filteredItems: items)),
    );
  }

  void _onSearch(SearchBadges event, Emitter<BadgeState> emit) {
    final query = event.query.toLowerCase();
    if (query.isEmpty) {
      emit(state.copyWith(searchQuery: '', filteredItems: state.items));
    } else {
      final filtered = state.items.where((item) => _matchesSearch(item, query)).toList();
      emit(state.copyWith(searchQuery: query, filteredItems: filtered));
    }
  }

  bool _matchesSearch(BadgeEntity item, String query) {
    return item.displayName.toLowerCase().contains(query) ||
        item.levelName.toLowerCase().contains(query);
  }

  Future<void> _onCreate(CreateBadgeRequested event, Emitter<BadgeState> emit) async {
    emit(state.copyWith(status: BadgeStatus.saving));
    final result = await createBadgeUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(status: BadgeStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: BadgeStatus.saved));
        add(LoadBadges());
      },
    );
  }

  Future<void> _onUpdate(UpdateBadgeRequested event, Emitter<BadgeState> emit) async {
    emit(state.copyWith(status: BadgeStatus.saving));
    final result = await updateBadgeUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(status: BadgeStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: BadgeStatus.saved));
        add(LoadBadges());
      },
    );
  }

  Future<void> _onDelete(DeleteBadgeRequested event, Emitter<BadgeState> emit) async {
    emit(state.copyWith(status: BadgeStatus.deleting));
    final result = await deleteBadgeUseCase(event.id);
    result.fold(
      (failure) => emit(state.copyWith(status: BadgeStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: BadgeStatus.deleted));
        add(LoadBadges());
      },
    );
  }
}
