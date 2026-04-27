import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega (ou recarrega) a assinatura atual do usuário logado.
class LoadCurrentSubscription extends SubscriptionEvent {
  const LoadCurrentSubscription();
}
