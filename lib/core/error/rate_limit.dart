/// Mensagens e detecção de rate limit (Auth nativo + RPCs + Edge Functions).
class RateLimitMessages {
  static const userFacing =
      'Muitas tentativas. Aguarde um minuto e tente novamente.';

  static bool looksLike(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('rate_limit') ||
        msg.contains('rate limit') ||
        msg.contains('too many requests') ||
        msg.contains('muitas tentativas');
  }

  static String? messageOrNull(Object error) =>
      looksLike(error) ? userFacing : null;
}
