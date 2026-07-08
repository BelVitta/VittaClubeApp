import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../entities/dependent_enums.dart';

typedef QrSecretProvider = Future<String> Function();

class QrTokenService {
  final QrSecretProvider secretProvider;

  const QrTokenService({required this.secretProvider});

  Future<String> generateAppointmentToken({
    required String holderUserId,
    required BeneficiaryType beneficiaryType,
    String? beneficiaryId,
    required DateTime scheduledAt,
  }) async {
    final secret = await secretProvider();
    final payload = jsonEncode({
      'h': holderUserId,
      't': beneficiaryType.dbValue,
      'b': beneficiaryId,
      's': scheduledAt.toUtc().toIso8601String(),
      'n': DateTime.now().microsecondsSinceEpoch,
    });
    final encodedPayload = base64Url.encode(utf8.encode(payload));
    final signature = Hmac(sha256, utf8.encode(secret))
        .convert(utf8.encode(encodedPayload))
        .toString();
    return '$encodedPayload.$signature';
  }
}
