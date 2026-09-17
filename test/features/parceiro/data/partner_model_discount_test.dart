import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/parceiro/data/models/partner_model.dart';

void main() {
  test('partner model reads live agreement percent from supabase snake_case',
      () {
    final model = PartnerModel.fromJson({
      'id': 'p1',
      'profile_id': 'u1',
      'name': 'Lab Saúde',
      'category': 'laboratorio',
      'code': 'LABSAUDE',
      'address': 'Rua A',
      'is_active': true,
      'discount_percentage': 15,
    });

    expect(model.discountPercentage, 15);
    expect(model.name, 'Lab Saúde');
  });

  test('copyWith publishes a new percent without touching the partner code',
      () {
    const original = PartnerModel(
      id: 'p1',
      profileId: 'u1',
      name: 'Lab Saúde',
      category: 'laboratorio',
      code: 'LABSAUDE',
      address: '',
      phone: '',
      logoUrl: '',
      isActive: true,
      discountPercentage: 10,
    );
    final updated = original.copyWith(discountPercentage: 20);
    expect(updated.discountPercentage, 20);
    expect(updated.code, 'LABSAUDE');
  });
}
