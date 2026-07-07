import 'dart:convert';

class InfinityPayItem {
  final int quantity;
  final int price; // em centavos
  final String description;

  const InfinityPayItem({
    required this.quantity,
    required this.price,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'quantity': quantity,
        'price': price,
        'description': description,
      };
}

class InfinityPayCustomer {
  final String name;
  final String email;
  final String? phoneNumber;

  const InfinityPayCustomer({
    required this.name,
    required this.email,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      };
}

class InfinityPayCreateLinkRequest {
  final String handle;
  final List<InfinityPayItem> items;
  final String? orderNsu;
  final String? redirectUrl;
  final String? webhookUrl;
  final InfinityPayCustomer? customer;

  const InfinityPayCreateLinkRequest({
    required this.handle,
    required this.items,
    this.orderNsu,
    this.redirectUrl,
    this.webhookUrl,
    this.customer,
  });

  String toJsonString() => jsonEncode({
        'handle': handle,
        'items': items.map((i) => i.toJson()).toList(),
        if (orderNsu != null) 'order_nsu': orderNsu,
        if (redirectUrl != null) 'redirect_url': redirectUrl,
        if (webhookUrl != null) 'webhook_url': webhookUrl,
        if (customer != null) 'customer': customer!.toJson(),
      });
}

class InfinityPayCreateLinkResponse {
  final String checkoutUrl;
  final String? slug;

  const InfinityPayCreateLinkResponse({
    required this.checkoutUrl,
    this.slug,
  });

  factory InfinityPayCreateLinkResponse.fromJson(Map<String, dynamic> json) {
    // A documentação não mostra o campo exato — testamos os mais comuns.
    final url =
        (json['url'] ?? json['checkout_url'] ?? json['link'] ?? '') as String;
    return InfinityPayCreateLinkResponse(
      checkoutUrl: url,
      slug: json['slug'] as String?,
    );
  }
}

class InfinityPayPaymentCheckRequest {
  final String handle;
  final String orderNsu;
  final String transactionNsu;
  final String slug;

  const InfinityPayPaymentCheckRequest({
    required this.handle,
    required this.orderNsu,
    required this.transactionNsu,
    required this.slug,
  });

  String toJsonString() => jsonEncode({
        'handle': handle,
        'order_nsu': orderNsu,
        'transaction_nsu': transactionNsu,
        'slug': slug,
      });
}

class InfinityPayPaymentCheckResponse {
  final bool success;
  final bool paid;
  final int amount;
  final int paidAmount;
  final int installments;
  final String captureMethod;
  final String? receiptUrl;
  final String? transactionNsu;
  final String? orderNsu;
  final String? slug;

  const InfinityPayPaymentCheckResponse({
    required this.success,
    required this.paid,
    required this.amount,
    required this.paidAmount,
    required this.installments,
    required this.captureMethod,
    this.receiptUrl,
    this.transactionNsu,
    this.orderNsu,
    this.slug,
  });

  factory InfinityPayPaymentCheckResponse.fromJson(Map<String, dynamic> json) {
    return InfinityPayPaymentCheckResponse(
      success: json['success'] as bool? ?? false,
      paid: json['paid'] as bool? ?? false,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      paidAmount: (json['paid_amount'] as num?)?.toInt() ?? 0,
      installments: (json['installments'] as num?)?.toInt() ?? 1,
      captureMethod: json['capture_method'] as String? ?? '',
      receiptUrl: json['receipt_url'] as String?,
      transactionNsu: json['transaction_nsu'] as String?,
      orderNsu: json['order_nsu'] as String?,
      slug: (json['slug'] ?? json['invoice_slug']) as String?,
    );
  }
}
