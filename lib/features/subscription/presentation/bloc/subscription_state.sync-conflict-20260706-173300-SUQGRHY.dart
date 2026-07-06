import 'package:equatable/equatable.dart';

import '../../domain/entities/subscription_entity.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

class SubscriptionActionLoading extends SubscriptionState {
  final String message;

  const SubscriptionActionLoading(this.message);

  @override
  List<Object?> get props => [message];
}

/// Usuário tem assinatura ativa.
class SubscriptionLoaded extends SubscriptionState {
  final SubscriptionEntity subscription;
  const SubscriptionLoaded(this.subscription);

  @override
  List<Object?> get props => [subscription];
}

/// Usuário não tem assinatura — UI deve mostrar NoPlanCard.
class NoSubscription extends SubscriptionState {
  const NoSubscription();
}

class SubscriptionError extends SubscriptionState {
  final String message;
  const SubscriptionError(this.message);

  @override
  List<Object?> get props => [message];
}

class SubscriptionActionSuccess extends SubscriptionState {
  final String message;

  const SubscriptionActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
