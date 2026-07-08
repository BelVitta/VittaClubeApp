import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/home/domain/entities/plan_level.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_entity.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_status.dart';
import 'package:vita_clube/features/subscription/presentation/widgets/subscription_status_cards.dart';

void main() {
  testWidgets('payment pending state shows persistent recovery warning',
      (tester) async {
    var refreshed = false;
    final subscription = SubscriptionEntity(
      id: 'sub_1',
      userId: 'user_1',
      planId: 'vittaclube-monthly',
      level: PlanLevel.bronze,
      activationDate: DateTime(2026, 6, 2),
      expirationDate: DateTime(2026, 7, 2),
      isCurrent: true,
      pixStatus: PixAutomaticSubscriptionStatus.paymentPending,
      paymentAccessStatus: PaymentAccessStatus.warningPending,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubscriptionStatusCards.forSubscription(
            subscription: subscription,
            onRefresh: () => refreshed = true,
          ),
        ),
      ),
    );

    expect(find.text('Pagamento pendente'), findsOneWidget);
    expect(find.textContaining('novas tentativas automáticas por até 7 dias'),
        findsOneWidget);

    await tester.tap(find.text('Atualizar status'));
    await tester.pump();
    expect(refreshed, isTrue);
  });
}
