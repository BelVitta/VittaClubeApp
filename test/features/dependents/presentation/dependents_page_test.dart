import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/dependents/presentation/pages/dependents_page.dart';
import 'package:vita_clube/features/home/domain/entities/plan_level.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_entity.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_status.dart';

void main() {
  testWidgets('shows limit reached state when dependents cannot be added',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DependentsPage(
          holderUserId: 'holder-1',
          initialLimitReached: true,
          subscription: _activeSubscription,
        ),
      ),
    );

    expect(find.textContaining('limite'), findsWidgets);
    expect(find.text('Adicionar dependente'), findsOneWidget);
  });
}

final _activeSubscription = SubscriptionEntity(
  id: 'sub_1',
  userId: 'user_1',
  planId: 'vittaclube-monthly',
  level: PlanLevel.bronze,
  activationDate: DateTime(2026, 6, 2),
  expirationDate: DateTime(2026, 7, 2),
  isCurrent: true,
  pixStatus: PixAutomaticSubscriptionStatus.active,
  paymentAccessStatus: PaymentAccessStatus.allowed,
);
