import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/plan_admin/get_plans_usecase.dart';
import '../../../domain/usecases/plan_admin/create_plan_usecase.dart';
import '../../../domain/usecases/plan_admin/update_plan_usecase.dart';
import '../../../domain/usecases/plan_admin/delete_plan_usecase.dart';
import 'plan_admin_event.dart';
import 'plan_admin_state.dart';

class PlanAdminBloc extends Bloc<PlanAdminEvent, PlanAdminState> {
  final GetPlansUseCase getPlansUseCase;
  final CreatePlanUseCase createPlanUseCase;
  final UpdatePlanUseCase updatePlanUseCase;
  final DeletePlanUseCase deletePlanUseCase;

  PlanAdminBloc({
    required this.getPlansUseCase,
    required this.createPlanUseCase,
    required this.updatePlanUseCase,
    required this.deletePlanUseCase,
  }) : super(const PlanAdminState()) {
    on<LoadPlans>(_onLoad);
    on<SearchPlans>(_onSearch);
    on<CreatePlanRequested>(_onCreate);
    on<UpdatePlanRequested>(_onUpdate);
    on<DeletePlanRequested>(_onDelete);
  }

  Future<void> _onLoad(LoadPlans event, Emitter<PlanAdminState> emit) async {
    emit(state.copyWith(status: PlanAdminStatus.loading));
    final result = await getPlansUseCase();
    result.fold(
      (failure) => emit(state.copyWith(
        status: PlanAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (items) => emit(state.copyWith(
        status: PlanAdminStatus.loaded,
        items: items,
        filteredItems: items,
      )),
    );
  }

  void _onSearch(SearchPlans event, Emitter<PlanAdminState> emit) {
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

  Future<void> _onCreate(CreatePlanRequested event, Emitter<PlanAdminState> emit) async {
    emit(state.copyWith(status: PlanAdminStatus.saving));
    final result = await createPlanUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(
        status: PlanAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: PlanAdminStatus.saved));
        add(LoadPlans());
      },
    );
  }

  Future<void> _onUpdate(UpdatePlanRequested event, Emitter<PlanAdminState> emit) async {
    emit(state.copyWith(status: PlanAdminStatus.saving));
    final result = await updatePlanUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(
        status: PlanAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: PlanAdminStatus.saved));
        add(LoadPlans());
      },
    );
  }

  Future<void> _onDelete(DeletePlanRequested event, Emitter<PlanAdminState> emit) async {
    emit(state.copyWith(status: PlanAdminStatus.deleting));
    final result = await deletePlanUseCase(event.id);
    result.fold(
      (failure) => emit(state.copyWith(
        status: PlanAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: PlanAdminStatus.deleted));
        add(LoadPlans());
      },
    );
  }
}
