import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/usecases/get_dependents_usecase.dart';

class BeneficiarySelection {
  final String label;
  final String? beneficiaryId;
  final bool isHolder;

  const BeneficiarySelection.holder()
      : label = 'Titular',
        beneficiaryId = null,
        isHolder = true;

  const BeneficiarySelection.dependent({
    required this.label,
    required this.beneficiaryId,
  }) : isHolder = false;
}

class BeneficiarySelector extends StatelessWidget {
  final List<DependentWithQuota> dependents;
  final ValueChanged<BeneficiarySelection> onSelected;

  const BeneficiarySelector({
    super.key,
    required this.dependents,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Selecione para quem e o desconto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Para quem e esse desconto?', style: AppTheme.headingMedium),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Titular'),
            subtitle: const Text('Usa a regra de beneficios do titular'),
            onTap: () => onSelected(const BeneficiarySelection.holder()),
          ),
          ...dependents.map((item) {
            final enabled = item.remainingUses > 0;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: enabled,
              title: Text(item.dependent.name),
              subtitle: Text('${item.remainingUses} usos restantes no ciclo'),
              trailing: enabled
                  ? const Icon(Icons.chevron_right)
                  : const Icon(Icons.lock_outline),
              onTap: enabled
                  ? () => onSelected(
                        BeneficiarySelection.dependent(
                          label: item.dependent.name,
                          beneficiaryId: item.dependent.id,
                        ),
                      )
                  : null,
            );
          }),
        ],
      ),
    );
  }
}
