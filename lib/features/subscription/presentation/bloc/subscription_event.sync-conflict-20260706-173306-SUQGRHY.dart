import 'package:equatable/equatable.dart';

import '../../domain/repositories/subscription_repository.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega (ou recarrega) a assinatura atual do usuário logado.
class LoadCurrentSubscription extends SubscriptionEvent {
  const LoadCurrentSubscription();
}

class CreatePixAutomaticSubscriptionRequested extends SubscriptionEvent {
  final String planId;
  final PixAutomaticCustomer customer;

  const CreatePixAutomaticSubscriptionRequested({
    required this.planId,
    required this.customer,
  });

  @override
  List<Object?> get props => [planId, customer];
}

class RefreshSubscriptionStatusRequested extends SubscriptionEvent {
  const RefreshSubscriptionStatusRequested();
}

class CancelSubscriptionRequested extends SubscriptionEvent {
  final String subscriptionId;
  final String? reason;

  const CancelSubscriptionRequested({
    required this.subscriptionId,
    this.reason,
  });

  @override
  List<Object?> get props => [subscriptionId, reason];
}
