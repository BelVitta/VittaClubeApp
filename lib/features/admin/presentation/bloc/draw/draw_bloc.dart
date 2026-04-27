import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/draw/get_draws_usecase.dart';
import '../../../domain/usecases/draw/create_draw_usecase.dart';
import '../../../domain/usecases/draw/update_draw_usecase.dart';
import '../../../domain/usecases/draw/delete_draw_usecase.dart';
import '../../../domain/usecases/draw/execute_draw_usecase.dart';
import '../../../domain/entities/draw_entity.dart';
import 'draw_event.dart';
import 'draw_state.dart';

class DrawBloc extends Bloc<DrawEvent, DrawState> {
  final GetDrawsUseCase getDrawsUseCase;
  final CreateDrawUseCase createDrawUseCase;
  final UpdateDrawUseCase updateDrawUseCase;
  final DeleteDrawUseCase deleteDrawUseCase;
  final ExecuteDrawUseCase executeDrawUseCase;

  DrawBloc({
    required this.getDrawsUseCase,
    required this.createDrawUseCase,
    required this.updateDrawUseCase,
    required this.deleteDrawUseCase,
    required this.executeDrawUseCase,
  }) : super(const DrawState()) {
    on<LoadDraws>(_onLoad);
    on<SearchDraws>(_onSearch);
    on<CreateDrawRequested>(_onCreate);
    on<UpdateDrawRequested>(_onUpdate);
    on<DeleteDrawRequested>(_onDelete);
    on<ExecuteDrawRequested>(_onExecute);
    on<FilterDrawsByStatus>(_onFilterByStatus);
    on<ClearDrawFilters>(_onClearFilters);
  }

  Future<void> _onLoad(LoadDraws event, Emitter<DrawState> emit) async {
    emit(state.copyWith(status: DrawStatus.loading));
    final result = await getDrawsUseCase();
    result.fold(
      (failure) => emit(state.copyWith(status: DrawStatus.failure, errorMessage: failure.message)),
      (items) => emit(state.copyWith(status: DrawStatus.loaded, items: items, filteredItems: items)),
    );
  }

  void _onSearch(SearchDraws event, Emitter<DrawState> emit) {
    final newState = state.copyWith(searchQuery: event.query);
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onFilterByStatus(FilterDrawsByStatus event, Emitter<DrawState> emit) {
    final newState = state.copyWith(
      filterDrawStatus: event.status,
      clearDrawStatus: event.status == null,
    );
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onClearFilters(ClearDrawFilters event, Emitter<DrawState> emit) {
    final newState = state.copyWith(
      searchQuery: '',
      clearDrawStatus: true,
    );
    emit(newState.copyWith(filteredItems: newState.items));
  }

  List<DrawEntity> _applyFilters(DrawState s) {
    var result = s.items.toList();

    if (s.searchQuery.isNotEmpty) {
      final query = s.searchQuery.toLowerCase();
      result = result.where((item) =>
          item.name.toLowerCase().contains(query) ||
          item.prizeName.toLowerCase().contains(query)).toList();
    }

    if (s.filterDrawStatus != null) {
      result = result.where((item) => item.status == s.filterDrawStatus).toList();
    }

    return result;
  }

  Future<void> _onCreate(CreateDrawRequested event, Emitter<DrawState> emit) async {
    emit(state.copyWith(status: DrawStatus.saving));
    final result = await createDrawUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(status: DrawStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: DrawStatus.saved));
        add(LoadDraws());
      },
    );
  }

  Future<void> _onUpdate(UpdateDrawRequested event, Emitter<DrawState> emit) async {
    emit(state.copyWith(status: DrawStatus.saving));
    final result = await updateDrawUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(status: DrawStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: DrawStatus.saved));
        add(LoadDraws());
      },
    );
  }

  Future<void> _onDelete(DeleteDrawRequested event, Emitter<DrawState> emit) async {
    emit(state.copyWith(status: DrawStatus.deleting));
    final result = await deleteDrawUseCase(event.id);
    result.fold(
      (failure) => emit(state.copyWith(status: DrawStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: DrawStatus.deleted));
        add(LoadDraws());
      },
    );
  }

  Future<void> _onExecute(ExecuteDrawRequested event, Emitter<DrawState> emit) async {
    emit(state.copyWith(status: DrawStatus.executing));
    final result = await executeDrawUseCase(event.drawId);
    result.fold(
      (failure) => emit(state.copyWith(status: DrawStatus.failure, errorMessage: failure.message)),
      (draw) {
        emit(state.copyWith(status: DrawStatus.executed, executedDraw: draw));
        add(LoadDraws());
      },
    );
  }
}
