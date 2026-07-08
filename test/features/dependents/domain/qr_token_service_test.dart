import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/dependents/domain/entities/dependent_enums.dart';
import 'package:vita_clube/features/dependents/domain/services/qr_token_service.dart';

void main() {
  test('generates opaque signed token without discount data', () async {
    final service = QrTokenService(secretProvider: () async => 'secret');
    final token = await service.generateAppointmentToken(
      holderUserId: 'holder-1',
      beneficiaryType: BeneficiaryType.dependent,
      beneficiaryId: 'dep-1',
      scheduledAt: DateTime(2026, 6, 20, 10),
    );

    final parts = token.split('.');
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts.first))),
    ) as Map<String, dynamic>;

    expect(parts, hasLength(2));
    expect(payload.keys, isNot(contains('discount')));
    expect(payload.keys, isNot(contains('discount_percent')));
    expect(payload.keys, isNot(contains('value')));
  });
}
