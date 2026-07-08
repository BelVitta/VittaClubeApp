import 'package:flutter/material.dart';

import '../../domain/entities/subscription_entity.dart';
import 'restore_account_modal.dart';

class SubscriptionAccessGate extends StatelessWidget {
  final SubscriptionEntity? subscription;
  final Widget child;
  final VoidCallback? onRestore;

  const SubscriptionAccessGate({
    super.key,
    required this.subscription,
    required this.child,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    if (subscription?.canAccessBenefits ?? false) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => RestoreAccountModal.show(
        context,
        variant: subscription == null
            ? AccountAccessModalVariant.subscribe
            : AccountAccessModalVariant.reactivate,
        onRestore: onRestore,
      ),
      child: AbsorbPointer(child: child),
    );
  }
}
