import 'package:flutter/material.dart';

import '../../../../shared/widgets/how_it_works_card.dart';

/// Texto do role `financeiro` (superadmin): dono do % vivo do parceiro.
class FinanceiroHowItWorksCard extends StatelessWidget {
  const FinanceiroHowItWorksCard({super.key});

  static const body = 'Você publica o percentual de desconto de cada parceiro. '
      'Esse é o número que o caixa do lab vê e que o membro vê no catálogo. '
      'O parceiro não altera o % sozinho.';

  static const steps = [
    'Cadastre o estabelecimento e grave o % combinado (acordo comercial).',
    'A recepção (admin) aprova dependentes e valida consulta na Vitta com o % da patente.',
    'O parceiro só lê a carteirinha no aparelho dele e honra o % que você publicou.',
  ];

  @override
  Widget build(BuildContext context) {
    return const HowItWorksCard(
      body: body,
      steps: steps,
    );
  }
}
