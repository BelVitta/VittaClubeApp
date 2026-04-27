import 'package:equatable/equatable.dart';

import '../../../domain/entities/payment_admin_entity.dart';

abstract class PaymentAdminEvent extends Equatable {
  const PaymentAdminEvent();

  @override
  List<Object?> get props => [];
}

class LoadPayments extends PaymentAdminEvent {}

class SearchPayments extends PaymentAdminEvent {
  final String query;

  const SearchPayments(this.query);

  @override
  List<Object?> get props => [query];
}

class CreatePaymentRequested extends PaymentAdminEvent {
  final PaymentAdminEntity entity;

  const CreatePaymentRequested(this.entity);

  @override
  List<Object?> get props => [entity];
}

class UpdatePaymentRequested extends PaymentAdminEvent {
  final PaymentAdminEntity entity;

  const UpdatePaymentRequested(this.entity);

  @override
  List<Object?> get props => [entity];
}

class DeletePaymentRequested extends PaymentAdminEvent {
  final String id;

  const DeletePaymentRequested(this.id);

  @override
  List<Object?> get props => [id];
}
