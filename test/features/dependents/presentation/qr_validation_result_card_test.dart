import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/dependents/domain/entities/dependent_enums.dart';
import 'package:vita_clube/features/dependents/domain/repositories/qr_validation_repository.dart';
import 'package:vita_clube/features/dependents/presentation/widgets/qr_validation_result_card.dart';

void main() {
  testWidgets('shows beneficiary name, plan, discount and remaining uses',
      (tester) async {
    const result = QrValidationResult(
      decision: QrValidationDecision.approved,
      message: 'Uso validado.',
      memberName: 'João Silva',
      holderName: 'Maria Silva',
      beneficiaryType: 'dependent',
      planLevel: 'prata',
      discountPercentage: 15,
      remainingUses: 1,
      holderUserId: 'holder-1',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: QrValidationResultCard(result: result)),
      ),
    );

    expect(find.text('Uso aprovado'), findsOneWidget);
    expect(find.text('João Silva'), findsOneWidget);
    expect(find.text('Beneficiário: dependente'), findsOneWidget);
    expect(find.text('Dependente de Maria Silva'), findsOneWidget);
    expect(find.text('Prata'), findsOneWidget);
    expect(find.text('15% desconto'), findsOneWidget);
    expect(find.text('1 uso restante'), findsOneWidget);
  });

  testWidgets('shows rate limit title and message', (tester) async {
    const result = QrValidationResult(
      decision: QrValidationDecision.rateLimited,
      message: 'Muitas tentativas. Aguarde um minuto e tente novamente.',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: QrValidationResultCard(result: result)),
      ),
    );

    expect(find.text('Muitas tentativas'), findsOneWidget);
    expect(find.textContaining('Aguarde um minuto'), findsOneWidget);
  });

  testWidgets('shows holder card label for member QR without beneficiary type',
      (tester) async {
    const result = QrValidationResult(
      decision: QrValidationDecision.approved,
      message: 'Membro ativo. Desconto de 10% aplicável.',
      memberName: 'Maria Silva',
      planLevel: 'ouro',
      discountPercentage: 10,
      holderUserId: 'holder-1',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: QrValidationResultCard(result: result)),
      ),
    );

    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.text('Titular da carteirinha'), findsOneWidget);
    expect(find.text('Ouro'), findsOneWidget);
    expect(find.text('10% desconto'), findsOneWidget);
  });
}
