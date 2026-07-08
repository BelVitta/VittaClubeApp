import 'package:equatable/equatable.dart';

/// Um pagamento realizado pelo usuário logado (tabela `payments`).
class PaymentEntity extends Equatable {
  final String id;
  final double amount;
  final String method;
  final String status;
  final String receiptNumber;
  final DateTime? paidAt;

  const PaymentEntity({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
    required this.receiptNumber,
    this.paidAt,
  });

  String get methodLabel => switch (method) {
        'cartao_credito' => 'Cartão de Crédito',
        'pix' => 'Pix',
        'boleto' => 'Boleto',
        _ => method,
      };

  String get statusLabel => switch (status) {
        'aprovado' => 'Pago',
        'pendente' => 'Pendente',
        'cancelado' => 'Cancelado',
        'estornado' => 'Estornado',
        _ => status,
      };

  @override
  List<Object?> get props => [id, amount, method, status, receiptNumber, paidAt];
}
