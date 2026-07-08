import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/subscription/presentation/pages/pix_automatic_explanation_page.dart';

void main() {
  testWidgets('shows recurring Pix explanation before bank authorization',
      (tester) async {
    var confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: PixAutomaticExplanationPage(
          onConfirmWithoutLink: () => confirmed = true,
        ),
      ),
    );

    expect(find.text('R\$34,90 por mês'), findsOneWidget);
    expect(find.textContaining('cobrança recorrente automática mensal'),
        findsOneWidget);
    expect(find.text('Autorizar no app do banco'), findsOneWidget);

    await tester.tap(find.text('Autorizar no app do banco'));
    await tester.pump();

    expect(confirmed, isTrue);
  });
}
