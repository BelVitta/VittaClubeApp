import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/home/domain/entities/plan_level.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_entity.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_status.dart';
import 'package:vita_clube/features/subscription/presentation/widgets/subscription_status_cards.dart';

void main() {
  testWidgets('shows rejected authorization state with retry CTA',
      (tester) async {
    var retried = false;
    final subscription = SubscriptionEntity(
      id: 'sub_1',
      userId: 'user_1',
      planId: 'plan_1',
      level: PlanLevel.bronze,
      activationDate: DateTime(2026, 6, 2),
      expirationDate: DateTime(2026, 7, 2),
      isCurrent: true,
      pixStatus: PixAutomaticSubscriptionStatus.rejected,
      paymentAccessStatus: PaymentAccessStatus.blocked,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubscriptionStatusCards.forSubscription(
            subscription: subscription,
            onSubscribe: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Autorização não concluída'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    expect(retried, isTrue);
  });
}
