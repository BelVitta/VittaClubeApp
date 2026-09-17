import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Gating test for the frozen loyalty MVP plan.
/// Reads the shipped doc (not a copy) and asserts the role flows and
/// commercial rules that the implementation goal must follow.
void main() {
  late String plan;

  setUpAll(() {
    plan = File('docs/sdd-loyalty-mvp-implementation.md').readAsStringSync();
  });

  test('plan file is the loyalty MVP source of truth, not a duplicate of PIX/QR SDD',
      () {
    expect(plan, isNotEmpty);
    expect(plan, contains('MVP de fidelidade'));
    expect(plan, isNot(contains('create-woovi-subscription')));
    expect(
      plan.toLowerCase(),
      isNot(contains('tornar o fluxo qr completamente funcional')),
    );
  });

  test('plan names every role in the objective', () {
    expect(plan.toLowerCase(), contains('titular'));
    expect(plan.toLowerCase(), contains('usuário'));
    expect(plan.toLowerCase(), contains('parceiro'));
    expect(plan.toLowerCase(), contains('admin'));
    expect(plan.toLowerCase(), contains('financeiro'));
    expect(plan.toLowerCase(), contains('superadmin'));
    expect(plan.toLowerCase(), contains('dependente'));
    expect(plan.toLowerCase(), contains('sem conta'));
    expect(plan.toLowerCase(), contains('sem login'));
  });

  test('plan records commercial rules: financeiro owns live %, clinic vs partner, not stacked, R\$ savings, partner-device validation',
      () {
    expect(plan.toLowerCase(), contains('discount_percentage'));
    expect(plan.toLowerCase(), contains('desconto'));
    expect(
      plan.toLowerCase(),
      contains('quem publica e edita o % vivo é só o financeiro'),
    );
    expect(
      plan.toLowerCase(),
      contains('o parceiro não auto-publica nem altera o % vivo'),
    );
    expect(plan.toLowerCase(), contains('% do badge'));
    expect(plan.toLowerCase(), contains('% do acordo'));
    expect(plan.toLowerCase(), contains('not stacked'));
    expect(plan.toLowerCase(), contains('não são somados'));
    expect(plan, contains('economia em R\$'));
    expect(
      plan.toLowerCase(),
      contains('validação do parceiro acontece na tela do parceiro'),
    );
    expect(plan, contains('LABSAUDE'));
  });

  test('plan assigns financeiro, admin, parceiro, and titular correctly', () {
    expect(
      plan.toLowerCase(),
      contains('publica e edita o **% vivo** do parceiro'),
    );
    expect(
      plan.toLowerCase(),
      contains('aprova/rejeita dependente'),
    );
    expect(plan.toLowerCase(), contains('scanner na vitta'));
    expect(
      plan.toLowerCase(),
      contains('valida no **próprio** aparelho'),
    );
    expect(plan.toLowerCase(), contains('não muda o % vivo'));
    expect(
      plan.toLowerCase(),
      contains('opera a carteirinha'),
    );
    expect(
      plan.toLowerCase(),
      contains('o titular opera o app e a carteirinha'),
    );
  });

  test('plan has current vs target and MVP vs later, plus known gaps', () {
    expect(plan.toLowerCase(), contains('current vs target'));
    expect(plan.toLowerCase(), contains('mvp vs later'));
    expect(plan, contains('admin-only'));
    expect(plan, contains('não tem coluna `discount_percentage`'));
    expect(plan.toLowerCase(), contains('não tem switch de dependente'));
    expect(plan.toLowerCase(), contains('gps'));
    expect(plan.toLowerCase(), contains('nfc'));
  });
}
