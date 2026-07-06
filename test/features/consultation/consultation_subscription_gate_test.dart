import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/consultation/presentation/pages/consultation_schedule_page.dart';
import 'package:vita_clube/features/home/domain/entities/plan_level.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_entity.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_status.dart';

void main() {
  testWidgets(
      'consultation scheduling blocks access when subscription is blocked',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationSchedulePage(
          subscription: _subscription(blocked: true),
        ),
      ),
    );

    expect(find.text('Agendamento bloqueado'), findsOneWidget);
    expect(find.text('Para quem e esse desconto?'), findsNothing);

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
