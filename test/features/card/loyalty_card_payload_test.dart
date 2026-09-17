import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/card/domain/loyalty_card_payload.dart';

void main() {
  test('holder payload is the profile UUID', () {
    expect(
      LoyaltyCardPayload.holder('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'),
      'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    );
  });

  test('dependent payload is prefixed so the scanner knows who is using', () {
    const id = '11111111-2222-3333-4444-555555555555';
    expect(LoyaltyCardPayload.dependent(id), 'vc:dep:$id');
    expect(LoyaltyCardPayload.isDependentPayload('vc:dep:$id'), isTrue);
    expect(LoyaltyCardPayload.parseDependentId('vc:dep:$id'), id);
    expect(LoyaltyCardPayload.isAppointmentToken('vc:dep:$id'), isFalse);
  });

  test('appointment tokens still use dotted signature, not card prefix', () {
    expect(
      LoyaltyCardPayload.isAppointmentToken('payload.signature'),
      isTrue,
    );
    expect(
      LoyaltyCardPayload.isDependentPayload('payload.signature'),
      isFalse,
    );
  });
}
