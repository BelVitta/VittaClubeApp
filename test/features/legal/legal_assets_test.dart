import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('privacy policy covers LGPD, ANPD and actual club data', () {
    final text =
        File('docs/legal/politica-de-privacidade.md').readAsStringSync();
    expect(text, contains('Lei nº 13.709/2018'));
    expect(text, contains('ANPD'));
    expect(text, contains('CPF'));
    expect(text, contains('dependente'));
    expect(text, contains('art. 18'));
    expect(text, contains('Encarregado'));
    expect(text.toLowerCase(), contains('não vendemos dados pessoais'));
  });

  test('terms state the club is not a health plan', () {
    final text = File('docs/legal/termos-de-uso.md').readAsStringSync();
    expect(text, contains('plano de saúde'));
    expect(text, contains('18 anos'));
    expect(text, contains('não se somam'));
    expect(text, contains('LGPD'));
  });

  test('app assets match the published legal drafts', () {
    final docsPrivacy =
        File('docs/legal/politica-de-privacidade.md').readAsStringSync();
    final assetPrivacy =
        File('assets/legal/politica-de-privacidade.md').readAsStringSync();
    expect(assetPrivacy, docsPrivacy);
    expect(
      File('assets/legal/termos-de-uso.md').readAsStringSync(),
      File('docs/legal/termos-de-uso.md').readAsStringSync(),
    );
  });
}
