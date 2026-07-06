import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/cancel_subscription_usecase.dart';
import '../../domain/usecases/create_pix_automatic_subscription_usecase.dart';
import '../../domain/usecases/get_current_subscription_usecase.dart';
import '../../domain/usecases/refresh_subscription_status_usecase.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final GetCurrentSubscriptionUseCase getCurrentSubscriptionUseCase;
  final CreatePixAutomaticSubscriptionUseCase?
      createPixAutomaticSubscriptionUseCase;
  final RefreshSubscriptionStatusUseCase? refreshSubscriptionStatusUseCase;
  final CancelSubscriptionUseCase? cancelSubscriptionUseCase;

  SubscriptionBloc({
    required this.getCurrentSubscriptionUseCase,
    this.createPixAutomaticSubscriptionUseCase,
    this.refreshSubscriptionStatusUseCase,
    this.cancelSubscriptionUseCase,
  }) : super(const SubscriptionInitial()) {
    on<LoadCurrentSubscription>(_onLoad);
    on<CreatePixAutomaticSubscriptionRequested>(_onCreatePixAutomatic);
    on<RefreshSubscriptionStatusRequested>(_onRefresh);
    on<CancelSubscriptionRequested>(_onCancel);
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

  Future<void> _onCreatePixAutomatic(
    CreatePixAutomaticSubscriptionRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    final useCase = createPixAutomaticSubscriptionUseCase;
    if (useCase == null) {
      emit(const SubscriptionError('Fluxo Pix Automático indisponível.'));
      return;
    }

    emit(const SubscriptionActionLoading('Criando assinatura...'));
    final result = await useCase(
      CreatePixAutomaticSubscriptionParams(
        planId: event.planId,
        customer: event.customer,
      ),
    );
    result.fold(
      (failure) => emit(SubscriptionError(failure.message)),
      (subscription) => emit(SubscriptionLoaded(subscription)),
    );
  }

  Future<void> _onRefresh(
    RefreshSubscriptionStatusRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    final useCase = refreshSubscriptionStatusUseCase;
    if (useCase == null) {
      add(const LoadCurrentSubscription());
      return;
    }

    emit(const SubscriptionActionLoading('Atualizando status...'));
    final result = await useCase();
    result.fold(
      (failure) => emit(SubscriptionError(failure.message)),
      (sub) => emit(
        sub == null ? const NoSubscription() : SubscriptionLoaded(sub),
      ),
    );
  }

  Future<void> _onCancel(
    CancelSubscriptionRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    final useCase = cancelSubscriptionUseCase;
    if (useCase == null) {
      emit(const SubscriptionError('Cancelamento indisponível.'));
      return;
    }

    emit(const SubscriptionActionLoading('Cancelando assinatura...'));
    final result = await useCase(
      subscriptionId: event.subscriptionId,
      reason: event.reason,
    );
    result.fold(
      (failure) => emit(SubscriptionError(failure.message)),
      (_) => emit(const SubscriptionActionSuccess('Assinatura cancelada.')),
    );
  }
}
