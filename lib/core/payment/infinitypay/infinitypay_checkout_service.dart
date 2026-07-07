import 'dart:convert';

import 'package:http/http.dart' as http;

import 'infinitypay_models.dart';

class InfinityPayCheckoutException implements Exception {
  final String message;
  final int? statusCode;

  const InfinityPayCheckoutException(this.message, {this.statusCode});

  @override
  String toString() => 'InfinityPayCheckoutException: $message';
}

class InfinityPayCheckoutService {
  static const _baseUrl = 'https://api.checkout.infinitepay.io';

  final String handle;
  final http.Client _client;

  InfinityPayCheckoutService({
    required this.handle,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Cria um link de checkout e retorna a URL para redirecionar o usuário.
  Future<InfinityPayCreateLinkResponse> createCheckoutLink(
    InfinityPayCreateLinkRequest request,
  ) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/links'),
      headers: {'Content-Type': 'application/json'},
      body: request.toJsonString(),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw InfinityPayCheckoutException(
        'Falha ao criar link de pagamento (HTTP ${response.statusCode}): ${response.body}',
        statusCode: response.statusCode,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return InfinityPayCreateLinkResponse.fromJson(json);
  }

  /// Consulta o status do pagamento pelo InfinityPay.
  Future<InfinityPayPaymentCheckResponse> checkPaymentStatus(
    InfinityPayPaymentCheckRequest request,
  ) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/payment_check'),
      headers: {'Content-Type': 'application/json'},
      body: request.toJsonString(),
    );

    if (response.statusCode != 200) {
      throw InfinityPayCheckoutException(
        'Falha ao consultar status de pagamento (HTTP ${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return InfinityPayPaymentCheckResponse.fromJson(json);
  }

  void dispose() => _client.close();
}
