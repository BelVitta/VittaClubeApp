import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/home/domain/entities/plan_level.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_entity.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_status.dart';
import 'package:vita_clube/features/subscription/presentation/widgets/subscription_status_cards.dart';

void main() {
  testWidgets('cancelled state shows paid period end and reactivation CTA',
      (tester) async {
    var reactivated = false;
    final subscription = SubscriptionEntity(
      id: 'sub_1',
      userId: 'user_1',
      planId: 'vittaclube-monthly',
      level: PlanLevel.cancelado,
      activationDate: DateTime(2026, 6, 2),
      expirationDate: DateTime(2026, 7, 2),
      isCurrent: true,
      pixStatus: PixAutomaticSubscriptionStatus.cancelled,
      paymentAccessStatus: PaymentAccessStatus.allowed,
      currentPeriodEnd: DateTime(2026, 7, 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubscriptionStatusCards.forSubscription(
            subscription: subscription,
            onSubscribe: () => reactivated = true,
          ),
        ),
      ),
    );

    expect(find.text('Assinatura cancelada'), findsOneWidget);
    expect(find.textContaining('02/07/2026'), findsOneWidget);

    await tester.tap(find.text('Reativar assinatura'));
    await tester.pump();
    expect(reactivated, isTrue);
  });
}
