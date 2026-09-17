import 'package:flutter/material.dart';

import '../../../../shared/widgets/how_it_works_card.dart';

/// Texto operacional do role `admin` (recepção Vitta).
class AdminHowItWorksCard extends StatelessWidget {
  const AdminHowItWorksCard({super.key});

  static const body =
      'Na recepção você libera o benefício e confirma quem está no balcão. '
      'O desconto da consulta é o percentual da patente (badge) do titular, '
      'não o percentual de laboratório ou farmácia.';

  static const steps = [
    'Aprove dependentes presencialmente na primeira visita, com documento.',
    'Leia o QR da carteirinha (titular ou dependente ativo) ou digite o código do membro.',
    'Se a consulta for na Vitta, informe o valor: o app calcula o % do badge e quanto o cliente economiza.',
  ];

  @override
  Widget build(BuildContext context) {
    return const HowItWorksCard(
      body: body,
      steps: steps,
    );
  }
}
