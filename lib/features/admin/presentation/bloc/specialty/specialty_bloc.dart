import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/specialty/get_specialties_usecase.dart';
import '../../../domain/usecases/specialty/create_specialty_usecase.dart';
import '../../../domain/usecases/specialty/update_specialty_usecase.dart';
import '../../../domain/usecases/specialty/delete_specialty_usecase.dart';
import 'specialty_event.dart';
import 'specialty_state.dart';

class SpecialtyBloc extends Bloc<SpecialtyEvent, SpecialtyState> {
  final GetSpecialtiesUseCase getSpecialtiesUseCase;
  final CreateSpecialtyUseCase createSpecialtyUseCase;
  final UpdateSpecialtyUseCase updateSpecialtyUseCase;
  final DeleteSpecialtyUseCase deleteSpecialtyUseCase;

  SpecialtyBloc({
    required this.getSpecialtiesUseCase,
    required this.createSpecialtyUseCase,
    required this.updateSpecialtyUseCase,
    required this.deleteSpecialtyUseCase,
  }) : super(const SpecialtyState()) {
    on<LoadSpecialties>(_onLoad);
    on<SearchSpecialties>(_onSearch);
    on<CreateSpecialtyRequested>(_onCreate);
    on<UpdateSpecialtyRequested>(_onUpdate);
    on<DeleteSpecialtyRequested>(_onDelete);
  }

  Future<void> _onLoad(LoadSpecialties event, Emitter<SpecialtyState> emit) async {
    emit(state.copyWith(status: SpecialtyStatus.loading));
    final result = await getSpecialtiesUseCase();
    result.fold(
      (failure) => emit(state.copyWith(
        status: SpecialtyStatus.failure,
        errorMessage: failure.message,
      )),
      (items) => emit(state.copyWith(
        status: SpecialtyStatus.loaded,
        items: items,
        filteredItems: items,
      )),
    );
  }

  void _onSearch(SearchSpecialties event, Emitter<SpecialtyState> emit) {
    final query = event.query.toLowerCase();
    if (query.isEmpty) {
      emit(state.copyWith(searchQuery: '', filteredItems: state.items));
    } else {
      final filtered = state.items
          .where((item) => item.name.toLowerCase().contains(query))
          .toList();
      emit(state.copyWith(searchQuery: query, filteredItems: filtered));
    }
  }

  Future<void> _onCreate(CreateSpecialtyRequested event, Emitter<SpecialtyState> emit) async {
    emit(state.copyWith(status: SpecialtyStatus.saving));
    final result = await createSpecialtyUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(
        status: SpecialtyStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: SpecialtyStatus.saved));
        add(LoadSpecialties());
      },
    );
  }

  Future<void> _onUpdate(UpdateSpecialtyRequested event, Emitter<SpecialtyState> emit) async {
    emit(state.copyWith(status: SpecialtyStatus.saving));
    final result = await updateSpecialtyUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(
        status: SpecialtyStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: SpecialtyStatus.saved));
        add(LoadSpecialties());
      },
    );
  }

  Future<void> _onDelete(DeleteSpecialtyRequested event, Emitter<SpecialtyState> emit) async {
    emit(state.copyWith(status: SpecialtyStatus.deleting));
    final result = await deleteSpecialtyUseCase(event.id);
    result.fold(
      (failure) => emit(state.copyWith(
        status: SpecialtyStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: SpecialtyStatus.deleted));
        add(LoadSpecialties());
      },
    );
  }
}
