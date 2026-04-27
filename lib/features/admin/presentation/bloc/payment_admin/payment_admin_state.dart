import 'package:equatable/equatable.dart';

import '../../../domain/entities/payment_admin_entity.dart';

enum PaymentAdminStatus { initial, loading, loaded, saving, saved, deleting, deleted, failure }

class PaymentAdminState extends Equatable {
  final PaymentAdminStatus status;
  final List<PaymentAdminEntity> items;
  final List<PaymentAdminEntity> filteredItems;
  final String searchQuery;
  final String? errorMessage;

  const PaymentAdminState({
    this.status = PaymentAdminStatus.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  PaymentAdminState copyWith({
    PaymentAdminStatus? status,
    List<PaymentAdminEntity>? items,
    List<PaymentAdminEntity>? filteredItems,
    String? searchQuery,
    String? errorMessage,
  }) {
    return PaymentAdminState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, filteredItems, searchQuery, errorMessage];
}
