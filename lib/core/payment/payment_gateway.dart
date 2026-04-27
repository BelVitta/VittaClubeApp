import 'package:equatable/equatable.dart';

/// Método de pagamento aceito. Alinhado com o enum `payment_method` do Supabase.
enum PaymentMethodType { creditCard, pix, boleto }

extension PaymentMethodTypeDb on PaymentMethodType {
  String get dbValue {
    switch (this) {
      case PaymentMethodType.creditCard:
        return 'cartao_credito';
      case PaymentMethodType.pix:
        return 'pix';
      case PaymentMethodType.boleto:
        return 'boleto';
    }
  }
}

/// Dados enviados para o gateway.
class PaymentRequest extends Equatable {
  final String planId;
  final double amount;
  final PaymentMethodType method;

  /// Para cartão. Null quando método for pix/boleto.
  final String? cardHolderName;
  final String? cardNumber;
  final String? cardExpiry;
  final String? cardCvv;

  const PaymentRequest({
    required this.planId,
    required this.amount,
    required this.method,
    this.cardHolderName,
    this.cardNumber,
    this.cardExpiry,
    this.cardCvv,
  });

  @override
  List<Object?> get props => [planId, amount, method, cardHolderName, cardNumber];
}

/// Resposta do gateway após a tentativa de cobrança.
class PaymentResult extends Equatable {
  final bool approved;
  final String? receiptNumber;
  final String? errorMessage;

  const PaymentResult.approved(this.receiptNumber)
      : approved = true,
        errorMessage = null;

  const PaymentResult.denied(this.errorMessage)
      : approved = false,
        receiptNumber = null;

  @override
  List<Object?> get props => [approved, receiptNumber, errorMessage];
}

/// Contrato plugável para gateways de pagamento.
/// Trocar a implementação (Stripe / Mercado Pago / Pagar.me) NÃO deve exigir
/// mudanças nas telas de pagamento.
abstract class PaymentGateway {
  Future<PaymentResult> charge(PaymentRequest request);
}
