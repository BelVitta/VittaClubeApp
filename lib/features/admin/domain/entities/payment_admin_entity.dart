import 'package:equatable/equatable.dart';

/// Entidade de pagamento no painel admin - objeto de negócio puro.
/// Não possui dependências de Flutter ou packages externos.
class PaymentAdminEntity extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String planName;
  final double amount;
  final String method;
  final String status;
  final String date;
  final String receiptNumber;

  const PaymentAdminEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.planName,
    required this.amount,
    required this.method,
    required this.status,
    required this.date,
    required this.receiptNumber,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        planName,
        amount,
        method,
        status,
        date,
        receiptNumber,
      ];
}
