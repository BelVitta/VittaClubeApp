import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/core/error/rate_limit.dart';
import 'package:vita_clube/features/dependents/data/models/qr_validation_result_model.dart';
import 'package:vita_clube/features/dependents/domain/entities/dependent_enums.dart';

void main() {
  test('detects auth and postgrest rate-limit wording', () {
    expect(RateLimitMessages.looksLike('rate limit exceeded'), isTrue);
    expect(RateLimitMessages.looksLike('Too Many Requests'), isTrue);
    expect(RateLimitMessages.looksLike('rate_limit_exceeded'), isTrue);
    expect(RateLimitMessages.looksLike('Muitas tentativas'), isTrue);
    expect(RateLimitMessages.looksLike('invalid login credentials'), isFalse);
    expect(
      RateLimitMessages.messageOrNull('429 too many requests'),
      RateLimitMessages.userFacing,
    );
  });

  test('maps RPC decision rate_limited', () {
    final model = QrValidationResultModel.fromJson({
      'decision': 'rate_limited',
      'message': 'Muitas tentativas. Aguarde um minuto e tente novamente.',
    });
    expect(model.decision, QrValidationDecision.rateLimited);
    expect(model.isApproved, isFalse);
  });
}
