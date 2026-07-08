import 'package:equatable/equatable.dart';

abstract class PaymentsEvent extends Equatable {
  const PaymentsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPaymentHistory extends PaymentsEvent {
  const LoadPaymentHistory();
}
