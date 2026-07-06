import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/home/domain/entities/plan_level.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_entity.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_status.dart';
import 'package:vita_clube/features/subscription/presentation/widgets/subscription_status_cards.dart';

void main() {
  testWidgets('blocked state shows restore account CTA', (tester) async {
    var restored = false;
    final subscription = SubscriptionEntity(
      id: 'sub_1',
      userId: 'user_1',
      planId: 'vittaclube-monthly',
      level: PlanLevel.inadimplente,
      activationDate: DateTime(2026, 6, 2),
      expirationDate: DateTime(2026, 7, 2),
      isCurrent: true,
      pixStatus: PixAutomaticSubscriptionStatus.blocked,
      paymentAccessStatus: PaymentAccessStatus.blocked,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubscriptionStatusCards.forSubscription(
            subscription: subscription,
            onRestore: () => restored = true,
          ),
        ),
      ),
    );

    expect(find.text('Conta bloqueada'), findsOneWidget);
    expect(find.textContaining('QR ficam bloqueados'), findsOneWidget);

    await tester.tap(find.text('Restaurar minha conta'));
    await tester.pump();
    expect(restored, isTrue);
  });
}
