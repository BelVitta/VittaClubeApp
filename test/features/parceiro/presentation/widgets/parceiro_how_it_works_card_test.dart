import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/admin/presentation/widgets/admin_how_it_works_card.dart';
import 'package:vita_clube/features/financeiro/presentation/widgets/financeiro_how_it_works_card.dart';
import 'package:vita_clube/features/parceiro/presentation/widgets/parceiro_how_it_works_card.dart';
import 'package:vita_clube/shared/widgets/how_it_works_card.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  testWidgets('parceiro card tells cashier to validate on their own device',
      (tester) async {
    await pump(tester, const ParceiroHowItWorksCard());

    expect(find.byType(HowItWorksCard), findsOneWidget);
    expect(find.text('Como funciona'), findsOneWidget);
    expect(
      find.textContaining('neste app, no seu aparelho'),
      findsOneWidget,
    );
    expect(
      find.textContaining('não no celular do cliente'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Só o financeiro altera esse %'),
      findsOneWidget,
    );
    expect(find.textContaining('LABSAUDE'), findsNothing);
    expect(find.textContaining('token'), findsNothing);
  });

  testWidgets('admin card uses badge percent at Vitta reception',
      (tester) async {
    await pump(tester, const AdminHowItWorksCard());

    expect(find.text('Como funciona'), findsOneWidget);
    expect(find.textContaining('patente (badge)'), findsOneWidget);
    expect(
      find.textContaining('não o percentual de laboratório'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Aprove dependentes presencialmente'),
      findsOneWidget,
    );
  });

  testWidgets('financeiro card owns live partner percent', (tester) async {
    await pump(tester, const FinanceiroHowItWorksCard());

    expect(find.text('Como funciona'), findsOneWidget);
    expect(
      find.textContaining('publica o percentual de desconto de cada parceiro'),
      findsOneWidget,
    );
    expect(
      find.textContaining('O parceiro não altera o % sozinho'),
      findsOneWidget,
    );
  });
}
