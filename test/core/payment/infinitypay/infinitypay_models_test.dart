import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/core/payment/infinitypay/infinitypay_models.dart';

void main() {
  group('InfinityPayCreateLinkRequest', () {
    test('serializes checkout payload with documented items key', () {
      const request = InfinityPayCreateLinkRequest(
        handle: 'vinicius-belchior-car',
        orderNsu: 'vitta_123',
        redirectUrl: 'vittaclube://payment/infinitypay/return',
        items: [
          InfinityPayItem(
            description: 'Vitta Assinatura',
            quantity: 1,
            price: 3490,
          ),
        ],
      );

      final json = jsonDecode(request.toJsonString()) as Map<String, dynamic>;

      expect(json['handle'], 'vinicius-belchior-car');
      expect(json['order_nsu'], 'vitta_123');
      expect(json['redirect_url'], 'vittaclube://payment/infinitypay/return');
      expect(json.containsKey('items'), isTrue);
      expect(json.containsKey('itens'), isFalse);
      expect(json['items'], [
        {
          'quantity': 1,
          'price': 3490,
          'description': 'Vitta Assinatura',
        },
      ]);
    });
  });

  group('InfinityPayPaymentCheckResponse', () {
    test('parses documented payment_check fields', () {
      final response = InfinityPayPaymentCheckResponse.fromJson({
        'success': true,
        'paid': true,
        'amount': 3490,
        'paid_amount': 3490,
        'installments': 1,
        'capture_method': 'pix',
        'transaction_nsu': 'txn_123',
        'order_nsu': 'vitta_123',
        'invoice_slug': 'invoice_123',
        'receipt_url': 'https://receipt.example/123',
      });

      expect(response.success, isTrue);
      expect(response.paid, isTrue);
      expect(response.amount, 3490);
      expect(response.paidAmount, 3490);
      expect(response.installments, 1);
      expect(response.captureMethod, 'pix');
      expect(response.transactionNsu, 'txn_123');
      expect(response.orderNsu, 'vitta_123');
      expect(response.slug, 'invoice_123');
      expect(response.receiptUrl, 'https://receipt.example/123');
    });
  });
}
