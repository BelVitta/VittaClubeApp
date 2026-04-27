import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/payment_admin/get_payments_usecase.dart';
import '../../../domain/usecases/payment_admin/create_payment_usecase.dart';
import '../../../domain/usecases/payment_admin/update_payment_usecase.dart';
import '../../../domain/usecases/payment_admin/delete_payment_usecase.dart';
import 'payment_admin_event.dart';
import 'payment_admin_state.dart';

class PaymentAdminBloc extends Bloc<PaymentAdminEvent, PaymentAdminState> {
  final GetPaymentsUseCase getPaymentsUseCase;
  final CreatePaymentUseCase createPaymentUseCase;
  final UpdatePaymentUseCase updatePaymentUseCase;
  final DeletePaymentUseCase deletePaymentUseCase;

  PaymentAdminBloc({
    required this.getPaymentsUseCase,
    required this.createPaymentUseCase,
    required this.updatePaymentUseCase,
    required this.deletePaymentUseCase,
  }) : super(const PaymentAdminState()) {
    on<LoadPayments>(_onLoad);
    on<SearchPayments>(_onSearch);
    on<CreatePaymentRequested>(_onCreate);
    on<UpdatePaymentRequested>(_onUpdate);
    on<DeletePaymentRequested>(_onDelete);
  }

  Future<void> _onLoad(LoadPayments event, Emitter<PaymentAdminState> emit) async {
    emit(state.copyWith(status: PaymentAdminStatus.loading));
    final result = await getPaymentsUseCase();
    result.fold(
      (failure) => emit(state.copyWith(
        status: PaymentAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (items) => emit(state.copyWith(
        status: PaymentAdminStatus.loaded,
        items: items,
        filteredItems: items,
      )),
    );
  }

  void _onSearch(SearchPayments event, Emitter<PaymentAdminState> emit) {
    final query = event.query.toLowerCase();
    if (query.isEmpty) {
      emit(state.copyWith(searchQuery: '', filteredItems: state.items));
    } else {
      final filtered = state.items
          .where((item) =>
              item.userName.toLowerCase().contains(query) ||
              item.planName.toLowerCase().contains(query))
          .toList();
      emit(state.copyWith(searchQuery: query, filteredItems: filtered));
    }
  }

  Future<void> _onCreate(CreatePaymentRequested event, Emitter<PaymentAdminState> emit) async {
    emit(state.copyWith(status: PaymentAdminStatus.saving));
    final result = await createPaymentUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(
        status: PaymentAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: PaymentAdminStatus.saved));
        add(LoadPayments());
      },
    );
  }

  Future<void> _onUpdate(UpdatePaymentRequested event, Emitter<PaymentAdminState> emit) async {
    emit(state.copyWith(status: PaymentAdminStatus.saving));
    final result = await updatePaymentUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(
        status: PaymentAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: PaymentAdminStatus.saved));
        add(LoadPayments());
      },
    );
  }

  Future<void> _onDelete(DeletePaymentRequested event, Emitter<PaymentAdminState> emit) async {
    emit(state.copyWith(status: PaymentAdminStatus.deleting));
    final result = await deletePaymentUseCase(event.id);
    result.fold(
      (failure) => emit(state.copyWith(
        status: PaymentAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: PaymentAdminStatus.deleted));
        add(LoadPayments());
      },
    );
  }
}
