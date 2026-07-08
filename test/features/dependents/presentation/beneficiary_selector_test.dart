import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/dependents/domain/usecases/get_dependents_usecase.dart';
import 'package:vita_clube/features/dependents/presentation/widgets/beneficiary_selector.dart';

import '../dependents_test_helpers.dart';

void main() {
  testWidgets('shows remaining quota and disables exhausted dependent',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BeneficiarySelector(
            dependents: [
              DependentWithQuota(dependent: makeDependent(), remainingUses: 0),
            ],
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.textContaining('0 usos'), findsOneWidget);
    final tile = tester.widget<ListTile>(find.byType(ListTile).last);
    expect(tile.enabled, isFalse);
  });
}
