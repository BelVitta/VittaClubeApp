import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_current_subscription_usecase.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final GetCurrentSubscriptionUseCase getCurrentSubscriptionUseCase;

  SubscriptionBloc({required this.getCurrentSubscriptionUseCase})
      : super(const SubscriptionInitial()) {
    on<LoadCurrentSubscription>(_onLoad);
  }

  Future<void> _onLoad(
    LoadCurrentSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(const SubscriptionLoading());
    final result = await getCurrentSubscriptionUseCase();
    result.fold(
      (failure) => emit(SubscriptionError(failure.message)),
      (sub) => emit(
        sub == null ? const NoSubscription() : SubscriptionLoaded(sub),
      ),
    );
  }
}
