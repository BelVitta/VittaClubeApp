import 'dart:convert';
import 'dart:math';

import '../entities/dependent_enums.dart';

typedef QrSecretProvider = Future<String> Function();

class QrTokenService {
  const QrTokenService({QrSecretProvider? secretProvider});

  Future<String> generateAppointmentToken({
    required String holderUserId,
    required BeneficiaryType beneficiaryType,
    String? beneficiaryId,
    required DateTime scheduledAt,
  }) async {
    // O token é um identificador aleatório de uso único. A autorização é
    // feita exclusivamente pela RPC no backend; nenhum segredo é enviado
    // ao aplicativo cliente.
    final payload = jsonEncode({
      'h': holderUserId,
      't': beneficiaryType.dbValue,
      'b': beneficiaryId,
      's': scheduledAt.toUtc().toIso8601String(),
      'n': DateTime.now().microsecondsSinceEpoch,
    });
    final nonce = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    // The second segment is entropy, not a client-verifiable signature. The
    // backend treats the complete value as an opaque database token.
    return '${base64UrlEncode(utf8.encode(payload)).replaceAll('=', '')}.'
        '${base64UrlEncode(nonce).replaceAll('=', '')}';
  }
}
