import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/dependents/presentation/pages/dependents_page.dart';
import 'package:vita_clube/features/home/domain/entities/plan_level.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_entity.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_status.dart';

void main() {
  testWidgets(
      'dependents page blocks access when holder subscription is blocked',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DependentsPage(
          holderUserId: 'holder_1',
          subscription: _subscription(blocked: true),
        ),
      ),
    );

    expect(find.text('Dependentes bloqueados'), findsOneWidget);
    expect(find.text('Adicionar dependente'), findsNothing);

    await tester.tap(find.text('Reativar minha conta'));
    await tester.pumpAndSettle();

    expect(find.text('Reative sua conta'), findsOneWidget);
  });
}

SubscriptionEntity _subscription({required bool blocked}) {
  return SubscriptionEntity(
    id: 'sub_1',
    userId: 'user_1',
    planId: 'vittaclube-monthly',
    level: blocked ? PlanLevel.inadimplente : PlanLevel.bronze,
    activationDate: DateTime(2026, 6, 2),
    expirationDate: DateTime(2026, 7, 2),
    isCurrent: true,
    pixStatus: blocked
        ? PixAutomaticSubscriptionStatus.blocked
        : PixAutomaticSubscriptionStatus.active,
    paymentAccessStatus:
        blocked ? PaymentAccessStatus.blocked : PaymentAccessStatus.allowed,
  );
}
