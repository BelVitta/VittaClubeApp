import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/home/domain/entities/plan_level.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_entity.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_status.dart';
import 'package:vita_clube/features/subscription/presentation/widgets/subscription_status_cards.dart';

void main() {
  testWidgets('active status shows fixed value and next billing date',
      (tester) async {
    final subscription = SubscriptionEntity(
      id: 'sub_1',
      userId: 'user_1',
      planId: 'vittaclube-monthly',
      level: PlanLevel.bronze,
      activationDate: DateTime(2026, 6, 2),
      expirationDate: DateTime(2026, 7, 2),
      isCurrent: true,
      pixStatus: PixAutomaticSubscriptionStatus.active,
      paymentAccessStatus: PaymentAccessStatus.allowed,
      nextBillingDate: DateTime(2026, 7, 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubscriptionStatusCards.forSubscription(
            subscription: subscription,
          ),
        ),
      ),
    );

    expect(find.text('Assinatura ativa'), findsOneWidget);
    expect(find.textContaining('R\$34,90/mês'), findsOneWidget);
    expect(find.textContaining('02/07/2026'), findsOneWidget);
  });
}
