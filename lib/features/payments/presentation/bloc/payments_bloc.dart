import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_payment_history_usecase.dart';
import 'payments_event.dart';
import 'payments_state.dart';

class PaymentsBloc extends Bloc<PaymentsEvent, PaymentsState> {
  final GetPaymentHistoryUseCase getPaymentHistoryUseCase;

  PaymentsBloc({required this.getPaymentHistoryUseCase})
      : super(const PaymentsInitial()) {
    on<LoadPaymentHistory>(_onLoad);
  }

  Future<void> _onLoad(
    LoadPaymentHistory event,
    Emitter<PaymentsState> emit,
  ) async {
    emit(const PaymentsLoading());
    final result = await getPaymentHistoryUseCase();
    result.fold(
      (failure) => emit(PaymentsError(failure.message)),
      (items) => emit(PaymentsLoaded(items)),
    );
  }
}
