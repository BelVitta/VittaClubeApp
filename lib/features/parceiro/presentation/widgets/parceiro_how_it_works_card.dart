import 'package:flutter/material.dart';

import '../../../../shared/widgets/how_it_works_card.dart';

/// Texto operacional do role `parceiro`: validar no aparelho do estabelecimento.
class ParceiroHowItWorksCard extends StatelessWidget {
  const ParceiroHowItWorksCard({super.key});

  static const body = 'O membro Vita Clube mostra a carteirinha no seu caixa '
      '(titular ou dependente já aprovado pela recepção). '
      'A confirmação do desconto acontece neste app, no seu aparelho — '
      'não no celular do cliente.';

  static const steps = [
    'Peça a carteirinha e confira o nome com o documento de quem está no balcão.',
    'Leia o QR ou digite o código do membro neste aparelho.',
    'Aplique no seu caixa o percentual combinado com o Vita Clube. Só o financeiro altera esse %.',
    'Se informar o valor do pedido, o app mostra quanto o cliente economiza em reais.',
  ];

  @override
  Widget build(BuildContext context) {
    return const HowItWorksCard(
      body: body,
      steps: steps,
    );
  }
}
