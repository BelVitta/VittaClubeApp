import 'dart:io';

import 'package:flutter/services.dart';

enum CardTokenizationOutcome { success, cancelled, unavailable, error }

class CardTokenizationResult {
  final CardTokenizationOutcome outcome;
  final String? cardTokenId;
  final String? message;

  const CardTokenizationResult._(this.outcome,
      {this.cardTokenId, this.message});

  const CardTokenizationResult.success(String token)
      : this._(CardTokenizationOutcome.success, cardTokenId: token);
  const CardTokenizationResult.cancelled()
      : this._(CardTokenizationOutcome.cancelled);
  const CardTokenizationResult.unavailable([String? message])
      : this._(CardTokenizationOutcome.unavailable, message: message);
  const CardTokenizationResult.error(String message)
      : this._(CardTokenizationOutcome.error, message: message);
}

class MercadoPagoCardTokenizationService {
  static const MethodChannel _channel =
      MethodChannel('br.com.vittaclube/mercadopago_card_tokenization');
  // Public Key is safe to ship in the client, but it remains environment
  // specific and is supplied through the build configuration.
  static const String _publicKey =
      String.fromEnvironment('MERCADOPAGO_PUBLIC_KEY');

  Future<bool> isAvailable() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    return await _channel.invokeMethod<bool>(
          'isAvailable',
          {'publicKey': _publicKey},
        ) ??
        false;
  }

  /// Somente nome, CPF e a Public Key identificam a operação. Número,
  /// validade e CVV ficam dentro dos PCI Fields nativos e nunca atravessam
  /// este canal.
  Future<CardTokenizationResult> openCardTokenization({
    required String payerName,
    required String cpf,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const CardTokenizationResult.unavailable(
        'Cartão não está disponível neste dispositivo.',
      );
    }
    try {
      final response = await _channel.invokeMapMethod<String, dynamic>(
        'openCardTokenization',
        {
          'payerName': payerName,
          'cpf': cpf,
          'publicKey': _publicKey,
        },
      );
      final status = response?['status'];
      final token = response?['cardTokenId'] as String?;
      if (status == 'success' && token != null && token.isNotEmpty) {
        return CardTokenizationResult.success(token);
      }
      if (status == 'cancelled') {
        return const CardTokenizationResult.cancelled();
      }
      return CardTokenizationResult.error(
        response?['message'] as String? ??
            'Não foi possível tokenizar o cartão.',
      );
    } on PlatformException catch (error) {
      return CardTokenizationResult.error(
        error.message ?? 'Falha na tokenização segura do cartão.',
      );
    }
  }
}
