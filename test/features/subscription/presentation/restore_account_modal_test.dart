import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/subscription/presentation/widgets/restore_account_modal.dart';

void main() {
  testWidgets('reactivate modal explains blocked access and has CTA',
      (tester) async {
    var restored = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => RestoreAccountModal.show(
                  context,
                  onRestore: () => restored = true,
                ),
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Reative sua conta'), findsOneWidget);
    expect(find.textContaining('QR, dependentes'), findsOneWidget);

    await tester.tap(find.text('Reativar minha conta'));
    await tester.pump();
    expect(restored, isTrue);
  });

  testWidgets('subscribe modal uses marketing copy for users without plan',
      (tester) async {
    var subscribed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => RestoreAccountModal.showSubscribe(
                  context,
                  onSubscribe: () => subscribed = true,
                ),
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Entre para o VittaClube'), findsOneWidget);
    expect(find.textContaining('descontos em consultas'), findsOneWidget);

    await tester.tap(find.text('Assinar agora'));
    await tester.pump();
    expect(subscribed, isTrue);
  });
}
