import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class FutureAppointmentsQuotaWarning extends StatelessWidget {
  final int futureAppointments;
  final int monthlyQuota;

  const FutureAppointmentsQuotaWarning({
    super.key,
    required this.futureAppointments,
    required this.monthlyQuota,
  });

  @override
  Widget build(BuildContext context) {
    if (futureAppointments < monthlyQuota) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.gradientLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Este beneficiario ja tem $futureAppointments agendamentos futuros. '
        'A cota so sera debitada na validacao do QR pela recepcao.',
        style: AppTheme.bodyMedium,
      ),
    );
  }
}
