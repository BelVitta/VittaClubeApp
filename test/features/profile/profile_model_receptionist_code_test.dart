import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/profile/data/models/profile_model.dart';

void main() {
  test('profile model reads receptionist_code for the front-desk card', () {
    final profile = ProfileModel.fromJson({
      'id': 'a',
      'name': 'Maria',
      'email': 'maria@vitaclube.com',
      'role': 'admin',
      'member_since': '2026-01-01T00:00:00Z',
      'member_code': '12345678',
      'receptionist_code': 'MAR0421',
    });
    expect(profile.receptionistCode, 'MAR0421');
    expect(profile.role, 'admin');
  });
}
