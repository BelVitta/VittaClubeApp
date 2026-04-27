import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/coupon/get_coupons_usecase.dart';
import '../../../domain/usecases/coupon/create_coupon_usecase.dart';
import '../../../domain/usecases/coupon/update_coupon_usecase.dart';
import '../../../domain/usecases/coupon/delete_coupon_usecase.dart';
import '../../../domain/entities/coupon_entity.dart';
import 'coupon_event.dart';
import 'coupon_state.dart';

class CouponBloc extends Bloc<CouponEvent, CouponState> {
  final GetCouponsUseCase getCouponsUseCase;
  final CreateCouponUseCase createCouponUseCase;
  final UpdateCouponUseCase updateCouponUseCase;
  final DeleteCouponUseCase deleteCouponUseCase;

  CouponBloc({
    required this.getCouponsUseCase,
    required this.createCouponUseCase,
    required this.updateCouponUseCase,
    required this.deleteCouponUseCase,
  }) : super(const CouponState()) {
    on<LoadCoupons>(_onLoad);
    on<SearchCoupons>(_onSearch);
    on<CreateCouponRequested>(_onCreate);
    on<UpdateCouponRequested>(_onUpdate);
    on<DeleteCouponRequested>(_onDelete);
    on<FilterCouponsByStatus>(_onFilterByStatus);
    on<ClearCouponFilters>(_onClearFilters);
  }

  Future<void> _onLoad(LoadCoupons event, Emitter<CouponState> emit) async {
    emit(state.copyWith(status: CouponStatus.loading));
    final result = await getCouponsUseCase();
    result.fold(
      (failure) => emit(state.copyWith(status: CouponStatus.failure, errorMessage: failure.message)),
      (items) => emit(state.copyWith(status: CouponStatus.loaded, items: items, filteredItems: items)),
    );
  }

  void _onSearch(SearchCoupons event, Emitter<CouponState> emit) {
    final newState = state.copyWith(searchQuery: event.query);
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onFilterByStatus(FilterCouponsByStatus event, Emitter<CouponState> emit) {
    final newState = state.copyWith(
      filterIsActive: event.isActive,
      clearIsActive: event.isActive == null,
    );
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onClearFilters(ClearCouponFilters event, Emitter<CouponState> emit) {
    final newState = state.copyWith(
      searchQuery: '',
      clearIsActive: true,
    );
    emit(newState.copyWith(filteredItems: newState.items));
  }

  List<CouponEntity> _applyFilters(CouponState s) {
    var result = s.items.toList();

    if (s.searchQuery.isNotEmpty) {
      final query = s.searchQuery.toLowerCase();
      result = result.where((item) =>
          item.code.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query)).toList();
    }

    if (s.filterIsActive != null) {
      result = result.where((item) => item.isActive == s.filterIsActive).toList();
    }

    return result;
  }

  Future<void> _onCreate(CreateCouponRequested event, Emitter<CouponState> emit) async {
    emit(state.copyWith(status: CouponStatus.saving));
    final result = await createCouponUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(status: CouponStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: CouponStatus.saved));
        add(LoadCoupons());
      },
    );
  }

  Future<void> _onUpdate(UpdateCouponRequested event, Emitter<CouponState> emit) async {
    emit(state.copyWith(status: CouponStatus.saving));
    final result = await updateCouponUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(status: CouponStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: CouponStatus.saved));
        add(LoadCoupons());
      },
    );
  }

  Future<void> _onDelete(DeleteCouponRequested event, Emitter<CouponState> emit) async {
    emit(state.copyWith(status: CouponStatus.deleting));
    final result = await deleteCouponUseCase(event.id);
    result.fold(
      (failure) => emit(state.copyWith(status: CouponStatus.failure, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: CouponStatus.deleted));
        add(LoadCoupons());
      },
    );
  }
}
