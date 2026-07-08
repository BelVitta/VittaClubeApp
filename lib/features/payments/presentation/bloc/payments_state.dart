import 'package:equatable/equatable.dart';

import '../../domain/entities/payment_entity.dart';

abstract class PaymentsState extends Equatable {
  const PaymentsState();

  @override
  List<Object?> get props => [];
}

class PaymentsInitial extends PaymentsState {
  const PaymentsInitial();
}

class PaymentsLoading extends PaymentsState {
  const PaymentsLoading();
}

class PaymentsLoaded extends PaymentsState {
  final List<PaymentEntity> items;
  const PaymentsLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class PaymentsError extends PaymentsState {
  final String message;
  const PaymentsError(this.message);

  @override
  List<Object?> get props => [message];
}
