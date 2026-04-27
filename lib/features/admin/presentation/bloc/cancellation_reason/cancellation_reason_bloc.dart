import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/cancellation_reason/get_cancellation_reasons_usecase.dart';
import '../../../domain/usecases/cancellation_reason/create_cancellation_reason_usecase.dart';
import '../../../domain/usecases/cancellation_reason/update_cancellation_reason_usecase.dart';
import '../../../domain/usecases/cancellation_reason/delete_cancellation_reason_usecase.dart';
import '../../../domain/entities/cancellation_reason_entity.dart';
import 'cancellation_reason_event.dart';
import 'cancellation_reason_state.dart';

class CancellationReasonBloc extends Bloc<CancellationReasonEvent, CancellationReasonState> {
  final GetCancellationReasonsUseCase getCancellationReasonsUseCase;
  final CreateCancellationReasonUseCase createCancellationReasonUseCase;
  final UpdateCancellationReasonUseCase updateCancellationReasonUseCase;
  final DeleteCancellationReasonUseCase deleteCancellationReasonUseCase;

  CancellationReasonBloc({
    required this.getCancellationReasonsUseCase,
    required this.createCancellationReasonUseCase,
    required this.updateCancellationReasonUseCase,
    required this.deleteCancellationReasonUseCase,
  }) : super(const CancellationReasonState()) {
    on<LoadCancellationReasons>(_onLoad);
    on<SearchCancellationReasons>(_onSearch);
    on<CreateCancellationReasonRequested>(_onCreate);
    on<UpdateCancellationReasonRequested>(_onUpdate);
    on<DeleteCancellationReasonRequested>(_onDelete);
  }

  Future<void> _onLoad(LoadCancellationReasons event, Emitter<CancellationReasonState> emit) async {
    emit(state.copyWith(status: CancellationReasonStatus.loading));
    final result = await getCancellationReasonsUseCase();
    result.fold(
      (failure) => emit(state.copyWith(status: CancellationReasonStatus.failure, errorMessage: failure.message)),
      (items) => emit(state.copyWith(status: CancellationReasonStatus.loaded, items: items, filteredItems: items)),
    );
  }

  void _onSearch(SearchCancellationReasons event, Emitter<CancellationReasonState> emit) {
    final query = event.query.toLowerCase();
    if (query.isEmpty) {
      emit(state.copyWith(searchQuery: '', filteredItems: state.items));
    } else {
      final filtered = state.items.where((item) => _matchesSearch(item, query)).toList();
      emit(state.copyWith(searchQuery: query, filteredItems: filtered));
    }
  }

  bool _matchesSearch(CancellationReasonEntity item, String query) {
    return item.text.toLowerCase().contains(query);
  }

  Future<void> _onCreate(CreateCancellationReasonRequested event, Emitter<CancellationReasonState> emit) async {
    emit(state.copyWith(status: CancellationReasonStatus.saving));
    final result = await createCancellationReasonUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(status: CancellationReasonStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: CancellationReasonStatus.saved));
        add(LoadCancellationReasons());
      },
    );
  }

  Future<void> _onUpdate(UpdateCancellationReasonRequested event, Emitter<CancellationReasonState> emit) async {
    emit(state.copyWith(status: CancellationReasonStatus.saving));
    final result = await updateCancellationReasonUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(status: CancellationReasonStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: CancellationReasonStatus.saved));
        add(LoadCancellationReasons());
      },
    );
  }

  Future<void> _onDelete(DeleteCancellationReasonRequested event, Emitter<CancellationReasonState> emit) async {
    emit(state.copyWith(status: CancellationReasonStatus.deleting));
    final result = await deleteCancellationReasonUseCase(event.id);
    result.fold(
      (failure) => emit(state.copyWith(status: CancellationReasonStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: CancellationReasonStatus.deleted));
        add(LoadCancellationReasons());
      },
    );
  }
}
